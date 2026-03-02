# Receipt Processor

Connects Claude Code to your Gmail and Google Sheets via the [Google Workspace MCP](https://github.com/mcp-community/workspace-mcp) server. Ask Claude to find receipt emails and build expense spreadsheets — no code required.

**How it works:** `start-mcp.sh` launches a local HTTP server that exposes Gmail, Sheets, and Drive tools. Claude Code connects to it over MCP and uses those tools on your behalf.

## Prerequisites

- `uvx` installed (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- A Google account with your receipts

---

## Setup (one-time, ~10 min)

### 1. Create a Google Cloud project

Go to [console.cloud.google.com](https://console.cloud.google.com/) → project dropdown → **New Project** → name it `receipt-processor` → **Create** → select it.

### 2. Enable APIs

Click each link (make sure your project is selected):

- [Gmail API](https://console.cloud.google.com/flows/enableapi?apiid=gmail.googleapis.com)
- [Google Sheets API](https://console.cloud.google.com/flows/enableapi?apiid=sheets.googleapis.com)
- [Google Drive API](https://console.cloud.google.com/flows/enableapi?apiid=drive.googleapis.com)

### 3. Configure OAuth consent screen

Go to [APIs & Services → OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent).

1. Choose **External** → **Create**
2. Fill in app name and your email
3. **Scopes** → **Add or Remove Scopes** → add exactly these three:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/spreadsheets`
   - `https://www.googleapis.com/auth/drive.readonly`
4. **Test Users** → add your Gmail address
5. Save

### 4. Create OAuth credentials

Go to [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials).

1. **Create Credentials** → **OAuth Client ID**
2. Application type: **Desktop Application**
3. Name: `receipt-processor-desktop`
4. **Create** → copy the **Client ID** and **Client Secret**

### 5. Configure credentials

```bash
mkdir -p ~/.receipt-processor
cp .env.example ~/.receipt-processor/.env
chmod 600 ~/.receipt-processor/.env
```

Edit `~/.receipt-processor/.env` and fill in your Client ID, Client Secret, and Gmail address:

```
GOOGLE_OAUTH_CLIENT_ID="your-client-id.apps.googleusercontent.com"
GOOGLE_OAUTH_CLIENT_SECRET="your-client-secret"
USER_GOOGLE_EMAIL="you@gmail.com"
OAUTHLIB_INSECURE_TRANSPORT=1
```

### 6. Register the MCP server with Claude Code

Start the local MCP server:

```bash
./start-mcp.sh
```

In a separate terminal, register it:

```bash
claude mcp add --transport http workspace-mcp http://localhost:8000/mcp
```

Verify it was added:

```bash
claude mcp list
# Should show: workspace-mcp
```

You only need to do steps 5–6 once. The MCP registration persists across Claude Code sessions.

### 7. Authorize Google (first use only)

The first time you use the server, it prints a Google authorization URL in the terminal where `start-mcp.sh` is running. Open it in your browser, sign in, authorize the app, and paste the code back. Tokens are cached at `~/.google_workspace_mcp/credentials/` so you won't be prompted again.

---

## Daily usage

Every time you want to use receipt processing:

```bash
# Terminal 1 — keep this running
./start-mcp.sh

# Terminal 2 — start Claude Code
claude
```

Claude can read your email from `~/.receipt-processor/.env` automatically. Just tell it to at the start of a session:

> "Read my email from ~/.receipt-processor/.env, then search my Gmail for receipt emails from the last 60 days and create an expense spreadsheet"

Or set it up once in your `CLAUDE.md` so Claude always knows:

```
My Google email for workspace-mcp tools is in ~/.receipt-processor/.env
```

For local receipt images (no MCP needed — Claude reads images natively):

> "Read the receipts in ~/receipts/ and extract merchant, date, and amount from each"

---

## Troubleshooting

**"Access blocked: This app's request is invalid"**
→ Add your Gmail as a test user in the OAuth consent screen (step 3 above).

**"insufficient authentication scopes"**
→ Delete cached tokens and re-authenticate:
```bash
rm -rf ~/.google_workspace_mcp/credentials/
```

**"MCP server not found" in Claude Code**
→ Make sure `./start-mcp.sh` is running in a separate terminal, then run `/mcp` in Claude Code to reconnect.

**Server won't start / `uvx` not found**
→ Restart your terminal after installing uv, or run `source ~/.zshrc`.
