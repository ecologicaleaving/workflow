# 🔔 Automatic Deploy Notifications Setup

Questo documento spiega come configurare le notifiche automatiche di deploy per qualsiasi repository.

## ✅ Come funziona

1. **Deploy inicia** → Workflow manda notifica "🔄 In progress..."
2. **Deploy completo (success)** → Notifica "✅ Success! Live 🎉"
3. **Deploy fallisce** → Notifica "❌ Failed"

Tutto centralizzato, niente token nei singoli repo.

## 🔧 Setup per una nuova repo

### Step 1: Aggiungi i secrets al repo
```bash
gh secret set TELEGRAM_BOT_TOKEN --body "8563130383:AAHsxqttIKcCAPVTkCj5Cw-V79BHG-jS1Xg" -R ecologicaleaving/nome-repo
gh secret set TELEGRAM_CHAT_ID --body "1634377998" -R ecologicaleaving/nome-repo
```

### Step 2: Aggiungi il workflow dispatch
Nel tuo `.github/workflows/deploy.yml` (o equivalente), aggiungi alla fine:

```yaml
  notify-dispatch:
    name: Notify Deploy Start
    runs-on: ubuntu-latest
    if: always()
    needs: [build-and-deploy]  # ← dipende dal job di deploy
    steps:
      - name: Checkout workflow repo
        uses: actions/checkout@v4
        with:
          repository: ecologicaleaving/workflow

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install requests

      - name: Send notification
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
        run: |
          STATUS="${{ needs.build-and-deploy.result }}"
          [ "$STATUS" = "success" ] && STATUS="success" || STATUS="failed"
          
          python workflow/scripts/deploy-notify.py \
            "${{ github.repository }}" \
            "deploy" \
            "$STATUS" \
            "${{ github.ref_name }}" \
            "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```

### Step 3: Test
Fai un push → il deploy triggererà la notifica Telegram 🎉

## 📋 Repository supportati

- ✅ **Web apps** (Next.js, React) — notifica deploy
- ✅ **Mobile apps** (Flutter) — notifica build APK
- ✅ **Backend** (Node, Python) — notifica release
- ✅ **Infrastructure** (Terraform, Docker) — notifica su demanda

## 🔐 Secrets (centralizzati)

| Secret | Valore | Scope |
|--------|--------|-------|
| `TELEGRAM_BOT_TOKEN` | Bot token | Tutti i repo |
| `TELEGRAM_CHAT_ID` | Chat ID destinazione | Tutti i repo |

## 📝 Customizzazione

Nel tuo workflow, puoi modificare il tipo di notifica:

```bash
# Deploy completion
python workflow/scripts/deploy-notify.py REPO deploy success BRANCH LINK

# Build APK
python workflow/scripts/deploy-notify.py REPO build success BRANCH LINK

# Release
python workflow/scripts/deploy-notify.py REPO release success BRANCH LINK

# Con dettagli
python workflow/scripts/deploy-notify.py REPO deploy success BRANCH LINK "Extra info"
```

## 🎯 Prossimi step

- Aggiungi a tutti i repo di produzione
- Configura filtri per silenziare notifiche non critiche
- Estendi con notifiche per PR reviews, security alerts, ecc.

---
_Sistema centralizzato di notifiche per 8020 Solutions_ 🚀
