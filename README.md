# Dream Vault

An Obsidian vault template with AI-augmented content creation, GitHub as single source of truth, and Cloudflare R2 cloud backup via GitHub Actions CI/CD.

## Tech Stack

**Bun + TypeScript + Biome + SQLite + Zod + LogTape + Drizzle ORM + Commander**

All implementation follows this canonical stack (see [ADR-008](docs/03_ADR.md)). Shell scripts used only for v1 bootstrap.

## Features

- **GitHub → R2 sync** — automated backup on every push to `main`
- **Obsidian CLI** — terminal vault management
- **Structured vault** — `NN_folder` convention for clean layout
- **Templates** — daily, meeting, project, scratch, article
- **AI content pipeline** — image prompts, SEO optimizer, content enhancement (Claude Code skills)
- **EmDash-ready** — v2 publishing pipeline planned

## Quick Start

```bash
git clone <your-repo> dream-vault && cd dream-valut
bun install
./scripts/dream-vault.sh install
# Open vault/ in Obsidian → File > Open Vault
```

Full setup guide: [CONFIG.md](CONFIG.md)

## Project Structure

```
dream-valut/
├── src/                     # Bun + TypeScript source (Commander CLI, DB, skills)
│   ├── cli/                # Commander CLI commands
│   ├── db/                 # Drizzle ORM + SQLite schemas
│   ├── skills/             # Skill implementations
│   └── utils/              # Shared utilities + LogTape logger
├── vault/                   # Obsidian vault content
│   ├── .obsidian/          # Obsidian config + plugins
│   ├── 99_templates/       # Note templates
│   ├── 98_attachments/     # Media + AI-generated assets
│   ├── 00-meta/            # Vault index
│   ├── 01-projects/ → 05-public/  # Content folders
├── scripts/
│   └── dream-vault.sh      # Shell management CLI (v1)
├── docs/
│   ├── 01_PRD.md           # Product Requirements
│   ├── 02_ARCH.md          # Architecture
│   └── 03_ADR.md           # Architecture Decision Records
├── .github/workflows/      # CI/CD (R2 sync, lint, validate)
└── AGENTS.md               # Agent config (→ CLAUDE.md, GEMINI.md)
```

## Commands

```bash
# Bun/TS commands
bun run check          # Biome lint + format check
bun run typecheck      # TypeScript strict check
bun run format         # Auto-format src/

# Shell CLI (v1)
./scripts/dream-vault.sh install              # run all install steps
./scripts/dream-vault.sh install install-basic  # check core tooling
./scripts/dream-vault.sh publish              # pre-publish checks
```

## Documentation

| Doc | Purpose |
|-----|---------|
| [CONFIG.md](CONFIG.md) | Setup guide (prerequisites, R2 config, secrets) |
| [docs/01_PRD.md](docs/01_PRD.md) | Product requirements, goals, workflows |
| [docs/02_ARCH.md](docs/02_ARCH.md) | Technical architecture, component design |
| [docs/03_ADR.md](docs/03_ADR.md) | Architecture Decision Records (ADR-001 through ADR-008) |

## License

Private repository. All rights reserved.
