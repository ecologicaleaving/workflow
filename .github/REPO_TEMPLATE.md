# 🚀 New Repository Setup — 80/20 Solutions

Checklist per configurare una nuova repo con notifiche deploy automatiche.

## 1️⃣ Repo Secrets (una volta per repo)

```bash
# Set secrets
export REPO="ecologicaleaving/your-repo-name"
export BOT_TOKEN="8563130383:AAHsxqttIKcCAPVTkCj5Cw-V79BHG-jS1Xg"
export CHAT_ID="1634377998"

gh secret set TELEGRAM_BOT_TOKEN --body "$BOT_TOKEN" -R "$REPO"
gh secret set TELEGRAM_CHAT_ID --body "$CHAT_ID" -R "$REPO"
```

## 2️⃣ Aggiungi il workflow dispatcher al tuo `.github/workflows/deploy.yml`

Alla fine del file, aggiungi:

```yaml
  notify-deploy:
    name: 🔔 Notify Deploy Status
    runs-on: ubuntu-latest
    if: always()
    needs: [build-and-deploy]  # ← adjust job name as needed
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

## 3️⃣ Fatto! 

Da adesso ogni deploy triggerizzerà la notifica Telegram automaticamente.

---

**Note:**
- `build-and-deploy` è il nome del job nel tuo workflow — verificalo e cambia se necessario
- La notifica parte sia all'inizio che al completamento del deploy
- Status: 🔄 in_progress → ✅ success o ❌ failed
