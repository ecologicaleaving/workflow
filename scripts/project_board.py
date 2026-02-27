"""
project_board.py — Helper per muovere card su GitHub Project #2 (80/20 Solutions Dev Hub)

Uso:
    from project_board import move_card

    move_card("ecologicaleaving/finn", 6, "In Progress")
    move_card("ecologicaleaving/BeachRef-app", 2, "Test")
"""

import subprocess
import json
import logging

# ── Costanti GitHub Project ────────────────────────────────────────────────────
PROJECT_ID     = "PVT_kwHODSTPQM4BP1Xp"
STATUS_FIELD_ID = "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"

STATUS_OPTIONS = {
    "Todo":        "f75ad846",
    "In Progress": "47fc9ee4",
    "PUSH":        "03f548ab",
    "Test":        "1d6a37f9",
    "Done":        "98236657",
}

log = logging.getLogger(__name__)


def _gh(*args) -> dict | list | None:
    """Esegue gh CLI e ritorna il JSON parsed, o None in caso di errore."""
    try:
        result = subprocess.run(
            ["gh", *args],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            log.warning("gh error: %s", result.stderr.strip())
            return None
        return json.loads(result.stdout) if result.stdout.strip() else {}
    except Exception as e:
        log.warning("gh exception: %s", e)
        return None


def _get_item_id(repo: str, issue_number: int) -> str | None:
    """Trova l'item ID nel Project per una data issue."""
    owner = repo.split("/")[0]
    query = """
    query($owner: String!) {
      user(login: $owner) {
        projectV2(number: 2) {
          items(first: 100) {
            nodes {
              id
              content {
                ... on Issue {
                  number
                  repository { nameWithOwner }
                }
              }
            }
          }
        }
      }
    }
    """
    data = _gh("api", "graphql",
               "-f", f"query={query}",
               "-f", f"owner={owner}")

    if not data:
        return None

    try:
        items = data["data"]["user"]["projectV2"]["items"]["nodes"]
        for item in items:
            content = item.get("content", {})
            if (content.get("number") == issue_number and
                    repo.lower() in content.get("repository", {}).get("nameWithOwner", "").lower()):
                return item["id"]
    except (KeyError, TypeError) as e:
        log.warning("Parsing error: %s", e)

    return None


def move_card(repo: str, issue_number: int, column: str) -> bool:
    """
    Sposta la card di un'issue su una colonna del Project board.

    Args:
        repo:         es. "ecologicaleaving/finn"
        issue_number: numero issue (int)
        column:       "Todo" | "In Progress" | "PUSH" | "Test" | "Done"

    Returns:
        True se successo, False altrimenti
    """
    option_id = STATUS_OPTIONS.get(column)
    if not option_id:
        log.error("Colonna '%s' non valida. Usa: %s", column, list(STATUS_OPTIONS))
        return False

    item_id = _get_item_id(repo, issue_number)
    if not item_id:
        log.warning("Item non trovato nel Project per %s#%d", repo, issue_number)
        # Provo ad aggiungere l'issue al project prima
        _gh("project", "item-add", "2",
            "--owner", repo.split("/")[0],
            "--url", f"https://github.com/{repo}/issues/{issue_number}")
        item_id = _get_item_id(repo, issue_number)
        if not item_id:
            return False

    mutation = """
    mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project
        itemId: $item
        fieldId: $field
        value: { singleSelectOptionId: $option }
      }) {
        projectV2Item { id }
      }
    }
    """
    result = _gh("api", "graphql",
                 "-f", f"query={mutation}",
                 "-f", f"project={PROJECT_ID}",
                 "-f", f"item={item_id}",
                 "-f", f"field={STATUS_FIELD_ID}",
                 "-f", f"option={option_id}")

    if result is None:
        return False

    log.info("Card %s#%d → %s ✅", repo, issue_number, column)
    return True


# ── Shortcut per casi comuni ───────────────────────────────────────────────────

def card_todo(repo, issue_number):        return move_card(repo, issue_number, "Todo")
def card_in_progress(repo, issue_number): return move_card(repo, issue_number, "In Progress")
def card_push(repo, issue_number):        return move_card(repo, issue_number, "PUSH")
def card_test(repo, issue_number):        return move_card(repo, issue_number, "Test")
def card_done(repo, issue_number):        return move_card(repo, issue_number, "Done")


if __name__ == "__main__":
    import sys
    logging.basicConfig(level=logging.INFO)
    if len(sys.argv) == 4:
        repo_, num_, col_ = sys.argv[1], int(sys.argv[2]), sys.argv[3]
        ok = move_card(repo_, num_, col_)
        print("✅ OK" if ok else "❌ FAILED")
    else:
        print("Uso: python3 project_board.py <owner/repo> <issue_number> <colonna>")
        print("Colonne:", list(STATUS_OPTIONS.keys()))
