#!/usr/bin/env python3
"""
AUTO ISSUE PARSER for Issues Tracker Group
Recognizes patterns in Davide's messages and auto-creates GitHub issues
"""
import re
import subprocess
import json
from typing import Dict, Optional, List

class AutoIssueParser:
    def __init__(self):
        self.patterns = {
            'feature_request': [
                r'voglio\s+(?:poter\s+)?(.+)',
                r'servire\s+(.+)',
                r'implementare\s+(.+)',
                r'aggiungere\s+(.+)',
                r'creare\s+(?:un\s+)?(.+)',
                r'per\s+(.+)\s+voglio\s+(.+)',
                r'nel\s+(.+)\s+per\s+(.+)',
            ],
            'bug_report': [
                r'(?:bug|errore|problema)\s+(?:in\s+|con\s+|nel\s+)?(.+)',
                r'non\s+funziona\s+(.+)',
                r'(.+)\s+non\s+va',
            ],
            'improvement': [
                r'migliorare\s+(.+)',
                r'ottimizzare\s+(.+)',
                r'rendere\s+(.+)\s+più\s+(.+)',
            ]
        }
        
        self.repos = {
            'progetto-casa': ['casa', 'lavori', 'cantiere', 'cme', 'relazione'],
            'stageconnect': ['stage', 'debug', 'browser', 'device'],
            'beachref': ['beach', 'spiaggia', 'flutter'],
            'maestro': ['maestro', 'automation', 'commands'],
            'finn': ['finn', 'finance', 'tracking'],
            'autodrum': ['drum', 'audio', 'reaper'],
            'gridconnect': ['grid', 'elettrico', 'enel', 'pratiche']
        }
    
    def detect_repo(self, text: str) -> str:
        """Detect repository from message content"""
        text_lower = text.lower()
        
        for repo, keywords in self.repos.items():
            if any(keyword in text_lower for keyword in keywords):
                return f"ecologicaleaving/{repo}"
        
        # Default fallback
        return "ecologicaleaving/progetto-casa"
    
    def extract_issue_info(self, message: str) -> Optional[Dict]:
        """Extract issue information from message"""
        for issue_type, patterns in self.patterns.items():
            for pattern in patterns:
                match = re.search(pattern, message, re.IGNORECASE)
                if match:
                    groups = match.groups()
                    repo = self.detect_repo(message)
                    
                    if issue_type == 'feature_request':
                        if len(groups) == 2:  # "per X voglio Y"
                            context = groups[0]
                            feature = groups[1]
                            title = f"Feature: {feature.strip()}"
                            description = f"Per {context}, implementare: {feature}"
                        else:
                            feature = groups[0].strip()
                            title = f"Feature: {feature}"
                            description = f"Implementare: {feature}"
                    
                    elif issue_type == 'bug_report':
                        bug = groups[0].strip()
                        title = f"Bug: {bug}"
                        description = f"Problema riscontrato: {bug}"
                    
                    elif issue_type == 'improvement':
                        improvement = groups[0].strip()
                        title = f"Improvement: {improvement}"
                        description = f"Migliorare: {improvement}"
                    
                    return {
                        'type': issue_type,
                        'title': title,
                        'description': description,
                        'repo': repo,
                        'original_message': message,
                        'labels': [issue_type.replace('_', '-')]
                    }
        
        return None
    
    def create_github_issue(self, issue_info: Dict) -> Optional[str]:
        """Create GitHub issue using gh CLI"""
        try:
            cmd = [
                'gh', 'issue', 'create',
                '--repo', issue_info['repo'],
                '--title', issue_info['title'],
                '--body', f"{issue_info['description']}\n\n**Original message:** {issue_info['original_message']}\n\n**Auto-created by Issues Tracker Bot**",
                '--label', ','.join(issue_info['labels'])
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.strip()  # GitHub issue URL
            else:
                print(f"Error creating issue: {result.stderr}")
                return None
                
        except Exception as e:
            print(f"Error: {e}")
            return None

def parse_message(message: str, author: str = "davide crescentini") -> Optional[str]:
    """Main function to parse message and create issue if needed"""
    if author.lower() != "davide crescentini":
        return None  # Only process Davide's messages
    
    parser = AutoIssueParser()
    issue_info = parser.extract_issue_info(message)
    
    if issue_info:
        issue_url = parser.create_github_issue(issue_info)
        if issue_url:
            return f"✅ **Issue creata automaticamente:**\n🔗 {issue_url}\n📋 **Tipo:** {issue_info['type']}\n📁 **Repo:** {issue_info['repo']}"
        else:
            return f"❌ Errore nella creazione automatica issue per: {issue_info['title']}"
    
    return None  # No pattern matched

if __name__ == "__main__":
    # Test cases
    test_messages = [
        "in progetto-casa per i lavori, voglio poter caricare un CME",
        "bug nel maestro automation non funziona",
        "migliorare la UI di BeachRef",
        "implementare upload file per GridConnect"
    ]
    
    for msg in test_messages:
        result = parse_message(msg)
        if result:
            print(f"INPUT: {msg}")
            print(f"OUTPUT: {result}")
            print("-" * 50)