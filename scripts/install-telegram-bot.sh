#!/bin/bash
# ===================================================
# Telegram Issues Tracker Bot Installer
# 80/20 Solutions - Auto-install bot on OpenClaw VPS
# ===================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
BOT_DIR="/root/.openclaw/workspace-ciccio"
AGENTS_MD="${BOT_DIR}/AGENTS.md"
SCRIPTS_DIR="${BOT_DIR}/scripts"

log "🤖 Installing Telegram Issues Tracker Bot..."

# Check if we're on the correct system
if [ ! -d "/root/.openclaw" ]; then
    echo "❌ OpenClaw not found. This script is for OpenClaw VPS systems."
    exit 1
fi

# Ensure scripts directory exists
mkdir -p "$SCRIPTS_DIR"

# Copy bot script
log "📂 Installing bot script..."
cp "$(dirname "$0")/issue_slash_command.py" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/issue_slash_command.py"
success "Bot script installed to $SCRIPTS_DIR/issue_slash_command.py"

# Check if AGENTS.md exists and update it
if [ -f "$AGENTS_MD" ]; then
    log "📝 Updating AGENTS.md with bot integration..."
    
    # Check if the bot handler is already there
    if ! grep -q "from scripts.issue_slash_command import handle_issue_command" "$AGENTS_MD"; then
        # Add bot integration to AGENTS.md
        cat >> "$AGENTS_MD" << 'EOF'

## 🤖 Telegram Issues Tracker Bot Integration

The bot automatically creates structured GitHub issues from Telegram slash commands.

### Bot Handler Code (Already Integrated)
```python
from scripts.issue_slash_command import handle_issue_command
result = handle_issue_command(user_message, sender_name)
if result:
    return result
```

### Bot Features
- **Smart repository detection** based on keywords
- **PROJECT.md context analysis** for structured issues  
- **Vague description handling** with clarification questions
- **Structured issue creation** with acceptance criteria
- **Manual claude-code labeling** for processing control

### Usage in Telegram Issues Tracker Group
- `/issue - "description"` → Creates GitHub issue
- Bot analyzes PROJECT.md from target repository
- Creates structured issue with context-aware criteria
- Add `claude-code` label manually to trigger auto-processing

### Repository Keywords
- progetto-casa: casa, lavori, cantiere, cme, relazione, edificio
- maestro: maestro, automation, commands, control, energia
- BeachRef: beach, spiaggia, flutter, app mobile, arbitri
- GridConnect: grid, elettrico, enel, pratiche, energia
- StageConnect: stage, debug, browser, device, connect
- workflow: workflow, processo, automation, team

### Auto-Processing Workflow
1. Telegram `/issue` → Bot creates structured GitHub issue
2. Manual review → Add `claude-code` label when ready
3. PC Monitor → Claude Code auto-processes labeled issues  
4. Development → Automatic implementation with PROJECT.md updates
5. Deploy → Ciccio handles test environment deployment

EOF
        success "AGENTS.md updated with bot integration documentation"
    else
        warning "Bot integration already exists in AGENTS.md"
    fi
else
    warning "AGENTS.md not found. Bot installed but integration not documented."
fi

# Verify dependencies
log "🔍 Checking dependencies..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 required but not found"
    exit 1
fi

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) required but not found"
    exit 1
fi

# Test gh authentication
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI not authenticated. Run: gh auth login"
    exit 1
fi

# Test bot functionality
log "🧪 Testing bot functionality..."
cd "$BOT_DIR"
python3 -c "
from scripts.issue_slash_command import IssueSlashCommand
parser = IssueSlashCommand()
print('✅ Bot imports and initializes correctly')

# Test repository detection
issue_data = parser.parse_slash_command('/issue - \"test maestro feature\"')
print(f'✅ Repository detection works: {issue_data[\"repo\"]}')

# Test PROJECT.md reading (if available)
try:
    context = parser.analyze_repository_context('ecologicaleaving/maestro')
    if context['name']:
        print(f'✅ PROJECT.md reading works: {context[\"name\"]}')
    else:
        print('⚠️ PROJECT.md reading needs GitHub access or file not found')
except Exception as e:
    print(f'⚠️ PROJECT.md reading test failed: {e}')
    
print('✅ Bot functionality test completed')
"

if [ $? -eq 0 ]; then
    success "Bot functionality test passed"
else
    echo "❌ Bot functionality test failed"
    exit 1
fi

# Create usage example
log "📖 Creating usage examples..."
cat > "$BOT_DIR/telegram-bot-examples.md" << 'EOF'
# Telegram Issues Tracker Bot - Usage Examples

## Basic Commands

### Feature Requests
```
/issue - "progetto-casa upload documenti CME con parsing AI"
/issue - "maestro export PDF report energetici mensili"  
/issue - "BeachRef notifiche push per tornei"
```

### Bug Reports  
```
/issue - "bug maestro dashboard non carica dati storici"
/issue - "errore progetto-casa calcolo mutuo variabile"
```

### Improvements
```
/issue - "migliorare UI BeachRef lista arbitri più responsive"
/issue - "ottimizzare performance GridConnect parsing documenti"
```

## Bot Response Types

### Structured Issue (Good Description)
- ✅ Creates complete GitHub issue with context
- 📊 Includes PROJECT.md analysis  
- ✅ Acceptance criteria generated
- 🎯 Ready for manual review and labeling

### Clarification Request (Vague Description)
- ❓ Asks specific questions about requirements
- 📋 Lists project context for reference
- 💡 Suggests improved command format
- 🔄 Requires reformulation with more details

## Manual Processing Control

### Add `claude-code` Label When Ready
1. Review the generated issue 
2. Refine acceptance criteria if needed
3. Add `claude-code` label in GitHub
4. PC Monitor detects and auto-processes
5. Claude Code implements automatically

### Repository Auto-Detection
Bot automatically selects repository based on keywords:
- **progetto-casa**: casa, lavori, cantiere, cme, relazione  
- **maestro**: maestro, automation, energia, control
- **BeachRef**: beach, spiaggia, flutter, arbitri
- **GridConnect**: grid, elettrico, enel, pratiche
- **StageConnect**: stage, debug, browser, device

### PROJECT.md Context Integration
Bot reads PROJECT.md from GitHub to understand:
- Existing features (to avoid breaking them)
- Tech stack and architecture constraints  
- Project status and platform targets
- User flows and business context

This creates much more accurate and actionable issues!
EOF

success "Usage examples created at $BOT_DIR/telegram-bot-examples.md"

# Final summary
echo
echo "================================================================"
success "🎉 Telegram Issues Tracker Bot Installation Complete!"
echo "================================================================"
echo
echo "📍 Bot Location: $SCRIPTS_DIR/issue_slash_command.py"
echo "📖 Documentation: $BOT_DIR/telegram-bot-examples.md" 
echo "⚙️ Configuration: Integrated in AGENTS.md"
echo
echo "🚀 Ready to use in Telegram Issues Tracker Group!"
echo "   Command: /issue - \"description\""
echo "   Manual control: Add 'claude-code' label when ready"
echo
echo "🔗 Full Workflow:"
echo "   Telegram → GitHub Issue → Manual Review → Auto-Processing"
echo