#!/bin/bash
# claude-code-issue-monitor.sh - DEPRECATO
# Sistema sostituito da setup Windows PC con Task Scheduler
# Vedere: scripts/claude-code-pc-setup.md

echo "⚠️ SCRIPT DEPRECATO"
echo "Nuovo sistema: Claude Code PC Windows con Task Scheduler ogni 5min"
echo "Documentazione: scripts/claude-code-pc-setup.md"
exit 1

# LEGACY CODE BELOW - NON UTILIZZARE

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} ✅ $1"
}

warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} ⚠️ $1"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} ❌ $1"
}

# Ensure work directory exists
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Function to extract clear goals from issue body
extract_goals() {
    local issue_body="$1"
    local issue_title="$2"
    
    # Look for explicit goals/requirements/tasks sections
    goals=$(echo "$issue_body" | grep -i -A 20 -E "(goals?|tasks?|requirements?|todo|checklist)" || echo "")
    
    if [ -z "$goals" ]; then
        # Extract from title and description
        echo "PRIMARY GOAL: $issue_title
        
DERIVED REQUIREMENTS:
$(echo "$issue_body" | head -10 | sed 's/^/- /')"
    else
        echo "$goals"
    fi
}

# Function to process single issue with iterative planning
process_issue() {
    local repo="$1"
    local issue_num="$2"
    local title="$3"
    local body="$4"
    
    log "🎯 Starting iterative processing: $repo#$issue_num"
    
    # Extract clear goals
    goals=$(extract_goals "$body" "$title")
    
    success "Goals extracted for $repo#$issue_num"
    
    # Mark issue as in-progress
    gh issue edit "$issue_num" --repo "$REPO_OWNER/$repo" \
        --remove-label "claude-code" \
        --add-label "in-progress" 2>/dev/null || warning "Could not update issue labels"
    
    # Comment on issue with start notification
    gh issue comment "$issue_num" --repo "$REPO_OWNER/$repo" \
        --body "🤖 **Claude Code Auto-Processing Started**

**Goals Identified:**
$goals

**Process:**
1. ✅ Context cleared - starting fresh
2. 🎯 Planning phase initiated  
3. 🔄 Iterative development with context resets
4. 🧪 Testing and verification
5. 📦 Build and deployment preparation
6. ✅ Goal validation and completion

Status updates will follow..." 2>/dev/null || warning "Could not comment on issue"

    # PHASE 1: Clear context and create initial plan
    log "📋 PHASE 1: Initial Planning (Context Reset #1)"
    
    claude "/clear
    
FRESH START - ISSUE PROCESSING

Repository: $repo  
Issue: #$issue_num
Title: $title

CLEAR GOALS:
$goals

TASK: Create detailed implementation plan
- Break down into specific, measurable steps
- Identify technical requirements  
- Define success criteria for each step
- Estimate complexity and time
- Plan testing strategy

Respond with ONLY the detailed plan. Keep it concise but complete."

    sleep 5
    
    # PHASE 2: Clear context and refine plan
    log "🔄 PHASE 2: Plan Refinement (Context Reset #2)"
    
    claude "/clear

CONTEXT: Working on $repo issue #$issue_num - $title

GOALS:
$goals

TASK: Review and refine implementation approach
- Consider edge cases and potential issues
- Validate technical approach
- Confirm all goals are addressable  
- Finalize step-by-step execution plan

Previous context cleared. Respond with refined, actionable plan."

    sleep 5
    
    # PHASE 3: Clear context and begin implementation
    log "🔧 PHASE 3: Implementation (Context Reset #3)"
    
    claude "/clear

IMPLEMENTATION PHASE

Repository: $repo
Issue: #$issue_num - $title

FINAL GOALS TO ACHIEVE:
$goals

TASK: Execute implementation
1. Clone/update repository if needed: $REPO_OWNER/$repo
2. Implement solution step by step
3. Test thoroughly 
4. Ensure ALL goals are met
5. Build if applicable (Flutter APK, web, etc.)
6. Commit with message: 'Fix #$issue_num: $title'
7. Push to appropriate branch

Work directory: $WORK_DIR
Start implementation NOW. Report progress and completion."

    # Update issue with progress
    gh issue comment "$issue_num" --repo "$REPO_OWNER/$repo" \
        --body "🔧 **Implementation Phase Started**

✅ Context reset completed (3x)
✅ Goals clarified and refined  
🔧 Implementation in progress...

Working in: $WORK_DIR
Target goals: All requirements from issue description" 2>/dev/null || warning "Could not update issue progress"

    success "Issue $repo#$issue_num processing initiated with iterative planning"
}

# Main monitoring loop
main() {
    log "🚀 Claude Code Issue Monitor started"
    log "👀 Monitoring: $REPO_OWNER repositories"
    log "⏱️ Check interval: ${MONITORING_INTERVAL}s"
    log "📁 Work directory: $WORK_DIR"
    
    while true; do
        # Get issues tagged 'claude-code'
        NEW_ISSUES=$(gh issue list \
            --search "org:$REPO_OWNER label:claude-code state:open" \
            --json number,title,body,repository \
            --limit 10 2>/dev/null || echo "[]")
        
        # Process each issue
        echo "$NEW_ISSUES" | jq -r '.[] | "\(.repository.name)|\(.number)|\(.title)|\(.body)"' 2>/dev/null | while IFS='|' read -r repo issue_num title body; do
            
            if [ -n "$repo" ] && [ -n "$issue_num" ]; then
                log "📥 Found new issue: $repo#$issue_num - $title"
                process_issue "$repo" "$issue_num" "$title" "$body"
            fi
        done
        
        # Wait before next check
        sleep $MONITORING_INTERVAL
    done
}

# Cleanup function
cleanup() {
    log "🛑 Shutting down Claude Code Issue Monitor..."
    exit 0
}

# Handle signals
trap cleanup SIGINT SIGTERM

# Check dependencies
command -v gh >/dev/null 2>&1 || { error "GitHub CLI (gh) is required but not installed. Aborting."; exit 1; }
command -v claude >/dev/null 2>&1 || { error "Claude CLI is required but not installed. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { error "jq is required but not installed. Aborting."; exit 1; }

# Start monitoring
main "$@"