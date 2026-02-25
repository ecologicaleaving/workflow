#!/bin/bash
# ===================================================
# Complete 80/20 Solutions Workflow Setup
# VPS (Ciccio) + PC (Claude Code) + Telegram Bot
# ===================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

title() {
    echo
    echo -e "${BOLD}${BLUE}═══ $1 ═══${NC}"
    echo
}

# Detect environment
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IS_VPS=false
IS_PC=false

if [ -d "/root/.openclaw" ] && [ -f "/etc/debian_version" ]; then
    IS_VPS=true
elif [ "$OS" = "Windows_NT" ] || command -v powershell &> /dev/null; then
    IS_PC=true
fi

title "🚀 80/20 Solutions Complete Workflow Setup"
echo "🔍 Environment Detection:"
if [ "$IS_VPS" = true ]; then
    echo "   📡 VPS (Ciccio) - OpenClaw orchestrator"
elif [ "$IS_PC" = true ]; then
    echo "   💻 PC (Claude Code) - Development agent" 
else
    echo "   ❓ Unknown environment"
fi
echo

# ===================================================
# VPS (CICCIO) SETUP
# ===================================================
if [ "$IS_VPS" = true ]; then
    title "📡 VPS (Ciccio) Setup"
    
    # 1. Install Telegram Bot
    log "🤖 Installing Telegram Issues Tracker Bot..."
    "$CURRENT_DIR/install-telegram-bot.sh"
    success "Telegram Bot installed and configured"
    
    # 2. Install Skills
    log "🛠️ Installing OpenClaw skills..."
    "$CURRENT_DIR/install-skills.sh"
    success "OpenClaw skills installed"
    
    # 3. Setup Commit Automation
    log "🔄 Installing commit automation..."
    "$CURRENT_DIR/install-commit-automation.sh"
    success "Commit automation installed"
    
    # 4. Test cross-instance communication
    log "🌐 Testing cross-instance communication..."
    if curl -s --max-time 5 http://100.80.106.79:18789/health &>/dev/null; then
        success "PC (Claude Code) is reachable via Tailscale"
        
        # Test authentication
        response=$(curl -s --max-time 5 \
            -H "Authorization: Bearer fd14dc3ae6d6cf69dc70481a2b1e13941eac7ad8685edb40" \
            -H "Content-Type: application/json" \
            -X POST http://100.80.106.79:18789/tools/invoke \
            -d '{"tool":"sessions_send","args":{"sessionKey":"agent:claudio:main","message":"VPS setup test - ignore this message"}}' 2>/dev/null)
        
        if echo "$response" | grep -q "success"; then
            success "Cross-instance authentication working"
        else
            warning "Cross-instance authentication may need setup"
        fi
    else
        warning "PC (Claude Code) not reachable - may be offline or not configured"
    fi
    
    title "✅ VPS (Ciccio) Setup Complete"
    echo "🎯 VPS Role: Orchestrator, Infrastructure, Deploy"
    echo "🤖 Bot: Ready for /issue commands in Telegram"
    echo "🔄 Skills: issue-resolver, github, weather, etc."
    echo "📡 Network: Monitoring PC for auto-processing"
    echo

# ===================================================
# PC (CLAUDE CODE) SETUP  
# ===================================================
elif [ "$IS_PC" = true ]; then
    title "💻 PC (Claude Code) Setup"
    
    # Check if we have PowerShell
    if command -v powershell &> /dev/null || [ "$OS" = "Windows_NT" ]; then
        log "🏗️ Installing Claude Code PC system..."
        
        # Run PowerShell installer
        if [ -f "$CURRENT_DIR/install-claude-pc.ps1" ]; then
            if command -v powershell &> /dev/null; then
                powershell -ExecutionPolicy Bypass -File "$CURRENT_DIR/install-claude-pc.ps1"
            else
                # Windows command prompt fallback
                powershell.exe -ExecutionPolicy Bypass -File "$CURRENT_DIR\\install-claude-pc.ps1"
            fi
            success "Claude Code PC system installed"
        else
            error "install-claude-pc.ps1 not found"
            exit 1
        fi
    else
        error "PowerShell not available. This setup requires Windows with PowerShell."
        exit 1
    fi
    
    title "✅ PC (Claude Code) Setup Complete"
    echo "🎯 PC Role: Development Agent, Auto-Processing"
    echo "🔍 Monitor: Checks GitHub issues every 5 minutes"  
    echo "🤖 Automation: Processes issues labeled 'claude-code'"
    echo "⚙️ Workflow: Research → Plan → Implement → Test → PR"
    echo

# ===================================================
# UNKNOWN ENVIRONMENT
# ===================================================
else
    error "Environment not recognized"
    echo
    echo "This setup script supports:"
    echo "  📡 VPS with OpenClaw (Linux/Debian)"
    echo "  💻 PC with Windows PowerShell"
    echo
    echo "Current environment:"
    echo "  OS: $(uname -s 2>/dev/null || echo $OS)"
    echo "  OpenClaw: $([ -d "/root/.openclaw" ] && echo "Found" || echo "Not found")"
    echo "  PowerShell: $(command -v powershell &> /dev/null && echo "Found" || echo "Not found")"
    exit 1
fi

# ===================================================
# FINAL WORKFLOW SUMMARY
# ===================================================
title "🎉 Setup Complete - Workflow Summary"

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│                  80/20 SOLUTIONS WORKFLOW                  │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                             │"
echo "│  1️⃣  Davide → /issue in Telegram Issues Tracker Group      │"
echo "│      📱 Bot creates structured GitHub issue                │" 
echo "│                                                             │"
echo "│  2️⃣  Review → Manual label 'claude-code' when ready       │"
echo "│      👀 Ciccio reviews acceptance criteria                 │"
echo "│                                                             │" 
echo "│  3️⃣  Auto-Processing → PC Monitor detects labeled issue    │"
echo "│      🤖 Claude Code: Research → Plan → Implement           │"
echo "│                                                             │"
echo "│  4️⃣  Implementation → Automated development workflow       │"
echo "│      ⚙️ Code → Test → Build → PR → review-ready label      │"
echo "│                                                             │"
echo "│  5️⃣  Deploy → Ciccio handles test environment             │"
echo "│      🚀 Deploy test → approval → production                │"
echo "│                                                             │"
echo "└─────────────────────────────────────────────────────────────┘"

echo
echo "🎯 ${BOLD}Key Features:${NC}"
if [ "$IS_VPS" = true ]; then
    echo "   ✅ Telegram Bot: Context-aware issue creation"
    echo "   ✅ Cross-instance: VPS ↔ PC communication ready"
    echo "   ✅ Skills: issue-resolver with PROJECT.md integration"
    echo "   ✅ Automation: Commit hooks and deploy workflows"
    echo
    echo "🔗 ${BOLD}Next Steps:${NC}"
    echo "   1. Test bot: Send /issue in Telegram Issues Tracker"
    echo "   2. Verify PC: Check Claude Code is online and monitoring"
    echo "   3. Test workflow: Create test issue → label → auto-process"
fi

if [ "$IS_PC" = true ]; then
    echo "   ✅ Issue Monitor: Checks GitHub every 5 minutes"
    echo "   ✅ Auto-Processing: Full development workflow automation"  
    echo "   ✅ PROJECT.md: Automatic version bump and backlog updates"
    echo "   ✅ Cross-instance: PC ↔ VPS communication configured"
    echo
    echo "🔗 ${BOLD}Next Steps:${NC}"
    echo "   1. Verify monitor: Check Task Scheduler is running"
    echo "   2. Test processing: Wait for 'claude-code' labeled issues"
    echo "   3. Monitor logs: Check claude_monitor_log.txt for activity"
fi

echo
title "🌟 Workflow Ready!"
echo "The complete 80/20 Solutions automated development pipeline is now active."
echo "From idea to implementation: fully automated, context-aware, and intelligent."
echo