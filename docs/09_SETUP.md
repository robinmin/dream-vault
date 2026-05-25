# Dream Vault — Setup Guide

End-to-end initialization from a fresh clone to a fully operational vault with CI/CD backup.

## Prerequisites

| Tool | Install | Purpose |
|------|---------|---------|
| **Bun** | `curl -fsSL https://bun.sh/install \| bash` | Runtime + package manager |
| **Git** | System default | Version control |
| **Obsidian** | [obsidian.md](https://obsidian.md) | Vault editor |
| **Wrangler** | `npm install -g wrangler` | Cloudflare R2 management |
| **GitHub CLI** | `brew install gh` | Secret management, repo ops |
| **rclone** (optional) | `brew install rclone` | Manual R2 sync |

Verify all tools:

```bash
bun --version && git --version && wrangler --version && gh --version
```

Or run the built-in check:

```bash
./scripts/dream-vault.sh install install-basic
```

---

## 1. Clone & Install Dependencies

```bash
git clone https://github.com/<you>/dream-vault.git
cd dream-vault
bun install
```

---

## 2. Initialize Vault Structure

Creates the folder hierarchy and default templates:

```bash
./scripts/dream-vault.sh install setup_structure
```

This creates:

```
vault/
├── .obsidian/
├── 00-meta/index.md
├── 01-projects/.gitkeep
├── 02-notes/.gitkeep
├── 03-areas/.gitkeep
├── 04-resources/.gitkeep
├── 05-public/.gitkeep
├── 98_attachments/_generated/
└── 99_templates/
```

---

## 3. Create Cloudflare R2 Bucket

### 3.1 Authenticate Wrangler

```bash
wrangler login
```

Opens a browser for Cloudflare OAuth. Grant access.

### 3.2 Create the Bucket

```bash
wrangler r2 bucket create dream-vault
```

Verify:

```bash
wrangler r2 bucket list
```

### 3.3 Create API Token

1. Open **Cloudflare Dashboard → R2 → Manage R2 API Tokens**
2. Click **Create API Token**
3. Permissions: **Object Read & Write**
4. Scope: **Apply to bucket → dream-vault**
5. Save the output — you need:
   - **Access Key ID**
   - **Secret Access Key**

Also note your **Account ID** from the R2 Overview page (`https://dash.cloudflare.com/<ACCOUNT_ID>/r2`).

---

## 4. Configure GitHub Actions Secrets

### 4.1 Create `.env` from Template

```bash
cp .env.example .env
```

Fill in the values:

```bash
CLOUDFLARE_R2_ACCOUNT_ID=your_account_id_here
CLOUDFLARE_R2_BUCKET_NAME=dream-vault
CLOUDFLARE_R2_ACCESS_KEY_ID=your_access_key_id_here
CLOUDFLARE_R2_SECRET_ACCESS_KEY=your_secret_access_key_here
```

### 4.2 Set Secrets via Script

```bash
./scripts/dream-vault.sh install setup_secrets
```

This reads `.env` and runs `gh secret set` for each variable.

### 4.3 Manual Alternative

```bash
gh secret set CLOUDFLARE_R2_ACCOUNT_ID --body "your_account_id"
gh secret set CLOUDFLARE_R2_BUCKET_NAME --body "dream-vault"
gh secret set CLOUDFLARE_R2_ACCESS_KEY_ID --body "your_access_key_id"
gh secret set CLOUDFLARE_R2_SECRET_ACCESS_KEY --body "your_secret_access_key"
```

### 4.4 Verify

```bash
gh secret list
```

Expected output:

```
CLOUDFLARE_R2_ACCOUNT_ID         Updated 2026-01-01
CLOUDFLARE_R2_ACCESS_KEY_ID      Updated 2026-01-01
CLOUDFLARE_R2_BUCKET_NAME        Updated 2026-01-01
CLOUDFLARE_R2_SECRET_ACCESS_KEY  Updated 2026-01-01
```

> **Security:** `.env` is in `.gitignore`. Never commit credentials.

---

## 5. Initialize the Database

Creates `vault/.dream-vault/metadata.db` (SQLite) for structured metadata:

```bash
bun src/cli/bin.ts db:init
```

---

## 6. Install Obsidian Plugins (Optional)

Downloads community plugins from GitHub releases:

```bash
./scripts/dream-vault.sh install install-plugins
```

Registered plugins: Templater, QuickAdd, Tasks, Advanced URI, Metatable, Local REST API, Remotely Save.

---

## 7. Install Claude Code Skills (Optional)

If using Claude Code or Pi as an AI assistant:

```bash
./scripts/dream-vault.sh install install-skills
```

Installs project-specific skills (vault-manager, seo-optimizer, content-writer, image-prompt) and community skills from `kepano/obsidian-skills`.

---

## 8. Run All Install Steps

Single command to run everything except secrets (needs `.env`):

```bash
./scripts/dream-vault.sh install
```

Then configure secrets separately:

```bash
./scripts/dream-vault.sh install setup_secrets
```

---

## 9. Verify Setup

### 9.1 Check Installed Resources

```bash
./scripts/dream-vault.sh list
```

Shows: Binaries, Obsidian Plugins, Claude Code Skills, Vault Structure, Git Status.

### 9.2 Run Health Check

```bash
bun src/cli/bin.ts health
```

All checks should pass (warnings for empty content dirs are expected for new vaults).

### 9.3 Test CI/CD Pipeline

Push to `main` and verify GitHub Actions runs:

```bash
git add -A && git commit -m "chore: initial setup"
git push origin main
```

Check: `gh run list --limit 1`

Two workflows trigger on `vault/**` changes:
- **Vault CI** — markdown lint + attachment validation + frontmatter check
- **Sync Vault to R2** — `aws s3 sync` to Cloudflare R2

---

## 10. Open in Obsidian

1. Launch Obsidian
2. **Open folder as vault** → select `vault/` directory
3. Enable community plugins in Settings → Community Plugins

---

## Quick Reference

| Task | Command |
|------|---------|
| Full install | `./scripts/dream-vault.sh install` |
| Set secrets | `./scripts/dream-vault.sh install setup_secrets` |
| Check resources | `./scripts/dream-vault.sh list` |
| Health check | `bun src/cli/bin.ts health` |
| Init database | `bun src/cli/bin.ts db:init` |
| Pre-publish checks | `./scripts/dream-vault.sh publish` |
| Lint + format | `bun run autofix` |
| Type check | `bun run typecheck` |
