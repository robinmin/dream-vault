# Dream Vault

Obsidian vault template with AI-augmented content creation. GitHub is the single source of truth; Cloudflare R2 provides zero-egress backup via GitHub Actions.

## Tech Stack

| Layer | Tool |
|-------|------|
| Runtime | Bun |
| Language | TypeScript (strict) |
| Lint / Format | Biome |
| Database | SQLite (bun:sqlite) + Drizzle ORM |
| Validation | Zod |
| Logging | LogTape |
| CLI | Commander |
| CI/CD | GitHub Actions |
| Storage | Cloudflare R2 (S3-compatible) |

Canonical stack defined in [ADR-008](docs/03_ADR.md).

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

**CLI separation:**

| CLI | Scope | Entry |
|-----|-------|-------|
| `scripts/dream-vault.sh` | Resource management (binaries, plugins, skills, secrets, sync) | `./scripts/dream-vault.sh <cmd>` |
| `src/cli/index.ts` | Vault operations (health, status, publish, db) | `bun run dv <cmd>` or `./scripts/dv` |

Components:

- **Commander CLI** (`src/cli/`) — thin CLI surface (`index.ts`) + action modules (`health.ts`, `status.ts`, `publish.ts`)
- **SQLite metadata DB** (`src/db/`) — notes, frontmatter_cache, sync_status, attachments, notes_fts
- **Health checker** — orphaned attachments, missing frontmatter, broken wikilinks, empty directories
- **Shell CLI** (`scripts/dream-vault.sh`) — install, plugins, skills, secrets, emergency R2 sync
- **Claude Code skills** (`.claude/skills/`) — SEO optimizer, image prompt generator, content writer, vault manager

## Project Structure

```
dream-vault/
├── src/
│   ├── cli/
│   │   ├── index.ts            # CLI surface + Commander program + program.parse()
│   │   ├── health.ts           # 4 filesystem health checks
│   │   ├── status.ts           # Vault directory + DB status
│   │   └── publish.ts          # Pre-publish checks
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
│   ├── .dream-vault/           # SQLite metadata DB
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
│   ├── dream-vault.sh          # Shell management CLI (resource ops)
│   └── dv                      # Compiled standalone binary (bun build --compile)
├── drizzle/
│   └── 0000_quick_gambit.sql   # Initial migration
├── .github/workflows/
│   ├── vault-ci.yml            # Markdown lint + attachment/frontmatter validation
│   └── vault-r2-sync.yml       # aws s3 sync → R2 on vault/** push
├── docs/
│   ├── 01_PRD.md               # Product Requirements Document
│   ├── 02_ARCH.md              # Architecture Document
│   ├── 03_ADR.md               # Architecture Decision Records (ADR-001–008)
│   └── 09_SETUP.md             # Full setup guide
├── .claude/skills/             # Claude Code skills
├── AGENTS.md                   # Agent config (symlinked → CLAUDE.md, GEMINI.md)
├── CONFIG.md                   # Setup guide
├── biome.json                  # Biome config
├── drizzle.config.ts           # Drizzle Kit config
├── package.json                # Bun project manifest
└── tsconfig.json               # TypeScript strict config
```

## Commands

### Setup

```bash
bun run dv:install                  # run all install steps
bun run dv:install install-basic    # check core tooling
bun run dv:install install-plugins  # download community plugins
bun run dv:install install-skills   # install Claude Code skills
bun run dv:install setup_structure  # create vault folder structure
bun run dv:install setup_secrets    # set GitHub Actions secrets from .env
bun run dv:list                     # show installed resources
bun run dv:sync                     # [emergency] rclone sync vault/ → R2
```

### Vault Operations

```bash
bun run dv health                   # 4 health checks (orphans, frontmatter, links, dirs)
bun run dv health --fix             # Auto-fix issues where possible
bun run dv status                   # Show vault directory + DB status
bun run dv publish                  # Pre-publish checks (structure, git, config)
bun run dv db:init                  # Initialize SQLite metadata database
```

### Development

```bash
bun install                     # Install dependencies
bun run check                   # Biome lint + format check
bun run typecheck               # TypeScript strict check (tsc --noEmit)
bun run autofix                 # Biome lint + format auto-fix
bun run build                   # Compile standalone binary → scripts/dv

# Database
bun run db:generate             # Generate Drizzle migration from schema changes
bun run db:migrate              # Run pending migrations
bun run db:studio               # Open Drizzle Studio (DB browser)
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

Auto-installed by `bun run dv:install install-plugins`:

| Plugin | Source |
|--------|--------|
| Templater | SilentVoid13/Templater❌ |
| QuickAdd | chhoumann/quickadd❌ |
| Obsidian Tasks | obsidian-tasks-group/obsidian-tasks❌ |
| Advanced URI | Vinzent03/obsidian-advanced-uri❌ |
| Metatable | joschahenningsen/obsidian-metatable❌ |
| Local REST API | adamgibbons/obsidian-local-rest-api❌ |
| Remotely Save | remotely-save/remotely-save❌ |

Additional plugins (install via Obsidian UI): GitHub PR Autocomplete, Vault Inspector, Image auto upload, BRAT, Dataview.

## Quick Start

```bash
# 1. Clone & install
git clone https://github.com/<you>/dream-vault.git && cd dream-vault
bun install

# 2. Initialize vault structure + plugins + skills
bun run dv:install

# 3. Create Cloudflare R2 bucket
wrangler login
wrangler r2 bucket create dream-vault

# 4. Configure GitHub Actions secrets
cp .env.example .env            # fill in R2 credentials
bun run dv:install setup_secrets

# 5. Initialize metadata DB & verify
bun run dv db:init
bun run dv health
bun run dv:list

# 6. Open in Obsidian → File > Open Vault → vault/
```

Full step-by-step guide: [docs/09_SETUP.md](docs/09_SETUP.md)

### Common Commands

| Task | Command |
|------|--------|
| Lint + format fix | `bun run autofix` |
| Type check | `bun run typecheck` |
| Health check | `bun run dv health` |
| Pre-publish checks | `bun run dv publish` |
| Emergency R2 sync | `bun run dv:sync` |
| Check installed resources | `bun run dv:list` |
| Install all resources | `bun run dv:install` |
| Build standalone binary | `bun run build` |

## Documentation

| Doc | Purpose |
|-----|--------|
| [docs/01_PRD.md](docs/01_PRD.md) | Product requirements, goals, workflows, plugin list |
| [docs/02_ARCH.md](docs/02_ARCH.md) | Technical architecture, component responsibilities, data flows |
| [docs/03_ADR.md](docs/03_ADR.md) | 8 immutable Architecture Decision Records |
| [docs/08_CONFIG.md](docs/08_CONFIG.md) | Vault configuration reference |
| [docs/09_SETUP.md](docs/09_SETUP.md) | Full setup guide (R2, secrets, initialization) |

## References
- [karpathy/llm-wiki.md](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [nashsu/llm_wiki](https://github.com/nashsu/llm_wiki)
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)
- [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)
