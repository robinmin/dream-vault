# ARCH — Dream Vault Technical Architecture

## 1. System Overview

Dream Vault is a single-user Obsidian vault with three integration layers:

1. **Local layer** — Obsidian client + CLI for vault editing and management
2. **Hub layer** — GitHub repository (single source of truth, version control)
3. **Backup layer** — Cloudflare R2 (S3-compatible object storage, cloud backup)

No direct local→R2 sync dependency exists. All changes flow through GitHub.

```
┌─────────────────────────────────┐
│  LOCAL                          │
│  ┌──────────┐  ┌─────────────┐ │
│  │ Obsidian  │  │ Obsidian CLI│ │
│  │ Client    │  │ (terminal)  │ │
│  └────┬──────┘  └──────┬──────┘ │
│       │                │        │
│       └───────┬────────┘        │
│               ▼                 │
│         vault/ (git repo)       │
└───────────────┬─────────────────┘
                │ git push
                ▼
┌───────────────────────────────────┐
│  GITHUB (single source of truth)  │
│  ┌─────────────────────────────┐  │
│  │ main branch                 │  │
│  │ vault/** paths              │  │
│  └──────────┬──────────────────┘  │
│             │ GitHub Actions       │
│             ▼                      │
│  ┌─────────────────────────────┐  │
│  │ vault-r2-sync.yml           │  │
│  │ vault-ci.yml                │  │
│  └──────────┬──────────────────┘  │
└─────────────┼─────────────────────┘
              │ aws s3 sync
              ▼
┌───────────────────────────────────┐
│  CLOUDFLARE R2 (cloud backup)     │
│  Bucket: s3://<BUCKET>/vault      │
└───────────────────────────────────┘
```

---

## 2. Component Responsibilities

### 2.1 Obsidian Client

- Primary editing interface for vault Markdown files
- Plugin management via Settings > Community Plugins
- Template instantiation via Templater or QuickAdd
- Local rendering of Mermaid diagrams, Dataview queries

### 2.2 Obsidian CLI

Terminal control over running Obsidian instance. Registered via symlink:

```bash
# macOS
sudo ln -s "/Applications/Obsidian.app/Contents/Resources/app/obsidian.sh" /usr/local/bin/obsidian

# Verify
obsidian help
```

Capabilities:
- `obsidian open` — open vault or specific note
- URI scheme hooks for automation (`obsidian://advanced-uri?...`)
- Plugin reload, command triggering

### 2.3 Git + GitHub

- **Local Git** tracks all vault changes. Commits on every meaningful edit.
- **GitHub `main` branch** is the authoritative copy.
- **Branch strategy:** `main` for all v1 work. Feature branches for CI/CD or structural changes.
- **Commit convention:** `feat/`, `fix/`, `docs/`, `refactor/` prefixes.

### 2.4 GitHub Actions

Two workflows (v1):

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `vault-r2-sync.yml` | push `vault/**` to `main` | `aws s3 sync vault/ s3://<BUCKET>/vault --delete` |
| `vault-ci.yml` | push `vault/**` to `main` | Markdown lint + attachment validation |

Secrets required (configured in GitHub repo Settings > Secrets):
- `CLOUDFLARE_R2_ACCOUNT_ID`
- `CLOUDFLARE_R2_ACCESS_KEY_ID`
- `CLOUDFLARE_R2_SECRET_ACCESS_KEY`

### 2.5 Cloudflare R2

S3-compatible object storage. Serves as **backup only** in v1 — no direct reads, no CDN serving.

- Endpoint: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`
- Region: `auto`
- Sync direction: GitHub Actions → R2 (one-way)

---

## 3. R2 Setup Procedures

### 3.1 Bucket Creation via Wrangler CLI

```bash
# Install Wrangler globally
npm install -g wrangler

# Authenticate
npx wrangler login

# Create bucket
npx wrangler r2 bucket create dream-vault
```

### 3.2 API Credentials

1. Cloudflare Dashboard > **R2** > **Manage R2 API Tokens**
2. Create token with **Object Read & Write** permission, scoped to the bucket
3. Save `Access Key ID`, `Secret Access Key`, and S3 endpoint
4. Add all three as GitHub Secrets

### 3.3 Rclone for Multi-Device Sync (Optional)

Rclone provides local CLI sync to R2, useful for secondary machines or manual backup:

```bash
# Install (macOS)
brew install rclone

# Configure R2 remote
rclone config
# > New remote: n
# > Name: r2
# > Storage: s3
# > Provider: Cloudflare
# > Enter Access Key ID + Secret Access Key
# > Endpoint: https://<ACCOUNT_ID>.r2.cloudflarestorage.com

# Sync vault to R2
rclone sync ./vault r2:dream-vault/vault
```

This is **supplementary** to the GitHub Actions pipeline — not a replacement.

---

## 4. Obsidian Plugin Architecture

### 4.1 Installation via CLI

Plugins live in `vault/.obsidian/plugins/<plugin-name>/`. Each requires:
- `main.js` — plugin code
- `manifest.json` — metadata
- `styles.css` (optional) — plugin styles

Activation requires entries in `vault/.obsidian/community-plugins.json`:

```json
["remotely-save", "obsidian-advanced-uri", "templater-obsidian"]
```

### 4.2 Plugin Tiers

| Tier | Plugins | Purpose |
|------|---------|---------|
| P0 (Critical) | GitHub PR Autocomplete, Local REST API | Automation integration |
| P1 (Productivity) | Templater, QuickAdd, Tasks, Advanced URI, Metatable | Content workflow |
| P2 (Extended) | BRAT, Dataview, Remotely Save, Image auto upload | Enhanced capabilities |

### 4.3 Remotely Save Configuration

For in-app R2 sync (multi-device scenario), configure via `vault/.obsidian/plugins/remotely-save/data.json`:

```json
{
  "serviceType": "s3",
  "s3": {
    "endpoint": "https://<ACCOUNT_ID>.r2.cloudflarestorage.com",
    "region": "auto",
    "bucketName": "dream-vault",
    "accessKeyId": "<ACCESS_KEY_ID>",
    "secretAccessKey": "<SECRET_ACCESS_KEY>",
    "forcePathStyle": true
  },
  "syncOnEveryOpen": true,
  "autoSyncIntervalInMinutes": 10
}
```

**Security note:** This file contains plaintext credentials. Ensure `data.json` is in `.gitignore` for any vault that pushes to a public repo. For this project (private repo), acceptable but document the risk.

---

## 5. Management CLI

**Entry point:** `scripts/dream-vault.sh`

Single-command interface for all vault operations:

| Command | Subcommand | Description |
|---------|------------|-------------|
| `install` | `install-basic` | Check core tooling (git, node, obsidian CLI) |
| `install` | `install-skills` | Install Claude Code skills |
| `install` | `install-plugins` | Install Obsidian community plugins |
| `install` | `setup-structure` | Create vault folder structure |
| `install` | (default) | Run all install steps |
| `publish` | — | Pre-publish checks + cloud sync |
| `help` | — | Usage documentation |

---

## 6. Data Flow Diagrams

### 6.1 Content Creation Pipeline

```
Note created → Claude Code skill processes →
  ├── Image prompt generation → external tool → save to 98_attachments/_generated/
  ├── SEO optimization → frontmatter rewrite → metadata updated
  └── Content enhancement → links, structure, cross-refs → note updated
→ git commit → git push → GitHub Actions → R2 backup
```

### 6.2 Sync Flow (Normal Operation)

```
Obsidian edit → save to vault/ → git add + commit → git push →
  GitHub Actions triggers →
    Job 1: aws s3 sync → R2 backup
    Job 2: markdownlint + attachment validation
```

### 6.3 Sync Flow (Multi-Device via Remotely Save)

```
Obsidian edit → Remotely Save plugin → direct R2 sync (bypasses GitHub)
⚠️  This path does NOT update Git history. Manual git pull/push needed after.
```

---

## 7. Security Considerations

| Concern | Mitigation |
|---------|------------|
| R2 credentials in CI | GitHub Secrets (never in code) |
| R2 credentials in plugin config | `data.json` in `.gitignore` (private repo acceptable) |
| Vault content privacy | Private GitHub repo; R2 bucket with no public access |
| Obsidian URI scheme | Local-only; no remote attack surface |

---

## 8. Infrastructure Dependencies

### 8.1 Canonical Tech Stack

All implementation uses this stack unless technically infeasible (e.g., GitHub Actions YAML, Obsidian plugin JSON):

| Layer | Tool | Role |
|-------|------|------|
| Runtime | **Bun** | JS/TS runtime, package manager, test runner |
| Language | **TypeScript** (strict) | Type-safe implementation |
| Lint/Format | **Biome** | Linting + formatting (replaces ESLint + Prettier) |
| Database | **SQLite** | Local structured data (metadata, search index) |
| Validation | **Zod** | Runtime schema validation |
| Logging | **LogTape** | Structured logging with log levels |
| ORM | **Drizzle ORM** | Type-safe SQLite queries |
| CLI Framework | **Commander** | CLI command definitions + argument parsing |

### 8.2 Supporting Tools

| Dependency | Version | Purpose |
|------------|---------|--------|
| Obsidian | latest | Client + CLI |
| Git | ≥2.40 | Version control |
| GitHub | — | Remote repo + Actions |
| Wrangler | latest | R2 bucket management |
| rclone | latest | Optional local R2 sync |
| AWS CLI | latest | Used in GitHub Actions for `aws s3 sync` |

---

_Last updated: 2026-05-24_
