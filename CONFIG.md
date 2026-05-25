# CONFIG — Dream Vault Setup Guide

## Prerequisites

| Tool | Install | Verify |
|------|---------|--------|
| **Bun** ≥1.3 | `curl -fsSL https://bun.sh/install \| bash` | `bun --version` |
| **Git** ≥2.40 | System package manager | `git --version` |
| **Obsidian** | [obsidian.md/download](https://obsidian.md/download) | App launches |
| **Wrangler** (R2) | `npm install -g wrangler` | `wrangler --version` |

## Quick Start

```bash
# 1. Clone the repo
git clone <REPO_URL> dream-valut && cd dream-valut

# 2. Install dependencies
bun install

# 3. Create vault structure + install plugins
./scripts/dream-vault.sh install

# 4. Open vault in Obsidian
# File > Open Vault → select ./vault/ directory
```

## Cloudflare R2 Setup

### 1. Create R2 Bucket

```bash
npx wrangler login
npx wrangler r2 bucket create dream-vault
```

### 2. Generate API Credentials

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) > **R2** > **Manage R2 API Tokens**
2. Create token with **Object Read & Write** permission, scoped to `dream-vault` bucket
3. Save the credentials:
   - `Access Key ID`
   - `Secret Access Key`
   - `S3 Endpoint` (format: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`)

### 3. Configure GitHub Secrets

In your GitHub repo → Settings → Secrets and variables → Actions:

| Secret Name | Value |
|-------------|-------|
| `CLOUDFLARE_R2_ACCOUNT_ID` | Your Cloudflare account ID |
| `CLOUDFLARE_R2_ACCESS_KEY_ID` | R2 API Access Key ID |
| `CLOUDFLARE_R2_SECRET_ACCESS_KEY` | R2 API Secret Access Key |
| `CLOUDFLARE_R2_BUCKET_NAME` | `dream-vault` |

### 4. Test the Pipeline

```bash
# Make a change, commit, push
echo "test" >> vault/00-meta/index.md
git add . && git commit -m "test: verify R2 sync" && git push
# Check GitHub Actions tab for vault-r2-sync workflow result
```

## Development Commands

```bash
# Lint + format check
bun run check

# Type checking
bun run typecheck

# Format fix
bun run format

# Database migrations
bun run db:generate
bun run db:migrate
```

## Optional: Multi-Device Sync via Rclone

For secondary machines without Git:

```bash
brew install rclone
rclone config  # Add R2 as s3/Cloudflare remote
rclone sync ./vault r2:dream-vault/vault
```

⚠️ This bypasses GitHub. Run `git pull` afterward to sync Git history.

## Optional: Obsidian CLI

```bash
# macOS
sudo ln -s "/Applications/Obsidian.app/Contents/Resources/app/obsidian.sh" /usr/local/bin/obsidian

# Verify
obsidian help
```
