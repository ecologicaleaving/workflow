#!/bin/bash
# safe-github.sh  (ex ciccio-safe-github.sh — rinominato, Ciccio non è più attivo)
# ============================================================
# GUARDRAIL per operazioni GitHub
# Blocca operazioni rischiose prima che causino danni.
#
# USO:
#   ciccio-safe-github check-branch --repo <owner/repo> --branch <branch>
#   ciccio-safe-github commit --repo <owner/repo> --branch <branch> --file <path> --content <b64> --sha <sha> --msg <msg>
#   ciccio-safe-github sync-template --template <path> --repos <repo1,repo2,...>
#
# REGOLE:
#   1. MAI commit diretto su main/master di repo applicative
#   2. MAI modificare codice applicativo senza issue associata
#   3. Sync template → sempre via PR, mai commit diretto
#   4. Repo "workflow" è l'unica dove è OK committare su main (è infra, non app)
# ============================================================

set -euo pipefail

export PATH=$PATH:/root/go/bin

# Repo dove è OK committare su main (infra/config, non app)
SAFE_MAIN_REPOS=("ecologicaleaving/workflow")

# Repo applicative — VIETATO commit diretto su main/master
APP_REPOS=(
    "ecologicaleaving/finn"
    "ecologicaleaving/StageConnect"
    "ecologicaleaving/BeachRef-app"
    "ecologicaleaving/maestro"
    "ecologicaleaving/GridConnect"
    "ecologicaleaving/AutoDrum"
    "ecologicaleaving/smartscore"
)

PROTECTED_BRANCHES=("main" "master")

log_ok()    { echo "✅ $*"; }
log_err()   { echo "❌ GUARDRAIL BLOCCATO: $*" >&2; exit 1; }
log_warn()  { echo "⚠️  $*"; }

is_protected_branch() {
    local branch="$1"
    for pb in "${PROTECTED_BRANCHES[@]}"; do
        [ "$branch" = "$pb" ] && return 0
    done
    return 1
}

is_safe_repo() {
    local repo="$1"
    for safe in "${SAFE_MAIN_REPOS[@]}"; do
        [ "$repo" = "$safe" ] && return 0
    done
    return 1
}

is_app_repo() {
    local repo="$1"
    for app in "${APP_REPOS[@]}"; do
        [ "$repo" = "$app" ] && return 0
    done
    return 1
}

# ── COMANDO: check-branch ─────────────────────────────────
cmd_check_branch() {
    local repo="" branch=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo)   repo="$2";   shift 2 ;;
            --branch) branch="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [ -z "$repo" ]   && log_err "Parametro --repo mancante"
    [ -z "$branch" ] && log_err "Parametro --branch mancante"

    if is_protected_branch "$branch" && ! is_safe_repo "$repo"; then
        log_err "Commit diretto su '$branch' vietato per $repo. Usa un branch feature (feature/issue-N-slug)."
    fi

    log_ok "Branch '$branch' su $repo: operazione consentita"
}

# ── COMANDO: commit ───────────────────────────────────────
cmd_commit() {
    local repo="" branch="" file="" content="" sha="" msg=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo)    repo="$2";    shift 2 ;;
            --branch)  branch="$2";  shift 2 ;;
            --file)    file="$2";    shift 2 ;;
            --content) content="$2"; shift 2 ;;
            --sha)     sha="$2";     shift 2 ;;
            --msg)     msg="$2";     shift 2 ;;
            *) shift ;;
        esac
    done

    [ -z "$repo" ]    && log_err "Parametro --repo mancante"
    [ -z "$branch" ]  && log_err "Parametro --branch mancante"
    [ -z "$file" ]    && log_err "Parametro --file mancante"
    [ -z "$content" ] && log_err "Parametro --content mancante"
    [ -z "$msg" ]     && log_err "Parametro --msg mancante"

    # GUARDRAIL 1: branch protetto su repo applicativa
    if is_protected_branch "$branch" && ! is_safe_repo "$repo"; then
        log_err "STOP — Stai per committare su '$branch' di $repo (repo applicativa). Crea prima un branch feature."
    fi

    # GUARDRAIL 2: file workflow su repo applicativa → warn
    if [[ "$file" == ".github/workflows/"* ]] && is_app_repo "$repo"; then
        log_warn "Stai modificando un file workflow su $repo. Assicurati di essere su branch feature."
    fi

    # Esegui il commit
    ARGS=(-X PUT "repos/$repo/contents/$file" -f "message=$msg" -f "content=$content")
    [ -n "$sha" ] && ARGS+=(-f "sha=$sha")

    gh api "${ARGS[@]}" --jq '.commit.sha'
    log_ok "Commit su $repo:$branch/$file completato"
}

# ── COMANDO: sync-template (crea PR invece di commit diretto) ──
cmd_sync_template() {
    local template="" repos_csv="" dry_run=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --template) template="$2"; shift 2 ;;
            --repos)    repos_csv="$2"; shift 2 ;;
            --dry-run)  dry_run=true; shift ;;
            *) shift ;;
        esac
    done

    [ -z "$template" ]  && log_err "Parametro --template mancante"
    [ -z "$repos_csv" ] && log_err "Parametro --repos mancante"

    WORKFLOW_REPO="ecologicaleaving/workflow"
    CONTENT_B64=$(gh api "repos/$WORKFLOW_REPO/contents/$template" --jq '.content' | tr -d '\n')
    [ -z "$CONTENT_B64" ] && log_err "Template $template non trovato"

    IFS=',' read -ra REPOS <<< "$repos_csv"
    DATE=$(date '+%Y%m%d-%H%M')
    BRANCH="chore/sync-templates-$DATE"
    TPLNAME=$(basename "$template" .yml)

    for repo in "${REPOS[@]}"; do
        repo=$(echo "$repo" | xargs)  # trim spazi
        echo "--- Sync $TPLNAME → $repo ---"

        DEST=".github/workflows/$TPLNAME.yml"
        CURRENT_SHA=$(gh api "repos/$repo/contents/$DEST" --jq '.sha' 2>/dev/null || echo "")
        CURRENT_CONTENT=$(gh api "repos/$repo/contents/$DEST" --jq '.content' 2>/dev/null | tr -d '\n' || echo "")

        if [ "$CONTENT_B64" = "$CURRENT_CONTENT" ]; then
            log_ok "$repo già aggiornato, skip"
            continue
        fi

        if $dry_run; then
            log_warn "[DRY RUN] $repo: creerebbe branch $BRANCH + PR per aggiornare $DEST"
            continue
        fi

        # Crea branch da main (non committa su main!)
        DEFAULT_SHA=$(gh api "repos/$repo/git/ref/heads/main" --jq '.object.sha' 2>/dev/null \
                   || gh api "repos/$repo/git/ref/heads/master" --jq '.object.sha' 2>/dev/null)
        [ -z "$DEFAULT_SHA" ] && log_err "Non trovo main/master su $repo"

        # Crea branch
        gh api -X POST "repos/$repo/git/refs" \
            -f "ref=refs/heads/$BRANCH" \
            -f "sha=$DEFAULT_SHA" \
            --jq '.ref' || log_err "Impossibile creare branch $BRANCH su $repo"

        # Commit sul branch (non su main!)
        ARGS=(-X PUT "repos/$repo/contents/$DEST"
              -f "message=chore: sync $TPLNAME template from workflow repo [skip ci]"
              -f "content=$CONTENT_B64"
              -f "branch=$BRANCH")
        [ -n "$CURRENT_SHA" ] && ARGS+=(-f "sha=$CURRENT_SHA")
        gh api "${ARGS[@]}" --jq '.commit.sha' > /dev/null

        # Apri PR
        PR_URL=$(gh pr create \
            --repo "$repo" \
            --head "$BRANCH" \
            --base main \
            --title "chore: sync workflow template $TPLNAME" \
            --body "🔄 **Sync automatico template**

Aggiornamento automatico del template \`$TPLNAME\` dal repo workflow.

**Cambiamenti:** vedi diff
**Origine:** \`ecologicaleaving/workflow/templates/$template\`
**Triggera build:** NO (usa \`[skip ci]\` nel commit)

> Mergia se il diff è corretto, chiudi se non necessario." 2>&1 || echo "")

        if [ -n "$PR_URL" ]; then
            log_ok "$repo → PR aperta: $PR_URL"
        else
            log_warn "$repo → PR già esistente o errore apertura PR"
        fi
    done

    log_ok "Sync completato via PR — nessun commit diretto su main"
}

# ── DISPATCH ─────────────────────────────────────────────
CMD="${1:-help}"
shift || true

case "$CMD" in
    check-branch)   cmd_check_branch "$@" ;;
    commit)         cmd_commit "$@" ;;
    sync-template)  cmd_sync_template "$@" ;;
    help|*)
        echo "USO: ciccio-safe-github <comando> [opzioni]"
        echo ""
        echo "Comandi:"
        echo "  check-branch  --repo <r> --branch <b>     Verifica che il branch sia sicuro"
        echo "  commit        --repo <r> --branch <b> ... Commit con guardrail"
        echo "  sync-template --template <t> --repos <r>  Sync template via PR (sicuro)"
        echo "  help                                       Questo messaggio"
        ;;
esac
