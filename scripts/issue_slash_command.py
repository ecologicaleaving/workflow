#!/usr/bin/env python3
"""
SLASH COMMAND /issue for Issues Tracker Group
Usage: /issue - "description text"
Auto-creates GitHub issues with guided workflow
"""
import re
import subprocess
import json
import sys
import os
from typing import Dict, Optional

# Project board helper
sys.path.insert(0, os.path.dirname(__file__))
try:
    from project_board import move_card
    _board_available = True
except ImportError:
    _board_available = False
    def move_card(repo, number, column): return False

class IssueSlashCommand:
    def __init__(self):
        self.repos = {
            'progetto-casa': ['casa', 'lavori', 'cantiere', 'cme', 'relazione', 'edificio'],
            'StageConnect': ['stage', 'debug', 'browser', 'device', 'connect'],
            'BeachRef-app': ['beach', 'spiaggia', 'flutter', 'app mobile', 'beachref', 'arbitri', 'torneo'],
            'BeachRef': ['beach backend', 'api beach', 'server beach'],
            'maestro': ['maestro', 'automation', 'commands', 'control'],
            'finn': ['finn', 'finance', 'tracking', 'financial'],
            'sun-stop-timer': ['drum', 'audio', 'reaper', 'music', 'timer', 'sun'],
            'GridConnect': ['grid', 'elettrico', 'enel', 'pratiche', 'energia', 'connessioni'],
            'workflow': ['workflow', 'processo', 'automation', 'team', 'standard']
        }
        
        self.issue_types = {
            'feature': ['voglio', 'poter', 'servire', 'implementare', 'aggiungere', 'creare', 'nuovo', 'feature'],
            'bug': ['bug', 'errore', 'problema', 'non funziona', 'crash', 'error'],
            'improvement': ['migliorare', 'ottimizzare', 'rendere più', 'enhancement', 'upgrade'],
            'question': ['come', 'perché', 'cosa', 'quando', 'dove', 'domanda', 'help']
        }
    
    def parse_slash_command(self, message: str) -> Optional[Dict]:
        """Parse /issue command format"""
        # Match: /issue - "text" or /issue "text" or /issue text
        patterns = [
            r'/issue\s*[-:]\s*["\'](.+)["\']',  # /issue - "text" or /issue : "text"
            r'/issue\s*[-:]\s*(.+)',            # /issue - text or /issue : text
            r'/issue\s*["\'](.+)["\']',         # /issue "text"
            r'/issue\s+(.+)'                    # /issue text
        ]
        
        for pattern in patterns:
            match = re.match(pattern, message.strip(), re.IGNORECASE | re.DOTALL)
            if match:
                description = match.group(1).strip()
                return self.analyze_issue_request(description)
        
        return None
    
    def detect_repo(self, text: str) -> str:
        """Detect repository from issue description"""
        text_lower = text.lower()
        
        # Score each repo based on keyword matches
        scores = {}
        for repo, keywords in self.repos.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                scores[repo] = score
        
        if scores:
            best_repo = max(scores, key=scores.get)
            return f"ecologicaleaving/{best_repo}"
        
        # Fallback to most common
        return "ecologicaleaving/progetto-casa"
    
    def detect_type(self, text: str) -> str:
        """Detect issue type from description"""
        text_lower = text.lower()
        
        scores = {}
        for issue_type, keywords in self.issue_types.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                scores[issue_type] = score
        
        if scores:
            return max(scores, key=scores.get)
        
        return 'feature'  # Default
    
    def analyze_issue_request(self, description: str) -> Dict:
        """Analyze issue request and extract metadata"""
        repo = self.detect_repo(description)
        issue_type = self.detect_type(description)
        
        # Generate title based on type
        if issue_type == 'feature':
            title = f"Feature: {description[:50]}..."
        elif issue_type == 'bug':
            title = f"Bug: {description[:50]}..."
        elif issue_type == 'improvement':
            title = f"Improvement: {description[:50]}..."
        else:
            title = f"Question: {description[:50]}..."
        
        # Clean title
        title = title.replace('...', '').strip()
        if len(title) > 60:
            title = title[:57] + "..."
        
        # Map to standard GitHub labels
        label_mapping = {
            'feature': 'enhancement',
            'bug': 'bug',
            'improvement': 'enhancement', 
            'question': 'question'
        }
        
        labels = [label_mapping.get(issue_type, 'enhancement')]
        
        return {
            'title': title,
            'description': description,
            'repo': repo,
            'type': issue_type,
            'labels': labels,
            'original_command': f"/issue - \"{description}\""
        }
    
    def ensure_claude_code_label(self, repo: str) -> bool:
        """Ensure claude-code label exists in repository"""
        try:
            # Check if label already exists
            result = subprocess.run([
                'gh', 'label', 'list', '--repo', repo, '--search', 'claude-code'
            ], capture_output=True, text=True)
            
            if 'claude-code' not in result.stdout:
                # Create the label
                subprocess.run([
                    'gh', 'label', 'create', 'claude-code',
                    '--repo', repo,
                    '--color', '0e7490',
                    '--description', 'Auto-assignment to Claude Code agent (PC development system)'
                ], capture_output=True)
            return True
        except:
            return False
    
    def analyze_repository_context(self, repo: str) -> Dict:
        """Analyze repository PROJECT.md to understand project context"""
        try:
            # Get PROJECT.md from repository
            result = subprocess.run([
                'gh', 'api', f'repos/{repo}/contents/PROJECT.md'
            ], capture_output=True, text=True)
            
            context = {
                'name': repo.split('/')[-1],
                'description': '',
                'tech_stack': '',
                'platforms': '',
                'status': 'unknown',
                'existing_features': [],
                'constraints': [],
                'user_flows': []
            }
            
            if result.returncode == 0:
                import base64
                content = json.loads(result.stdout)
                project_content = base64.b64decode(content['content']).decode('utf-8')
                
                # Parse PROJECT.md content
                lines = project_content.split('\n')
                current_section = None
                
                for line in lines:
                    line = line.strip()
                    
                    # Extract key project info
                    if '**Name**:' in line:
                        context['name'] = line.split(':')[-1].strip()
                    elif '**Description**:' in line:
                        context['description'] = line.split(':', 1)[-1].strip()
                    elif '**Platforms**:' in line:
                        context['platforms'] = line.split(':', 1)[-1].strip()
                    elif '**Status**:' in line:
                        context['status'] = line.split(':', 1)[-1].strip()
                    
                    # Extract sections
                    elif line.startswith('## Tech Stack'):
                        current_section = 'tech_stack'
                    elif line.startswith('## Services'):
                        current_section = 'existing_features'
                    elif line.startswith('## Backlog'):
                        current_section = 'backlog'
                    elif line.startswith('#'):
                        current_section = None
                    
                    # Collect tech stack info
                    elif current_section == 'tech_stack' and line.startswith('-'):
                        context['tech_stack'] += line.replace('-', '').replace('*', '').strip() + '; '
                    
                    # Collect existing features (DONE items in backlog)
                    elif current_section == 'backlog' and '**DONE**:' in line:
                        feature = line.split(':', 1)[-1].strip()
                        context['existing_features'].append(feature)
                
                # Clean up tech stack
                context['tech_stack'] = context['tech_stack'].rstrip('; ')
                
            return context
        except Exception as e:
            # Fallback for repos without PROJECT.md
            return {
                'name': repo.split('/')[-1], 
                'description': 'Progetto da analizzare',
                'tech_stack': 'Da determinare',
                'platforms': 'Da determinare', 
                'status': 'unknown',
                'existing_features': [],
                'constraints': [],
                'user_flows': []
            }
    
    def create_structured_issue_body(self, issue_data: Dict) -> str:
        """Create structured issue body based on PROJECT.md context"""
        repo_context = self.analyze_repository_context(issue_data['repo'])
        
        # Check if description is too vague and needs clarification
        vague_indicators = ['voglio', 'serve', 'bisogna', 'dovrebbe', 'sarebbe bello']
        is_vague = any(indicator in issue_data['description'].lower() for indicator in vague_indicators)
        
        if is_vague and len(issue_data['description'].split()) < 10:
            # Description too vague - suggest clarifications based on project context
            return f"""## ⚠️ **Issue richiede chiarimenti**

**Descrizione originale:**
{issue_data['description']}

### 📊 **Contesto Progetto ({repo_context['name']})**
- **Descrizione**: {repo_context['description']}
- **Tech Stack**: {repo_context['tech_stack']}
- **Platforms**: {repo_context['platforms']}
- **Status**: {repo_context['status']}

### 🎯 **Features esistenti da considerare:**
{chr(10).join([f"- {feature}" for feature in repo_context['existing_features'][:5]]) if repo_context['existing_features'] else "- Analizza il progetto per features esistenti"}

### ❓ **Domande specifiche per {repo_context['name']}:**

1. **User Story**: Chi userà questa feature nel contesto {repo_context['name']}?
2. **Integrazione**: Come si collega alle features esistenti sopra?
3. **Input/Output**: Che dati servono? Che risultato concreto?
4. **Platform**: Su quale platform? ({repo_context['platforms']})
5. **UI/UX**: Modifica interfaccia esistente o nuova sezione?

### 📝 **Per procedere:**
Rispondi alle domande e riformula con più dettagli.

**Esempio contestualizzato:**
`/issue - "Per {repo_context['name']}, l'utente [TIPO_USER] deve poter [AZIONE_SPECIFICA] per [BENEFICIO]. Integrazione con [FEATURE_ESISTENTE], output [FORMATO_DATI], UI [DOVE_NELLA_APP]"`

---
**Original command:** `{issue_data['original_command']}`
"""
        
        # Create structured issue for clear descriptions
        existing_features_text = ""
        if repo_context['existing_features']:
            existing_features_text = f"""
### 🎯 **Features esistenti da NON rompere:**
{chr(10).join([f"- {feature}" for feature in repo_context['existing_features'][:8]])}
"""

        return f"""## 📋 **{issue_data['type'].title()}: {issue_data['title'].replace(f"{issue_data['type'].title()}: ", "")}**

### 🎯 **User Story**
Come **utente di {repo_context['name']}**, voglio {issue_data['description'].lower()}, così da [BENEFICIO DA DEFINIRE MEGLIO].

### 📊 **Contesto Progetto**
- **Nome**: {repo_context['name']}
- **Descrizione**: {repo_context['description']}
- **Tech Stack**: {repo_context['tech_stack']}
- **Platforms**: {repo_context['platforms']}
- **Status**: {repo_context['status']}{existing_features_text}

### ✅ **Criteri di Accettazione**

#### **🔄 Integrazione con sistema esistente:**
- [ ] Si integra perfettamente con l'architettura {repo_context['name']} esistente
- [ ] Utilizza il tech stack corrente: {repo_context['tech_stack']}
- [ ] Supporta le platforms target: {repo_context['platforms']}
- [ ] ZERO breaking changes delle features esistenti sopra

#### **🎯 Funzionalità core:**
- [ ] [CRITERIO 1: Input handling - formato e validazione]
- [ ] [CRITERIO 2: Core processing - logica principale]  
- [ ] [CRITERIO 3: Output delivery - formato risultato]
- [ ] [CRITERIO 4: Error handling - gestione casi limite]

#### **🎨 User Experience:**
- [ ] Interfaccia coerente con il design system esistente
- [ ] Feedback utente appropriato (loading, success, error)
- [ ] Accessibile da navigation corrente
- [ ] Performance adeguata per platform target

### 🎯 **Risultati Attesi**

#### **Input di test:**
[DA SPECIFICARE: Scenario/dati specifici per {repo_context['name']}]

#### **Output atteso:**
[DA SPECIFICARE: Risultato misurabile che l'utente vede/ottiene]

#### **Metriche successo:**
- **Funzionale**: Feature fa quello che serve senza errori
- **Performance**: Tempi di risposta accettabili per l'uso reale  
- **Integrazione**: Non rompe workflow esistenti
- **User Experience**: Facile da usare e coerente con il resto

### 💡 **Vincoli e Note**
- **Repository**: {issue_data['repo']}
- **Project Status**: {repo_context['status']} (considera limitazioni dev environment)
- **Architecture**: Rispetta patterns e convenzioni esistenti
- **NO soluzioni tecniche specifiche** - Claude Code analizzerà il codice

### 🏁 **Definition of Done**
- [ ] Feature implementata secondo criteri di accettazione
- [ ] Testing completato (manuale + automatico se disponibile)
- [ ] Nessuna regressione delle features esistenti
- [ ] Code review approvato  
- [ ] Build successful su tutte le platforms target
- [ ] Documentation aggiornata se necessario

### 📝 **Prossimi passi**
1. **👀 Review issue**: Valida criteri e affina se necessario
2. **🤖 Auto-processing**: Label `claude-code` + assignee già impostati — il monitor PC la prenderà entro 5 minuti
3. **🚀 Deploy**: Ciccio gestisce deployment dopo review-ready

---
**Auto-creata:** Issues Tracker Bot via slash command  
**Original command:** `{issue_data['original_command']}`
"""
    
    def create_github_issue(self, issue_data: Dict) -> Optional[str]:
        """Create GitHub issue using gh CLI"""
        try:
            # Ensure claude-code label exists (for manual use)
            self.ensure_claude_code_label(issue_data['repo'])
            
            body = self.create_structured_issue_body(issue_data)
            
            # Always include claude-code label + assign to Claude Code agent
            all_labels = list(set(issue_data['labels'] + ['claude-code']))

            cmd = [
                'gh', 'issue', 'create',
                '--repo', issue_data['repo'],
                '--title', issue_data['title'],
                '--body', body,
                '--label', ','.join(all_labels),
                '--assignee', 'ecologicaleaving'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                issue_url = result.stdout.strip()
                
                # Aggiungi al project e sposta su Todo
                try:
                    project_cmd = [
                        'gh', 'project', 'item-add', '2',
                        '--owner', 'ecologicaleaving',
                        '--url', issue_url
                    ]
                    subprocess.run(project_cmd, capture_output=True)
                    # Estrai numero issue dall'URL e sposta su Todo
                    issue_num = int(issue_url.rstrip('/').split('/')[-1])
                    repo_name = issue_url.split('github.com/')[-1].rsplit('/', 2)[0]
                    move_card(repo_name, issue_num, "Todo")
                except:
                    pass  # Non-critical
                
                return issue_url
            else:
                return None
                
        except Exception as e:
            print(f"Error creating issue: {e}")
            return None

def handle_issue_command(message: str, author: str = "davide crescentini") -> Optional[str]:
    """Main handler for /issue slash command"""
    if author.lower() != "davide crescentini":
        return "❌ Solo Davide può creare issue tramite questo comando."
    
    if not message.strip().lower().startswith('/issue'):
        return None
    
    parser = IssueSlashCommand()
    issue_data = parser.parse_slash_command(message)
    
    if not issue_data:
        return """❌ **Formato comando non valido**

**Uso corretto:**
• `/issue - "descrizione issue"`
• `/issue "descrizione issue"`  
• `/issue descrizione issue`

**Esempi:**
• `/issue - "in progetto-casa voglio upload documenti CME"`
• `/issue "bug maestro automation non funziona"`
• `/issue migliorare UI BeachRef più responsiva`"""
    
    # Create GitHub issue
    issue_url = parser.create_github_issue(issue_data)
    
    if issue_url:
        # Check if issue was created with clarification request
        vague_indicators = ['voglio', 'serve', 'bisogna', 'dovrebbe', 'sarebbe bello']
        is_vague = any(indicator in issue_data['description'].lower() for indicator in vague_indicators)
        needs_clarification = is_vague and len(issue_data['description'].split()) < 10
        
        if needs_clarification:
            return f"""⚠️ **Issue creata - Richiede chiarimenti**

🔗 **URL:** {issue_url}
📋 **Titolo:** {issue_data['title']}
📁 **Repository:** {issue_data['repo']}

📝 **AZIONE RICHIESTA:**
L'issue ha bisogno di maggiori dettagli per essere processabile.
Consulta la issue per le domande specifiche e riformula con più dettagli.

**Aggiunta al Project "80/20 Solutions - Development Hub"** 📋"""
        else:
            return f"""✅ **Issue strutturata creata!**

🔗 **URL:** {issue_url}
📋 **Titolo:** {issue_data['title']}
📁 **Repository:** {issue_data['repo']}
🏷️ **Tipo:** {issue_data['type']}
📌 **Labels:** {', '.join(issue_data['labels'] + ['claude-code'])}
👤 **Assigned to:** ecologicaleaving

📋 **ISSUE STRUTTURATA:**
• Criteri di accettazione definiti
• User story formulata
• Note tecniche integrate  
• Definition of done inclusa

🤖 **PROCESSING AUTOMATICO ATTIVATO:**
• Label `claude-code` + assignee già impostati automaticamente
• Monitor PC rileverà l'issue entro 5 minuti
• Claude Code inizierà development automaticamente
• Progress updates saranno postati sulla issue GitHub

**Aggiunta al Project "80/20 Solutions - Development Hub"** ✅"""
    else:
        return f"""❌ **Errore nella creazione issue**

**Dati estratti:**
• **Repo:** {issue_data['repo']}  
• **Tipo:** {issue_data['type']}
• **Titolo:** {issue_data['title']}

Verifica configurazione `gh CLI` e permessi repository."""

def handle_reject_command(message: str, author: str = "davide crescentini") -> Optional[str]:
    """
    Handler per /reject — riporta una issue in lavorazione con feedback.

    Sintassi supportata:
      /reject #123 "schermata bianca su mobile, bottone salva non funziona"
      /reject 123 "feedback"
      /reject #123 - "feedback"
    """
    if author.lower() != "davide crescentini":
        return "❌ Solo Davide può usare /reject."

    if not message.strip().lower().startswith('/reject'):
        return None

    # Parse numero issue e feedback
    patterns = [
        r'/reject\s+#?(\d+)\s*[-:]\s*["\'](.+)["\']',
        r'/reject\s+#?(\d+)\s+["\'](.+)["\']',
        r'/reject\s+#?(\d+)\s*[-:]\s*(.+)',
        r'/reject\s+#?(\d+)\s+(.+)',
    ]

    number = None
    feedback = None
    for pattern in patterns:
        match = re.match(pattern, message.strip(), re.IGNORECASE | re.DOTALL)
        if match:
            number  = int(match.group(1))
            feedback = match.group(2).strip()
            break

    if not number or not feedback:
        return """❌ **Formato /reject non valido**

**Uso corretto:**
• `/reject #123 "schermata bianca su mobile"`
• `/reject 123 - "bottone salva non funziona, errore 401 in console"`

**Cosa succede:**
1. Aggiungo un commento sulla issue con il tuo feedback
2. Cambio label: review-ready/deployed-test → `needs-fix`
3. Il monitor VPS la rileva entro 10 minuti e spawna un subagente"""

    # Cerca la issue nei repo ecologicaleaving
    try:
        result = subprocess.run([
            'gh', 'issue', 'view', str(number),
            '--json', 'title,url,labels,repository'
        ], capture_output=True, text=True)

        if result.returncode != 0:
            # Prova a cercarlo nei repo principali
            found = None
            for repo_short in ['StageConnect', 'BeachRef-app', 'maestro', 'finn',
                                'GridConnect', 'workflow', 'progetto-casa']:
                r = subprocess.run([
                    'gh', 'issue', 'view', str(number),
                    '--repo', f'ecologicaleaving/{repo_short}',
                    '--json', 'title,url,labels,repository'
                ], capture_output=True, text=True)
                if r.returncode == 0:
                    found = r
                    break
            if not found:
                return f"❌ Issue #{number} non trovata. Specifica il repo: `/reject ecologicaleaving/repo#{number} \"feedback\"`"
            result = found

        issue_info = json.loads(result.stdout)
        title    = issue_info.get('title', '?')
        url      = issue_info.get('url', '')
        repo     = issue_info.get('repository', {}).get('nameWithOwner', '')
        labels   = [l['name'] for l in issue_info.get('labels', [])]

    except Exception as e:
        return f"❌ Errore recupero issue #{number}: {e}"

    # Costruisci il commento di feedback
    from datetime import datetime, timezone
    ts = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')

    comment_body = f"""## ❌ Review Fallita — Rework Richiesto

**Data review:** {ts}
**Reviewer:** @{author.split()[0].lower()}

### 🐛 Problemi riscontrati

{feedback}

### 📋 Azioni richieste
- [ ] Analizza i problemi segnalati
- [ ] Riproduci il bug/problema localmente
- [ ] Implementa il fix
- [ ] Verifica con Playwright E2E (se web app)
- [ ] Re-commit e re-push su `feature/issue-{number}`

---
*Generato automaticamente da /reject slash command*"""

    # 1. Aggiungi commento sulla issue
    try:
        subprocess.run([
            'gh', 'issue', 'comment', str(number),
            '--repo', repo,
            '--body', comment_body
        ], capture_output=True, check=True)
    except Exception as e:
        return f"❌ Errore aggiunta commento su issue #{number}: {e}"

    # 2. Aggiorna labels: rimuovi review-ready/deployed-test, aggiungi needs-fix
    remove_labels = [l for l in labels if l in ('review-ready', 'deployed-test', 'in-progress')]
    try:
        cmd = ['gh', 'issue', 'edit', str(number), '--repo', repo, '--add-label', 'needs-fix']
        for lbl in remove_labels:
            cmd += ['--remove-label', lbl]
        subprocess.run(cmd, capture_output=True, check=True)
    except Exception as e:
        return f"❌ Errore aggiornamento label issue #{number}: {e}"

    # 3. Sposta card su "In Progress" nel Project board
    move_card(repo, number, "In Progress")

    removed_str = ', '.join(remove_labels) if remove_labels else 'nessuna'

    return f"""🔧 **Issue #{number} rimandata in lavorazione**

🔗 **URL:** {url}
📋 **Titolo:** {title}
📁 **Repository:** {repo}

**Azioni eseguite:**
• 💬 Commento feedback aggiunto alla issue
• 🏷️ Rimossa: `{removed_str}`
• 🏷️ Aggiunta: `needs-fix`

⏱️ **Il monitor VPS rileverà la issue entro 10 minuti** e spawnerà un subagente con il tuo feedback come contesto.

**Feedback registrato:**
_{feedback}_"""


if __name__ == "__main__":
    # Test cases
    test_commands = [
        '/issue - "in progetto-casa per i lavori, voglio poter caricare un CME"',
        '/issue "bug nel maestro automation non funziona"',
        '/issue migliorare la UI di BeachRef',
        '/issue - "come implementare upload file per GridConnect?"'
    ]
    
    for cmd in test_commands:
        print(f"\n📝 COMMAND: {cmd}")
        result = handle_issue_command(cmd)
        if result:
            print(f"✅ RESULT:\n{result}")
        print("-" * 70)

    # Test /reject
    print("\n\n=== TEST /reject ===")
    reject_commands = [
        '/reject #42 "schermata bianca su mobile, bottone salva non funziona"',
        '/reject 7 - "errore 401 in console quando apro la dashboard"',
        '/reject',  # formato sbagliato
    ]
    for cmd in reject_commands:
        print(f"\n📝 COMMAND: {cmd}")
        result = handle_reject_command(cmd)
        if result:
            print(f"✅ RESULT:\n{result}")
        print("-" * 70)