#!/usr/bin/env python3
"""
TRIAGE COMMAND /triage for Issues Tracker Group
Presents unassigned issues one by one with inline buttons for label assignment
"""
import subprocess
import json
import os
from typing import Optional, List, Dict

TRIAGE_STATE_FILE = os.path.join(os.path.dirname(__file__), "../memory/triage_state.json")

def save_triage_state(message_id: str = None, pending_issue: Dict = None):
    """Track active triage message ID and pending issue"""
    try:
        state = load_triage_state()
        if message_id:
            history = state.get("history", [])
            if state.get("active_message_id"):
                history.append(state["active_message_id"])
            state["active_message_id"] = str(message_id)
            state["history"] = history[-10:]
        if pending_issue is not None:
            state["pending_issue"] = pending_issue
        os.makedirs(os.path.dirname(TRIAGE_STATE_FILE), exist_ok=True)
        with open(TRIAGE_STATE_FILE, "w") as f:
            json.dump(state, f)
    except Exception:
        pass

def save_triage_message_id(message_id: str):
    save_triage_state(message_id=message_id)

def load_triage_state() -> dict:
    try:
        with open(TRIAGE_STATE_FILE) as f:
            return json.load(f)
    except Exception:
        return {}

def get_previous_triage_message_ids() -> list:
    """Return list of old message IDs to invalidate"""
    state = load_triage_state()
    ids = state.get("history", [])
    if state.get("active_message_id"):
        ids = ids + [state["active_message_id"]]
    return ids

ASSIGNABLE_LABELS = ["claude-code", "ciccio", "codex"]
WORKFLOW_LABELS = ["in-progress", "review-ready", "deployed-test", "needs-fix"]  # già in lavorazione

LABEL_EMOJI = {
    "claude-code": "🤖",
    "ciccio": "🖥️",
    "codex": "⚡",
}

def get_open_unassigned_issues() -> List[Dict]:
    """Get all open issues without assignable labels across repos"""
    repos = [
        "ecologicaleaving/progetto-casa",
        "ecologicaleaving/BeachRef-app",
        "ecologicaleaving/finn",
        "ecologicaleaving/StageConnect",
        "ecologicaleaving/maestro",
        "ecologicaleaving/x32-Assist",
        "ecologicaleaving/GridConnect",
    ]

    unassigned = []
    for repo in repos:
        result = subprocess.run(
            ["gh", "issue", "list", "--repo", repo, "--state", "open",
             "--json", "number,title,labels,url,body"],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            continue

        issues = json.loads(result.stdout or "[]")
        for issue in issues:
            labels = [l["name"] for l in issue.get("labels", [])]
            has_agent = any(l in ASSIGNABLE_LABELS for l in labels)
            already_in_progress = any(l in WORKFLOW_LABELS for l in labels)
            if not has_agent and not already_in_progress:
                issue["repo"] = repo
                issue["repo_short"] = repo.split("/")[1]
                issue["current_labels"] = labels
                unassigned.append(issue)

    return unassigned


def format_issue_message(issue: Dict, total: int, index: int) -> str:
    """Format issue for Telegram display"""
    repo = issue["repo_short"]
    number = issue["number"]
    title = issue["title"]
    labels = issue["current_labels"]
    url = issue["url"]

    label_str = f"🏷️ `{', '.join(labels)}`\n" if labels else ""

    return (
        f"📋 *Issue {index + 1}/{total}*\n\n"
        f"📁 `{repo} #{number}`\n"
        f"📌 *{title}*\n\n"
        f"{label_str}"
        f"🔗 [Apri su GitHub]({url})"
    )


def build_buttons(issue: Dict) -> list:
    """No inline buttons - use text-based replies instead (no loading spinner)"""
    return []


def parse_ta_command(message: str) -> Optional[dict]:
    """Parse /ta repo number action command"""
    import re
    match = re.match(r'/ta\s+(\S+)\s+(\d+)\s+(\S+)', message.strip())
    if not match:
        return None
    repo_short, number, action = match.groups()
    # Find full repo name
    repo_map = {r.split("/")[1]: r for r in [
        "ecologicaleaving/progetto-casa",
        "ecologicaleaving/StageConnect",
        "ecologicaleaving/BeachRef-app",
        "ecologicaleaving/BeachRef",
        "ecologicaleaving/maestro",
        "ecologicaleaving/finn",
        "ecologicaleaving/sun-stop-timer",
        "ecologicaleaving/GridConnect",
        "ecologicaleaving/x32-Assist",
        "ecologicaleaving/workflow",
    ]}
    full_repo = repo_map.get(repo_short, f"ecologicaleaving/{repo_short}")
    if action in ASSIGNABLE_LABELS:
        return {"action": "assign", "repo": full_repo, "number": number, "label": action}
    elif action == "skip":
        return {"action": "skip", "repo": full_repo, "number": number}
    elif action == "close":
        return {"action": "close", "repo": full_repo, "number": number}
    return None


def group_issues_by_repo(issues: List[Dict]) -> Dict[str, List[Dict]]:
    """Group issues by repository, bugs first within each repo"""
    grouped = {}
    for issue in issues:
        repo = issue["repo_short"]
        if repo not in grouped:
            grouped[repo] = []
        grouped[repo].append(issue)

    # Sort each repo: bugs first, then features/others
    for repo in grouped:
        grouped[repo].sort(key=lambda i: (
            0 if any("bug" in l for l in i["current_labels"]) else 1,
            i["number"]
        ))

    return grouped


def format_issue_message(issue: Dict, index: int, total_in_repo: int, repo_index: int, total_repos: int) -> str:
    """Format issue for Telegram display with text-based options"""
    repo = issue["repo_short"]
    number = issue["number"]
    title = issue["title"]
    labels = issue["current_labels"]
    url = issue["url"]

    label_str = f"🏷️ `{', '.join(labels)}`\n" if labels else ""

    options = (
        f"\n👇 *Rispondi con:*\n"
        f"1️⃣ `claude-code` — 🤖 Claude Code\n"
        f"2️⃣ `ciccio` — 🖥️ Ciccio VPS\n"
        f"3️⃣ `codex` — ⚡ Codex\n"
        f"▶️ `salta` — passa oltre\n"
        f"🔒 `chiudi` — chiudi issue"
    )

    return (
        f"📁 *{repo}* — progetto {repo_index}/{total_repos}\n"
        f"📋 *Issue {index}/{total_in_repo}*\n\n"
        f"📌 *{title}*\n\n"
        f"{label_str}"
        f"🔗 [Apri su GitHub]({url})"
        f"{options}"
    )


def next_issue_message(issues: List[Dict], current_repo_short: str = None) -> Optional[dict]:
    """Build the next issue message and save pending state"""
    if not issues:
        save_triage_state(pending_issue={})
        return {"text": "🎉 *Triage completato!* Tutte le issue sono assegnate.", "buttons": []}

    grouped = group_issues_by_repo(issues)
    repos = list(grouped.keys())

    # Stay on same repo if it still has issues
    if current_repo_short and current_repo_short in grouped:
        next_repo = current_repo_short
    else:
        next_repo = repos[0]

    issue = grouped[next_repo][0]
    repo_index = repos.index(next_repo) + 1
    issue_index = grouped[next_repo].index(issue) + 1
    total_in_repo = len(grouped[next_repo])

    save_triage_state(pending_issue={
        "repo": issue["repo"],
        "repo_short": issue["repo_short"],
        "number": str(issue["number"]),
        "title": issue["title"],
    })

    text = format_issue_message(issue, issue_index, total_in_repo, repo_index, len(repos))
    return {"text": text, "buttons": []}


def handle_triage_command() -> Optional[dict]:
    """Start triage session - returns first issue grouped by repo"""
    issues = get_open_unassigned_issues()

    if not issues:
        save_triage_state(pending_issue={})
        return {"text": "✅ *Tutto in ordine!*\n\nNon ci sono issue aperte senza assegnazione.", "buttons": []}

    grouped = group_issues_by_repo(issues)
    repos = list(grouped.keys())
    first_repo = repos[0]
    first_issue = grouped[first_repo][0]

    save_triage_state(pending_issue={
        "repo": first_issue["repo"],
        "repo_short": first_issue["repo_short"],
        "number": str(first_issue["number"]),
        "title": first_issue["title"],
    })

    header = f"🗂️ *Triage issues* — {len(issues)} da assegnare in {len(repos)} progetti\n\n"
    body = format_issue_message(first_issue, 1, len(grouped[first_repo]), 1, len(repos))

    return {"text": header + body, "buttons": [], "invalidate_previous": True}


def handle_triage_reply(reply: str) -> Optional[dict]:
    """Handle text reply during triage (1/2/3/claude-code/ciccio/codex/salta/chiudi)"""
    SHORTCUTS = {"1": "claude-code", "2": "ciccio", "3": "codex"}
    reply = reply.strip().lower()
    action = SHORTCUTS.get(reply, reply)

    state = load_triage_state()
    pending = state.get("pending_issue", {})

    if not pending or not pending.get("repo"):
        return None  # No active triage

    repo = pending["repo"]
    repo_short = pending["repo_short"]
    number = pending["number"]

    if action in ASSIGNABLE_LABELS:
        r1 = subprocess.run(
            ["gh", "issue", "edit", number, "--repo", repo, "--add-label", action],
            capture_output=True, text=True
        )
        r2 = subprocess.run(
            ["gh", "issue", "edit", number, "--repo", repo, "--add-assignee", "ecologicaleaving"],
            capture_output=True, text=True
        )
        action_text = (
            f"✅ `{repo_short} #{number}` → *{action}* + @ecologicaleaving"
            if r1.returncode == 0 and r2.returncode == 0
            else f"❌ Errore assegnazione"
        )

    elif action == "salta":
        action_text = f"⏭️ Saltata `{repo_short} #{number}`"

    elif action == "chiudi":
        result = subprocess.run(
            ["gh", "issue", "close", number, "--repo", repo, "--reason", "not planned"],
            capture_output=True, text=True
        )
        action_text = (
            f"🔒 Chiusa `{repo_short} #{number}`"
            if result.returncode == 0 else f"❌ Errore chiusura"
        )
    else:
        return None  # Not a triage reply

    issues = get_open_unassigned_issues()
    next_result = next_issue_message(issues, repo_short)

    separator = "\n\n➡️ *Prossimo progetto*\n\n" if (
        issues and issues[0]["repo_short"] != repo_short
    ) else "\n\n"

    return {"text": action_text + separator + next_result["text"], "buttons": []}


def handle_callback(callback_data: str) -> Optional[dict]:
    """Handle button press callback - respects repo grouping"""
    parts = callback_data.split(":")
    current_repo = parts[1] + "/" + parts[2] if len(parts) >= 3 else ""
    # Rebuild repo correctly (format: "assign:org/repo:number:label")
    # callback_data = "assign:ecologicaleaving/BeachRef-app:2:claude-code"
    # Split carefully
    # callback_data format: "action:org/repo:number[:label]"
    # parts = ["action", "org/repo", "number", "label?"]
    action = parts[0]
    repo = parts[1]       # "ecologicaleaving/BeachRef-app"
    number = parts[2]     # "2"
    label = parts[3] if len(parts) > 3 else None
    repo_short = repo.split("/")[1]

    if action == "assign":
        # 1) Aggiungi label agente
        r1 = subprocess.run(
            ["gh", "issue", "edit", number, "--repo", repo, "--add-label", label],
            capture_output=True, text=True
        )
        # 2) Assegna a ecologicaleaving
        r2 = subprocess.run(
            ["gh", "issue", "edit", number, "--repo", repo, "--add-assignee", "ecologicaleaving"],
            capture_output=True, text=True
        )
        if r1.returncode == 0 and r2.returncode == 0:
            action_text = f"✅ `{repo_short} #{number}` → *{label}* + assegnata a @ecologicaleaving"
        else:
            action_text = f"❌ Errore assegnazione (label:{r1.returncode} assignee:{r2.returncode})"

    elif action == "skip":
        action_text = f"⏭️ Saltata `{repo_short} #{number}`"

    elif action == "close":
        result = subprocess.run(
            ["gh", "issue", "close", number, "--repo", repo, "--reason", "not planned"],
            capture_output=True, text=True
        )
        action_text = f"🔒 Chiusa `{repo_short} #{number}`" if result.returncode == 0 else f"❌ Errore chiusura"
    else:
        return None

    # Fetch remaining issues grouped by repo
    issues = get_open_unassigned_issues()
    if not issues:
        return {
            "text": f"{action_text}\n\n🎉 *Triage completato!* Tutte le issue sono assegnate.",
            "buttons": None
        }

    grouped = group_issues_by_repo(issues)
    repos = list(grouped.keys())

    # Stay on same repo if it still has issues, else move to next
    if repo_short in grouped:
        next_repo = repo_short
    else:
        next_repo = repos[0]

    next_issue = grouped[next_repo][0]
    repo_index = repos.index(next_repo) + 1
    issue_index = grouped[next_repo].index(next_issue) + 1
    total_in_repo = len(grouped[next_repo])

    # Show separator when switching repo
    if repo_short != next_repo:
        separator = f"\n\n➡️ *Prossimo progetto: {next_repo}*\n\n"
    else:
        separator = "\n\n"

    next_text = action_text + separator + format_issue_message(
        next_issue, issue_index, total_in_repo, repo_index, len(repos)
    )
    buttons = build_buttons(next_issue)

    return {"text": next_text, "buttons": buttons}


if __name__ == "__main__":
    result = handle_triage_command()
    if result:
        print(result["text"])
        if result.get("buttons"):
            print("\nBUTTONS:", json.dumps(result["buttons"], indent=2))
