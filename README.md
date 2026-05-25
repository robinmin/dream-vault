# Dream Vault

Obsidian vault template with AI-augmented content creation. GitHub is the single source of truth; Cloudflare R2 provides zero-egress backup via GitHub Actions.

## Tech Stack

| Layer | Tool |
|-------|------|
| Runtime | Bun |
| Language | TypeScript (strict) |
| Lint / Format | Biome |
| Database | SQLite + Drizzle ORM |
| Validation | Zod |
| Logging | LogTape |
| CLI | Commander |
| CI/CD | GitHub Actions |
| Storage | Cloudflare R2 (S3-compatible) |

Canonical stack defined in [ADR-008](docs/03_ADR.md). Shell scripts used for v1 bootstrap only.

## Architecture

```
Obsidian (local edit)
    │
    ▼
git push → GitHub (source of truth)
    │
    ├──→ vault-ci.yml     (lint + validate)
    └──→ vault-r2-sync.yml (mirror to R2, --delete)
```

Components:

- **Commander CLI** (`src/cli/`) — `install`, `publish`, `status`, `health`, `db:init`
- **SQLite metadata DB** (`src/db/`) — 5 tables: notes, frontmatter_cache, sync_status, attachments, notes_fts
- **Health checker** — orphaned attachments, missing frontmatter, broken wikilinks, empty directories
- **Shell CLI** (`scripts/dream-vault.sh`) — v1 fallback; delegates plugin install, structure setup, publish checks
- **Claude Code skills** (`.claude/skills/`) — SEO optimizer, image prompt generator, content writer, vault manager

## Project Structure

```
dream-vault/
├── src/
│   ├── cli/
│   │   ├── bin.ts              # Bun entry point (#!/usr/bin/env bun)
│   │   ├── index.ts            # Commander program + 5 subcommands
│   │   └── health.ts           # 4 filesystem health checks
│   ├── db/
│   │   ├── schema.ts           # Drizzle tables (notes, frontmatter, sync, attachments, FTS)
│   │   ├── schemas.ts          # Zod validation (frontmatter, SEO metadata)
│   │   ├── index.ts            # initDb, runMigrations, createTables (WAL mode)
│   │   └── mod.ts              # Re-exports
│   └── utils/
│       ├── logger.ts           # LogTape setup (pretty renderer)
│       └── index.ts            # Re-exports
├── vault/
│   ├── .obsidian/              # Obsidian config + community-plugins.json
│   ├── 00-meta/                # Vault index
│   ├── 01-projects/            # Per-project notes
│   ├── 02-notes/               # Evergreen knowledge (Zettelkasten)
│   ├── 03-areas/               # Areas of responsibility
│   ├── 04-resources/           # Reference materials
│   ├── 05-public/              # Notes flagged for publishing
│   ├── 98_attachments/
│   │   └── _generated/         # AI-generated images
│   └── 99_templates/           # daily, meeting, project, scratch, article
├── scripts/
│   └── dream-vault.sh          # Shell management CLI (v1)
├── drizzle/
│   └── 0000_quick_gambit.sql   # Initial migration
├── .github/workflows/
│   ├── vault-ci.yml            # Markdown lint + attachment/frontmatter validation
│   └── vault-r2-sync.yml       # aws s3 sync → R2 on vault/** push
├── docs/
│   ├── 01_PRD.md               # Product Requirements Document
│   ├── 02_ARCH.md              # Architecture Document
│   └── 03_ADR.md               # Architecture Decision Records (ADR-001–008)
├── .claude/skills/             # 9 Claude Code skills
├── AGENTS.md                   # Agent config (symlinked → CLAUDE.md, GEMINI.md)
├── CONFIG.md                   # Setup guide
├── biome.json                  # Biome v2.4.15 config
├── drizzle.config.ts           # Drizzle Kit config
├── package.json                # Bun project manifest
└── tsconfig.json               # TypeScript strict config
```

## Commands

```bash
# Development
bun install                     # Install dependencies
bun run check                   # Biome lint + format check
bun run typecheck               # TypeScript strict check (tsc --noEmit)
bun run format                  # Auto-format src/

# Database
bun run db:generate             # Generate Drizzle migration from schema changes
bun run db:migrate              # Run pending migrations
bun run db:studio               # Open Drizzle Studio (DB browser)

# Commander CLI (via bun)
bun src/cli/bin.ts install      # Install deps + configure vault
bun src/cli/bin.ts status       # Show vault directory + DB status
bun src/cli/bin.ts health       # Run 4 health checks (orphans, frontmatter, links, dirs)
bun src/cli/bin.ts health --fix # Auto-fix issues where possible
bun src/cli/bin.ts publish      # Pre-publish checks + cloud sync
bun src/cli/bin.ts db:init      # Initialize SQLite metadata database

# Shell CLI (v1 fallback)
./scripts/dream-vault.sh install              # run all install steps
./scripts/dream-vault.sh install install-basic  # check core tooling (brew, obsidian, rclone, aws)
./scripts/dream-vault.sh install install-plugins # download 7 community plugins from GitHub
./scripts/dream-vault.sh install setup_structure # create vault folder structure
./scripts/dream-vault.sh publish              # pre-publish checks + sync
```

## Database Schema

| Table | Purpose |
|-------|---------|
| `notes` | Vault note metadata (path, title, tags, word count, hash) |
| `frontmatter_cache` | Parsed YAML frontmatter per note |
| `sync_status` | Last sync timestamp per path |
| `attachments` | File metadata for attachments |
| `notes_fts` | Full-text search virtual table |

Zod schemas in `src/db/schemas.ts` validate:
- Note frontmatter (title, date, tags, publish flag)
- SEO metadata (title ≤ 60 chars, description ≤ 160 chars, keywords, og_type)

## GitHub Actions

| Workflow | Trigger | Action |
|----------|---------|--------|
| `vault-ci.yml` | push `vault/**` to `main` | Bun setup → markdownlint → attachment validation → frontmatter check |
| `vault-r2-sync.yml` | push `vault/**` to `main` | `aws s3 sync` with `--delete` to Cloudflare R2 |

**Required secrets:** `CLOUDFLARE_R2_ACCOUNT_ID`, `CLOUDFLARE_R2_ACCESS_KEY_ID`, `CLOUDFLARE_R2_SECRET_ACCESS_KEY`, `CLOUDFLARE_R2_BUCKET_NAME`

## Health Checks

| Check | Severity | What it finds |
|-------|----------|---------------|
| Orphaned Attachments | ⚠️ warn | Files in `98_attachments/` not referenced by any note |
| Missing Frontmatter | ❌ fail | Public notes missing `title` or `date` |
| Broken Internal Links | ❌ fail | `[[wikilinks]]` pointing to non-existent notes |
| Empty Directories | ⚠️ warn | Content folders with only `.gitkeep` |

## Obsidian Plugins

Auto-installed by `./scripts/dream-vault.sh install install-plugins`:

| Plugin | Source |
|--------|--------|
| Templater | SilentVoid13/Templater |
| QuickAdd | chhoumann/quickadd |
| Obsidian Tasks | obsidian-tasks-group/obsidian-tasks |
| Advanced URI | Vinzent03/obsidian-advanced-uri |
| Metatable | joschahenningsen/obsidian-metatable |
| Local REST API | adamgibbons/obsidian-local-rest-api |
| Remotely Save | remotely-save/remotely-save |

Additional plugins (install via Obsidian UI): GitHub PR Autocomplete, Vault Inspector, Image auto upload, BRAT, Dataview.

## Documentation

| Doc | Purpose |
|-----|---------|
| [CONFIG.md](CONFIG.md) | Setup guide (prerequisites, R2 config, secrets, Bun install) |
| [docs/01_PRD.md](docs/01_PRD.md) | Product requirements, goals, workflows, plugin list |
| [docs/02_ARCH.md](docs/02_ARCH.md) | Technical architecture, component responsibilities, data flows |
| [docs/03_ADR.md](docs/03_ADR.md) | 8 immutable Architecture Decision Records |

## Quick Start

```bash
git clone <your-repo> dream-vault && cd dream-vault
bun install
./scripts/dream-vault.sh install              # tools + plugins + vault structure
bun src/cli/bin.ts db:init                    # initialize metadata DB
bun src/cli/bin.ts health                     # verify vault is healthy
# Open vault/ in Obsidian → File > Open Vault
```

## References
- [karpathy/llm-wiki.md](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [nashsu/llm_wiki](https://github.com/nashsu/llm_wiki)
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)
- [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)
