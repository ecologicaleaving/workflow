#!/usr/bin/env python3
"""
Universal Deploy Notifier for all 8020 Solutions repositories
Sends deployment status updates to Telegram
"""
import os
import sys
import json
import requests
from datetime import datetime
from typing import Dict, Optional

# Configuration
BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
CHAT_ID = os.getenv('TELEGRAM_CHAT_ID')

if not BOT_TOKEN or not CHAT_ID:
    print("❌ TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID env vars are required")
    sys.exit(1)
TELEGRAM_API = f"https://api.telegram.org/bot{BOT_TOKEN}"

# Test URLs per repo
TEST_URLS = {
    'maestroweb':     'https://test-maestroweb.8020solutions.org',
    'BeachCRER':      'https://test-beachcrer.8020solutions.org',
    'StageConnect':   'https://apps.8020solutions.org/downloads/test/',
    'BeachRef-app':   'https://apps.8020solutions.org/downloads/test/',
    'finn':           'https://apps.8020solutions.org/downloads/test/',
    'musicbuddy-app': 'https://apps.8020solutions.org/downloads/test/',
    'musicbuddy-web': None,
}

# Status emojis
STATUS_EMOJI = {
    'in_progress': '🔄',
    'success': '✅',
    'failed': '❌',
    'deploy': '🚀',
    'build': '🏗️',
    'release': '📦',
    'merge': '🔀',
    'test': '🧪'
}

def format_message(
    repo: str,
    event_type: str,
    status: str,
    branch: str,
    link: str,
    details: Optional[str] = None
) -> str:
    """Format deployment notification message"""

    repo_name = repo.split('/')[-1]
    status_emoji = STATUS_EMOJI.get(status, '📌')
    type_emoji = STATUS_EMOJI.get(event_type, '⚙️')

    # Status text
    if status == 'in_progress':
        status_text = "In progress..."
    elif status == 'success':
        status_text = "Success! Live 🎉"
    elif status == 'failed':
        status_text = "Failed ⚠️"
    else:
        status_text = status.capitalize()

    # Build message
    msg = f"{status_emoji} **{repo_name}** {type_emoji}\n"
    msg += f"Branch: `{branch}`\n"
    msg += f"Status: {status_text}\n"

    if link:
        msg += f"[View on GitHub]({link})\n"

    # Test URL (solo su success)
    if status == 'success':
        test_url = TEST_URLS.get(repo_name)
        if test_url:
            msg += f"[Testa qui]({test_url})\n"

    if details:
        msg += f"\n```\n{details}\n```"

    msg += f"\n__{datetime.now().strftime('%H:%M UTC')}__"

    return msg

def send_notification(
    repo: str,
    event_type: str,
    status: str,
    branch: str = "main",
    link: str = "",
    details: str = ""
) -> bool:
    """Send notification via Telegram"""
    
    try:
        message = format_message(repo, event_type, status, branch, link, details)
        
        payload = {
            'chat_id': CHAT_ID,
            'text': message,
            'parse_mode': 'Markdown',
            'disable_web_page_preview': True
        }
        
        response = requests.post(
            f"{TELEGRAM_API}/sendMessage",
            json=payload,
            timeout=10
        )
        
        if response.status_code == 200:
            print(f"✅ Notification sent for {repo} ({status})")
            return True
        else:
            print(f"❌ Failed to send notification: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error sending notification: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage: deploy-notify.py <repo> <type> <status> <branch> [link] [details]")
        print("Example: deploy-notify.py ecologicaleaving/beachcrer deploy success main https://github.com/... 'Optional details'")
        sys.exit(1)
    
    repo = sys.argv[1]
    event_type = sys.argv[2]
    status = sys.argv[3]
    branch = sys.argv[4]
    link = sys.argv[5] if len(sys.argv) > 5 else ""
    details = sys.argv[6] if len(sys.argv) > 6 else ""
    
    success = send_notification(repo, event_type, status, branch, link, details)
    sys.exit(0 if success else 1)
