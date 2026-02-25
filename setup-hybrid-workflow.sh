#!/bin/bash

# 🚀 Setup Script: Hybrid Workflow 80/20 Solutions
# Configura automaticamente il workflow Ciccio (VPS) + Claude Code (PC) + GitHub Actions
# Autore: Team 80/20 Solutions
# Versione: 1.0
# Data: 2026-02-25

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logo ASCII
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║  🚀 80/20 Solutions - Hybrid Workflow Setup                  ║
║                                                              ║
║  Ciccio (VPS) + Claude Code (PC) + GitHub Actions          ║
╚══════════════════════════════════════════════════════════════╝
EOF

echo ""

# Funzioni utility
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verifica prerequisiti
check_prerequisites() {
    log_info "Verifico prerequisiti..."
    
    # Verifica gh CLI
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) non installato. Installa con: sudo snap install gh"
        exit 1
    fi
    
    # Verifica autenticazione GitHub
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI non autenticato. Esegui: gh auth login"
        exit 1
    fi
    
    # Verifica git
    if ! command -v git &> /dev/null; then
        log_error "Git non installato."
        exit 1
    fi
    
    log_success "Prerequisiti verificati"
}

# Repository da configurare
declare -a REPOSITORIES=(
    "StageConnect"
    "BeachRef-app" 
    "x32-Assist"
    "GridConnect"
    "finn"
    "progetto-casa"
    "Maestro"
    "AutoDrum"
)

# Configurazione GitHub Actions per ogni repository
setup_github_actions() {
    log_info "Configurazione GitHub Actions per tutti i repository..."
    
    local workflow_file="$(dirname "$0")/scripts/github-actions-build-workflow.yml"
    
    if [[ ! -f "$workflow_file" ]]; then
        log_error "File workflow GitHub Actions non trovato: $workflow_file"
        exit 1
    fi
    
    for repo in "${REPOSITORIES[@]}"; do
        log_info "Configurazione repository: $repo"
        
        # Clone temporaneo
        local temp_dir="/tmp/setup-$repo-$(date +%s)"
        
        if gh repo clone "ecologicaleaving/$repo" "$temp_dir" 2>/dev/null; then
            cd "$temp_dir"
            
            # Crea directory .github/workflows se non esiste
            mkdir -p .github/workflows
            
            # Copia il workflow
            cp "$workflow_file" ".github/workflows/build-and-release.yml"
            
            # Verifica se ci sono modifiche
            if git diff --quiet && git diff --cached --quiet; then
                log_warning "Repository $repo già configurato"
            else
                # Commit e push
                git add .github/workflows/build-and-release.yml
                git commit -m "feat: Add automated build and release workflow

- Auto-detect project type (Flutter/React/Node/Static)
- Build platform-specific artifacts
- Create GitHub releases with assets
- Support for APK, web builds, and static sites
- Integrated with 80/20 Solutions hybrid workflow"
                
                git push origin main 2>/dev/null || git push origin master 2>/dev/null
                
                log_success "Repository $repo configurato con GitHub Actions"
            fi
            
            cd - > /dev/null
            rm -rf "$temp_dir"
        else
            log_warning "Impossibile clonare repository: $repo (potrebbe essere privato o non esistere)"
        fi
    done
}

# Configurazione label GitHub
setup_github_labels() {
    log_info "Configurazione label GitHub per coordinamento workflow..."
    
    # Label necessari per il workflow
    declare -A LABELS=(
        ["claude-code"]="0052cc"
        ["building"]="fbca04" 
        ["review-ready"]="0e8a16"
        ["deployed-test"]="d4c5f9"
        ["ciccio"]="b60205"
        ["in-progress"]="c5def5"
    )
    
    for repo in "${REPOSITORIES[@]}"; do
        log_info "Configurazione label per repository: $repo"
        
        for label in "${!LABELS[@]}"; do
            local color="${LABELS[$label]}"
            
            # Crea label (ignora se esiste già)
            gh label create "$label" --color "$color" --repo "ecologicaleaving/$repo" 2>/dev/null || true
        done
        
        log_success "Label configurati per repository: $repo"
    done
}

# Verifica configurazione Ciccio (VPS)
verify_ciccio_setup() {
    log_info "Verifica configurazione Ciccio (VPS)..."
    
    # Verifica cron jobs attivi
    if command -v openclaw &> /dev/null; then
        log_success "OpenClaw installato"
        
        # Verifica cron jobs attivi tramite openclaw cron status
        if openclaw cron list --format json &>/dev/null; then
            local ci_monitor_active=$(openclaw cron list --format json 2>/dev/null | jq -r '.[] | select(.payload.text | contains("CI Monitor")) | .enabled' 2>/dev/null || echo "false")
            
            if [[ "$ci_monitor_active" == "true" ]]; then
                log_success "CI Monitor cron job attivo"
            else
                log_warning "CI Monitor cron job non trovato o disattivo"
            fi
        else
            log_warning "Impossibile verificare cron jobs OpenClaw"
        fi
    else
        log_warning "OpenClaw non trovato - verifica installazione"
    fi
}

# Genera istruzioni per Claude Code PC
generate_pc_instructions() {
    log_info "Generazione istruzioni per Claude Code (PC)..."
    
    local pc_setup_file="CLAUDE_CODE_PC_SETUP.md"
    local powershell_script="scripts/install-claude-pc.ps1"
    
    cat << 'EOF'

╔══════════════════════════════════════════════════════════════╗
║  📋 PROSSIMI PASSI - CONFIGURAZIONE PC                       ║
╚══════════════════════════════════════════════════════════════╝

Per completare il setup del sistema ibrido:

1. 🪟 Su PC Windows, esegui come Administrator:
   .\scripts\install-claude-pc.ps1

2. 🔧 Configura Task Scheduler per monitoraggio automatico:
   - Script: C:\claude-workspace\claude-monitor.ps1
   - Trigger: Ogni 5 minuti
   - User: SYSTEM

3. 🧪 Test del workflow completo:
   - Crea issue con label 'claude-code'
   - Verifica processing automatico PC
   - Controlla GitHub Actions build
   - Monitora deploy VPS

4. 📊 Monitoring:
   - Log PC: C:\claude-workspace\logs\
   - Cron VPS: /status per verificare CI Monitor
   - GitHub Actions: tab Actions nei repository

EOF
}

# Riepilogo configurazione
show_summary() {
    log_info "Riepilogo configurazione completata:"
    echo ""
    echo "✅ GitHub Actions configurato per ${#REPOSITORIES[@]} repository"
    echo "✅ Label workflow configurati"
    echo "✅ Prerequisiti verificati"
    echo ""
    echo "🔄 Workflow attivo:"
    echo "   claude-code → building → review-ready → deployed-test"
    echo ""
    echo "📋 Repository configurati:"
    for repo in "${REPOSITORIES[@]}"; do
        echo "   - ecologicaleaving/$repo"
    done
    echo ""
}

# Main execution
main() {
    log_info "Inizio configurazione Hybrid Workflow..."
    echo ""
    
    check_prerequisites
    setup_github_actions
    setup_github_labels
    verify_ciccio_setup
    
    echo ""
    log_success "🎉 Configurazione completata!"
    
    show_summary
    generate_pc_instructions
}

# Help function
show_help() {
    cat << 'EOF'
🚀 80/20 Solutions - Hybrid Workflow Setup

UTILIZZO:
  ./setup-hybrid-workflow.sh [opzioni]

OPZIONI:
  -h, --help          Mostra questo help
  --github-only       Solo configurazione GitHub Actions
  --labels-only       Solo configurazione label
  --verify-only       Solo verifica configurazione

DESCRIZIONE:
  Configura automaticamente il workflow ibrido per 80/20 Solutions:
  - Ciccio (VPS): Orchestrator, DevOps, deploy
  - Claude Code (PC): Development automation, GitHub monitoring  
  - GitHub Actions: Build automatico multi-platform

PREREQUISITI:
  - GitHub CLI (gh) installato e autenticato
  - Git configurato
  - Accesso ai repository ecologicaleaving/*

REPOSITORY CONFIGURATI:
  StageConnect, BeachRef-app, x32-Assist, GridConnect, 
  finn, progetto-casa, Maestro, AutoDrum

EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --github-only)
        check_prerequisites
        setup_github_actions
        ;;
    --labels-only)
        check_prerequisites
        setup_github_labels
        ;;
    --verify-only)
        verify_ciccio_setup
        ;;
    *)
        main
        ;;
esac