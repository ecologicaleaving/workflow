#!/usr/bin/env bash
# security-audit.sh — Automated security checks for pre-push gate
# Part of 8020 Solutions workflow
# Usage: bash scripts/security-audit.sh [repo-root] [--json] [--fix] [--strict] [--help]

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

# Counters
CRITICAL_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0

# Options
REPO_ROOT="."
JSON_OUTPUT=false
FIX_MODE=false
STRICT_MODE=false

# Output accumulator (for JSON mode)
declare -a JSON_SECTIONS=()

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# ── Functions ──────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
${SCRIPT_NAME} v${VERSION} — Automated security audit for git repositories

Usage: ${SCRIPT_NAME} [repo-root] [options]

Arguments:
  repo-root       Path to the repository root (default: current directory)

Options:
  --help          Show this help message
  --json          Output results in JSON format
  --fix           Attempt automatic fixes where possible
  --strict        Treat warnings as failures (exit 1 on warnings)

Exit codes:
  0  All checks passed (warnings may exist)
  1  Critical issues found
  2  Script error

Checks performed:
  1. Secrets/credentials in code
  2. Sensitive files tracked by git
  3. Vulnerable dependencies (npm/pip/go)
  4. Debug/dev leftovers
  5. File permissions (777, SUID/SGID)
EOF
    exit 0
}

print_header() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🔒 Security Audit v${VERSION}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "  📁 Repository: ${REPO_ROOT}"
    echo -e "  📅 Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
}

section_header() {
    [[ "$JSON_OUTPUT" == true ]] && return
    echo -e "\n${BOLD}── $1 ──${NC}"
}

critical() {
    [[ "$JSON_OUTPUT" != true ]] && echo -e "  ${RED}❌ CRITICAL:${NC} $1"
    ((CRITICAL_COUNT++)) || true
}

warning() {
    [[ "$JSON_OUTPUT" != true ]] && echo -e "  ${YELLOW}⚠️  WARNING:${NC} $1"
    ((WARNING_COUNT++)) || true
}

info() {
    [[ "$JSON_OUTPUT" != true ]] && echo -e "  ${BLUE}ℹ️  INFO:${NC} $1"
    ((INFO_COUNT++)) || true
}

ok() {
    [[ "$JSON_OUTPUT" == true ]] && return
    echo -e "  ${GREEN}✅${NC} $1"
}

# Get list of git-tracked files, excluding common non-source directories
get_tracked_files() {
    cd "$REPO_ROOT"
    git ls-files 2>/dev/null | grep -v -E '^(node_modules/|\.git/|vendor/|dist/|build/|\.next/)' || true
}

# Get tracked files filtered to source code only
get_source_files() {
    get_tracked_files | grep -E '\.(js|jsx|ts|tsx|py|go|rb|php|java|cs|rs|sh|yml|yaml|json|toml|ini|cfg|conf|env)$' || true
}

# ── Check 1: Secrets/Credentials ──────────────────────────────────────────────

check_secrets() {
    section_header "1. Secrets / Credentials in Code"
    local found=0
    local files

    files=$(get_tracked_files)
    if [[ -z "$files" ]]; then
        info "No tracked files found"
        return
    fi

    cd "$REPO_ROOT"

    # AWS Access Keys
    local aws_matches
    aws_matches=$(echo "$files" | xargs grep -lnE 'AKIA[0-9A-Z]{16}' 2>/dev/null || true)
    if [[ -n "$aws_matches" ]]; then
        while IFS= read -r match; do
            critical "Possible AWS key found in: $match"
            found=1
        done <<< "$aws_matches"
    fi

    # Private keys
    local pk_matches
    pk_matches=$(echo "$files" | xargs grep -lnE '-----BEGIN[[:space:]]+(RSA|DSA|EC|OPENSSH|PGP)?[[:space:]]*PRIVATE KEY-----' 2>/dev/null || true)
    if [[ -n "$pk_matches" ]]; then
        while IFS= read -r match; do
            critical "Private key found in: $match"
            found=1
        done <<< "$pk_matches"
    fi

    # Connection strings with passwords
    local conn_matches
    conn_matches=$(echo "$files" | xargs grep -lnE '(mysql|postgres|postgresql|mongodb|redis|amqp|smtp)://[^:]+:[^@]+@' 2>/dev/null | \
        grep -v -E '(\.example|\.sample|\.template|TEMPLATE|README|\.md)' || true)
    if [[ -n "$conn_matches" ]]; then
        while IFS= read -r match; do
            critical "Connection string with password in: $match"
            found=1
        done <<< "$conn_matches"
    fi

    # Hardcoded passwords (in source files, not markdown/docs)
    local src_files
    src_files=$(echo "$files" | grep -E '\.(js|jsx|ts|tsx|py|go|rb|php|java|cs|rs|sh)$' || true)
    if [[ -n "$src_files" ]]; then
        local pwd_matches
        pwd_matches=$(echo "$src_files" | xargs grep -lnE '(password|passwd|pwd)\s*[=:]\s*["\x27][^"\x27]{4,}["\x27]' 2>/dev/null | \
            grep -v -E '(test|spec|mock|fixture|example|\.test\.|\.spec\.)' || true)
        if [[ -n "$pwd_matches" ]]; then
            while IFS= read -r match; do
                critical "Hardcoded password in: $match"
                found=1
            done <<< "$pwd_matches"
        fi
    fi

    # API keys near keyword context (only in source files)
    if [[ -n "$src_files" ]]; then
        local api_matches
        api_matches=$(echo "$src_files" | xargs grep -lnE '(api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[=:]\s*["\x27][A-Za-z0-9_\-]{20,}["\x27]' 2>/dev/null | \
            grep -v -E '(test|spec|mock|fixture|example|\.test\.|\.spec\.|\.env\.example)' || true)
        if [[ -n "$api_matches" ]]; then
            while IFS= read -r match; do
                critical "Possible API key/secret in: $match"
                found=1
            done <<< "$api_matches"
        fi
    fi

    if [[ $found -eq 0 ]]; then
        ok "No secrets or credentials detected"
    fi
}

# ── Check 2: Sensitive Files ──────────────────────────────────────────────────

check_sensitive_files() {
    section_header "2. Sensitive Files"
    local found=0
    local files

    files=$(get_tracked_files)
    cd "$REPO_ROOT"

    # .env files (not .env.example or .env.sample)
    local env_files
    env_files=$(echo "$files" | grep -E '(^|/)\.env(\.[^.]+)?$' | grep -v -E '\.(example|sample|template)$' || true)
    if [[ -n "$env_files" ]]; then
        while IFS= read -r f; do
            critical "Sensitive file tracked by git: $f"
            found=1
            if [[ "$FIX_MODE" == true ]]; then
                info "FIX: Adding $f to .gitignore"
                echo "$f" >> "$REPO_ROOT/.gitignore"
            fi
        done <<< "$env_files"
    fi

    # Key/certificate files
    local key_files
    key_files=$(echo "$files" | grep -E '\.(pem|key|p12|pfx|jks)$' || true)
    if [[ -n "$key_files" ]]; then
        while IFS= read -r f; do
            critical "Key/certificate file tracked by git: $f"
            found=1
        done <<< "$key_files"
    fi

    # SSH keys
    local ssh_files
    ssh_files=$(echo "$files" | grep -E '(id_rsa|id_ed25519|id_ecdsa|id_dsa)(\.pub)?$' || true)
    if [[ -n "$ssh_files" ]]; then
        while IFS= read -r f; do
            critical "SSH key tracked by git: $f"
            found=1
        done <<< "$ssh_files"
    fi

    # Credential files
    local cred_files
    cred_files=$(echo "$files" | grep -E '(credentials\.json|service-account.*\.json)$' || true)
    if [[ -n "$cred_files" ]]; then
        while IFS= read -r f; do
            critical "Credential file tracked by git: $f"
            found=1
        done <<< "$cred_files"
    fi

    # Check .gitignore coverage for common patterns
    if [[ -f "$REPO_ROOT/.gitignore" ]]; then
        local missing_patterns=()
        for pattern in ".env" "*.pem" "*.key" "*.p12" "*.pfx" "*.jks" "id_rsa" "id_ed25519"; do
            if ! grep -qF "$pattern" "$REPO_ROOT/.gitignore" 2>/dev/null; then
                missing_patterns+=("$pattern")
            fi
        done
        if [[ ${#missing_patterns[@]} -gt 0 ]]; then
            warning ".gitignore missing patterns: ${missing_patterns[*]}"
            if [[ "$FIX_MODE" == true ]]; then
                info "FIX: Adding missing patterns to .gitignore"
                echo "" >> "$REPO_ROOT/.gitignore"
                echo "# Security audit — sensitive file patterns" >> "$REPO_ROOT/.gitignore"
                for p in "${missing_patterns[@]}"; do
                    echo "$p" >> "$REPO_ROOT/.gitignore"
                done
            fi
        fi
    else
        warning "No .gitignore file found"
    fi

    if [[ $found -eq 0 ]]; then
        ok "No sensitive files tracked by git"
    fi
}

# ── Check 3: Vulnerable Dependencies ─────────────────────────────────────────

check_dependencies() {
    section_header "3. Vulnerable Dependencies"
    local checked=false

    cd "$REPO_ROOT"

    # Node.js / npm
    if [[ -f "package.json" ]]; then
        checked=true
        if command -v npm &>/dev/null; then
            info "Running npm audit..."
            local audit_output
            audit_output=$(npm audit --json 2>/dev/null || true)
            if [[ -n "$audit_output" ]]; then
                local high_count critical_count
                high_count=$(echo "$audit_output" | grep -o '"high":[0-9]*' | head -1 | cut -d: -f2 || echo "0")
                critical_count=$(echo "$audit_output" | grep -o '"critical":[0-9]*' | head -1 | cut -d: -f2 || echo "0")
                high_count=${high_count:-0}
                critical_count=${critical_count:-0}

                if [[ "$critical_count" -gt 0 ]]; then
                    critical "npm audit: $critical_count critical vulnerabilities"
                elif [[ "$high_count" -gt 0 ]]; then
                    critical "npm audit: $high_count high vulnerabilities"
                else
                    ok "npm audit: no high/critical vulnerabilities"
                fi
            fi
        else
            warning "npm not available — skipping npm audit"
        fi
    fi

    # Python / pip
    if [[ -f "requirements.txt" || -f "Pipfile" || -f "pyproject.toml" ]]; then
        checked=true
        if command -v pip-audit &>/dev/null; then
            info "Running pip-audit..."
            local pip_result
            if pip_result=$(pip-audit --format json 2>/dev/null); then
                local vuln_count
                vuln_count=$(echo "$pip_result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('dependencies',[])))" 2>/dev/null || echo "0")
                if [[ "$vuln_count" -gt 0 ]]; then
                    warning "pip-audit: $vuln_count vulnerable dependencies"
                else
                    ok "pip-audit: no vulnerabilities found"
                fi
            fi
        else
            warning "pip-audit not available — skipping Python dependency check"
        fi
    fi

    # Go
    if [[ -f "go.mod" ]]; then
        checked=true
        if command -v govulncheck &>/dev/null; then
            info "Running govulncheck..."
            if govulncheck ./... 2>/dev/null | grep -q "Vulnerability"; then
                critical "govulncheck: vulnerabilities found (run 'govulncheck ./...' for details)"
            else
                ok "govulncheck: no vulnerabilities found"
            fi
        else
            warning "govulncheck not available — skipping Go vulnerability check"
        fi
    fi

    if [[ "$checked" == false ]]; then
        info "No recognized dependency files found (package.json, requirements.txt, go.mod)"
    fi
}

# ── Check 4: Debug/Dev Leftovers ──────────────────────────────────────────────

check_debug_leftovers() {
    section_header "4. Debug / Dev Leftovers"
    local debug_warnings_before=$WARNING_COUNT
    local files

    cd "$REPO_ROOT"
    files=$(get_tracked_files)

    # Filter to source files, exclude test files
    local src_non_test
    src_non_test=$(echo "$files" | grep -E '\.(js|jsx|ts|tsx)$' | grep -v -E '(\.test\.|\.spec\.|__test__|__spec__|/test/|/tests/|/spec/)' || true)

    # console.log in non-test JS/TS files (warning)
    if [[ -n "$src_non_test" ]]; then
        local console_count
        console_count=$(echo "$src_non_test" | while IFS= read -r f; do grep -c 'console\.log' "$f" 2>/dev/null || true; done | awk '{sum+=$1} END{print sum+0}')
        if [[ "${console_count:-0}" -gt 0 ]]; then
            warning "Found $console_count console.log statement(s) in non-test files"
        fi
    fi

    # debugger statements (all source files)
    local all_src
    all_src=$(echo "$files" | grep -E '\.(js|jsx|ts|tsx|py|rb)$' || true)
    if [[ -n "$all_src" ]]; then
        local debugger_files
        debugger_files=$(echo "$all_src" | while IFS= read -r f; do
            if grep -qE '^\s*debugger\s*;?\s*$' "$f" 2>/dev/null; then echo "$f"; fi
        done)
        if [[ -n "$debugger_files" ]]; then
            while IFS= read -r f; do
                warning "debugger statement in: $f"
                if [[ "$FIX_MODE" == true ]]; then
                    info "FIX: Removing debugger from $f"
                    sed -i '/^\s*debugger\s*;*\s*$/d' "$f"
                fi
            done <<< "$debugger_files"
        fi
    fi

    # TODO / FIXME / HACK (warning)
    if [[ -n "$all_src" ]]; then
        local todo_count
        todo_count=$(echo "$all_src" | while IFS= read -r f; do grep -cE '(TODO|FIXME|HACK)\b' "$f" 2>/dev/null || true; done | awk '{sum+=$1} END{print sum+0}')
        if [[ "${todo_count:-0}" -gt 0 ]]; then
            warning "Found $todo_count TODO/FIXME/HACK comment(s)"
        fi
    fi

    # Python print() in non-test files
    local py_non_test
    py_non_test=$(echo "$files" | grep -E '\.py$' | grep -v -E '(test_|_test\.py|/tests/|/test/)' || true)
    if [[ -n "$py_non_test" ]]; then
        local print_count
        print_count=$(echo "$py_non_test" | while IFS= read -r f; do grep -cE '^\s*print\(' "$f" 2>/dev/null || true; done | awk '{sum+=$1} END{print sum+0}')
        if [[ "${print_count:-0}" -gt 0 ]]; then
            warning "Found $print_count print() statement(s) in non-test Python files"
        fi
    fi

    local debug_warnings_after=$WARNING_COUNT
    if [[ "$debug_warnings_after" -eq "$debug_warnings_before" ]]; then
        ok "No debug/dev leftovers found"
    fi
}

# ── Check 5: File Permissions ─────────────────────────────────────────────────

check_permissions() {
    section_header "5. File Permissions"
    local found=0

    cd "$REPO_ROOT"

    # Files with 777 permissions
    local perm_777
    perm_777=$(find . -not -path './.git/*' -not -path './node_modules/*' -not -path './vendor/*' -perm 0777 -type f 2>/dev/null || true)
    if [[ -n "$perm_777" ]]; then
        while IFS= read -r f; do
            warning "File with 777 permissions: $f"
            found=1
            if [[ "$FIX_MODE" == true ]]; then
                info "FIX: Setting permissions to 644 for $f"
                chmod 644 "$f"
            fi
        done <<< "$perm_777"
    fi

    # SUID/SGID files
    local suid_files
    suid_files=$(find . -not -path './.git/*' -not -path './node_modules/*' -not -path './vendor/*' \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null || true)
    if [[ -n "$suid_files" ]]; then
        while IFS= read -r f; do
            critical "SUID/SGID file found: $f"
            found=1
        done <<< "$suid_files"
    fi

    if [[ $found -eq 0 ]]; then
        ok "No permission issues found"
    fi
}

# ── Summary ───────────────────────────────────────────────────────────────────

print_summary() {
    echo -e "\n${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  📊 Summary${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"

    if [[ $CRITICAL_COUNT -gt 0 ]]; then
        echo -e "  ${RED}❌ CRITICAL: ${CRITICAL_COUNT}${NC}"
    fi
    if [[ $WARNING_COUNT -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠️  WARNINGS: ${WARNING_COUNT}${NC}"
    fi
    if [[ $INFO_COUNT -gt 0 ]]; then
        echo -e "  ${BLUE}ℹ️  INFO: ${INFO_COUNT}${NC}"
    fi

    echo ""

    if [[ $CRITICAL_COUNT -gt 0 ]]; then
        echo -e "  ${RED}${BOLD}❌ FAIL — ${CRITICAL_COUNT} critical issue(s) must be resolved before push${NC}"
        echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
        return 1
    elif [[ $WARNING_COUNT -gt 0 && "$STRICT_MODE" == true ]]; then
        echo -e "  ${YELLOW}${BOLD}❌ FAIL (strict mode) — ${WARNING_COUNT} warning(s) found${NC}"
        echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
        return 1
    elif [[ $WARNING_COUNT -gt 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}⚠️  PASS with warnings — review recommended${NC}"
        echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
        return 0
    else
        echo -e "  ${GREEN}${BOLD}✅ PASS — no issues found${NC}"
        echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
        return 0
    fi
}

# JSON output wrapper
print_json_summary() {
    cat <<EOF
{
  "version": "${VERSION}",
  "repository": "${REPO_ROOT}",
  "date": "$(date -Iseconds)",
  "critical": ${CRITICAL_COUNT},
  "warnings": ${WARNING_COUNT},
  "info": ${INFO_COUNT},
  "result": "$(if [[ $CRITICAL_COUNT -gt 0 ]]; then echo "FAIL"; elif [[ $WARNING_COUNT -gt 0 && "$STRICT_MODE" == true ]]; then echo "FAIL"; elif [[ $WARNING_COUNT -gt 0 ]]; then echo "PASS_WITH_WARNINGS"; else echo "PASS"; fi)"
}
EOF
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                usage
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --fix)
                FIX_MODE=true
                shift
                ;;
            --strict)
                STRICT_MODE=true
                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 2
                ;;
            *)
                REPO_ROOT="$1"
                shift
                ;;
        esac
    done

    # Validate repo root
    if [[ ! -d "$REPO_ROOT" ]]; then
        echo "Error: directory '$REPO_ROOT' does not exist" >&2
        exit 2
    fi

    if [[ ! -d "$REPO_ROOT/.git" ]]; then
        echo "Error: '$REPO_ROOT' is not a git repository" >&2
        exit 2
    fi

    # Resolve to absolute path
    REPO_ROOT=$(cd "$REPO_ROOT" && pwd)

    if [[ "$JSON_OUTPUT" == false ]]; then
        print_header
    fi

    # Run all checks
    check_secrets
    check_sensitive_files
    check_dependencies
    check_debug_leftovers
    check_permissions

    # Print results
    if [[ "$JSON_OUTPUT" == true ]]; then
        print_json_summary
        if [[ $CRITICAL_COUNT -gt 0 ]]; then
            exit 1
        elif [[ $WARNING_COUNT -gt 0 && "$STRICT_MODE" == true ]]; then
            exit 1
        fi
        exit 0
    else
        print_summary
    fi
}

main "$@"
