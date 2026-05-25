# ADR — Architecture Decision Records

Immutable log of significant architectural decisions. New decisions are appended; no edits to past records.

---

## ADR-001: GitHub as Single Source of Truth

**Date:** 2026-05-22

**Status:** Accepted

**Context:**
Dream Vault needs a reliable, version-controlled hub for vault content. Options considered:
1. **Cloud-first** — R2 as primary, local as cache
2. **Git-first** — GitHub as hub, R2 as backup
3. **Local-first** — local filesystem as primary, cloud as sync target

**Decision:**
Option 2 — GitHub as single source of truth.

**Rationale:**
- Git provides version history, diff, rollback natively
- GitHub Actions provides CI/CD without custom infrastructure
- R2 serves as backup; no need for it to be authoritative
- Single-user vault makes Git-first simple (no merge conflicts from multiple authors)

**Consequences:**
- All changes must go through `git push` to reach R2
- No direct local→R2 sync in primary workflow
- Multi-device scenarios need additional tooling (Remotely Save plugin or rclone)
- R2 will always be behind GitHub by at most one CI run

---

## ADR-002: Cloudflare R2 for Cloud Backup

**Date:** 2026-05-22

**Status:** Accepted

**Context:**
Need cloud backup for vault content. Options considered:
1. **AWS S3** — industry standard, but egress fees
2. **Cloudflare R2** — S3-compatible, zero egress fees
3. **Google Cloud Storage** — good integration, but vendor lock-in
4. **Backblaze B2** — cheap, S3-compatible

**Decision:**
Cloudflare R2.

**Rationale:**
- Zero egress fees (critical for frequent sync)
- S3-compatible API (works with `aws s3 sync`, rclone, Remotely Save plugin)
- Single Cloudflare account can later serve EmDash (v2) from same ecosystem
- Generous free tier (10GB storage, 10M class A ops/month)

**Consequences:**
- Locked into Cloudflare's S3 dialect (minor — standard API surface)
- Wrangler CLI required for bucket management
- Access via API tokens scoped to bucket

---

## ADR-003: Obsidian CLI for Local Automation

**Date:** 2026-05-22

**Status:** Accepted

**Context:**
Need terminal access to Obsidian for scripting and automation. Options:
1. **Obsidian CLI** — official, built into Obsidian app
2. **Local REST API plugin** — HTTP-based, requires running Obsidian
3. **Direct file manipulation** — edit Markdown files, no Obsidian integration

**Decision:**
Obsidian CLI as primary, Local REST API as supplementary.

**Rationale:**
- Official CLI is maintained by Obsidian team
- URI scheme enables triggering actions from shell scripts
- REST API provides richer programmatic access when needed
- Direct file manipulation is fallback (Markdown is plain text)

**Consequences:**
- CLI requires Obsidian app running for live commands
- Symlink registration needed on macOS/Linux
- Some operations still need manual Obsidian restart

---

## ADR-004: Single-Entry Management CLI (dream-vault.sh)

**Date:** 2026-05-22

**Status:** Accepted

**Context:**
Multiple setup and operational steps (install tools, plugins, skills, sync, publish). Need unified interface.

**Decision:**
Bash script `scripts/dream-vault.sh` as single entry point with subcommands.

**Rationale:**
- Zero dependencies (Bash available everywhere)
- Subcommand pattern familiar (`install`, `publish`, `help`)
- Idempotent operations safe to re-run
- Single file to maintain

**Consequences:**
- Complex logic lives in one script — needs modular functions
- No argument validation library — manual checks required
- Future migration to task runner (e.g., `devenv`, `just`) possible

---

## ADR-005: Vault Folder Numbering Convention

**Date:** 2026-05-22

**Status:** Accepted

**Context:**
Obsidian vault needs structured folders for different content types. Options:
1. **Numbered prefixes** (`00-meta/`, `01-projects/`) — enforced ordering in file managers
2. **Plain names** (`meta/`, `projects/`) — cleaner but arbitrary sort order
3. **PARA method** — standard knowledge management hierarchy

**Decision:**
Numbered prefixes following PARA-inspired hierarchy.

```
00-meta/          → Index, vault map
01-projects/      → Active project notes
02-notes/         → Evergreen knowledge (Zettelkasten)
03-areas/         → Responsibility areas
04-resources/     → Reference materials
05-public/        → Publish-ready notes
98_attachments/   → Media (high number = sorted to bottom)
99_templates/     → Note templates
```

**Rationale:**
- Numbered prefix ensures consistent folder ordering across all tools
- `00` for meta, `01-05` for content, `98-99` for utility — standard Obsidian convention
- Aligns with PARA methodology without being rigid

**Consequences:**
- Folder names are coupled to numbering scheme
- Adding new categories requires renumbering decision
- Obsidian sidebar respects this ordering natively

---

## ADR-006: GitHub Actions for CI/CD (Not Local Cron)

**Date:** 2026-05-22

**Status:** Accepted

**Context:**
R2 sync can be triggered locally (cron + rclone) or via GitHub Actions. Options:
1. **Local cron** — rclone sync on schedule, bypasses GitHub
2. **GitHub Actions** — triggered on push, syncs from GitHub to R2
3. **Both** — local for speed, GitHub for backup

**Decision:**
GitHub Actions only for v1. Local sync (rclone/Remotely Save) is optional supplementary.

**Rationale:**
- Maintains GitHub as single source of truth (ADR-001)
- No local daemon/cron to maintain
- Push-triggered means R2 is always in sync with latest commit
- CI also runs lint + validation in same pipeline

**Consequences:**
- R2 sync only happens after push (not real-time)
- Local machine must push before R2 updates
- CI minutes consumed (generous free tier for private repos)

---

## ADR-007: Content Creation via Claude Code Skills

**Date:** 2026-05-22

**Status:** Accepted

**Context:**
Content enhancement (SEO, image prompts, structure) needs AI integration. Options:
1. **Obsidian AI plugins** — in-editor, limited control
2. **Claude Code skills** — CLI-based, full control, scriptable
3. **Custom API pipeline** — most flexible, most maintenance

**Decision:**
Claude Code skills for v1.

**Rationale:**
- Skills are declarative, version-controlled, shareable
- Claude Code has direct file access (no API bridge needed)
- Composable: `content-writer` → `seo-optimizer` → `image-prompt`
- Obsidian AI plugins still available as supplementary

**Consequences:**
- Requires Claude Code session for content processing
- Not integrated into Obsidian UI directly
- Skills maintained in `.claude/skills/` — needs documentation

---

_Last updated: 2026-05-24_

---

## ADR-008: Canonical Tech Stack — Bun + TypeScript + Biome + SQLite + Zod + LogTape + Drizzle + Commander

**Date:** 2026-05-24

**Status:** Accepted

**Context:**
Dream Vault needs implementation tools for the management CLI (`scripts/dream-vault.sh` future migration), skill internals, and any future tooling. The current shell script is sufficient for v1 bootstrap but will hit expressiveness limits as complexity grows.

Options considered:
1. **Node.js + ESLint + Prettier** — established, but slower runtime, fragmented tooling
2. **Bun + Biome** — fast runtime, unified lint+format, newer ecosystem
3. **Deno** — built-in TypeScript, but different stdlib, smaller ecosystem
4. **Shell-only** — zero dependencies, but limited for structured data/validation

**Decision:**
**Bun + TypeScript + Biome + SQLite + Zod + LogTape + Drizzle ORM + Commander.**

| Layer | Choice | Why |
|-------|--------|-----|
| Runtime | Bun | Fast startup, native TS, built-in test runner, drop-in Node compat |
| Language | TypeScript (strict) | Type safety across CLI + data layer |
| Lint/Format | Biome | Single tool replaces ESLint + Prettier; fast Rust-based |
| Database | SQLite | Zero-config local DB for vault metadata, search index |
| Validation | Zod | Runtime schema validation with TS inference |
| Logging | LogTape | Structured logging with configurable levels and transports |
| ORM | Drizzle ORM | Type-safe SQL, lightweight, excellent SQLite support |
| CLI | Commander | De facto TS CLI framework; well-typed, composable |

**Rationale:**
- Bun eliminates `ts-node`, `tsx`, `jest`/`vitest` — one runtime handles all
- Biome replaces two tools (ESLint + Prettier) with one config
- SQLite is the only zero-config embedded DB; Drizzle provides type-safe queries without abstraction tax
- Zod validates at system boundaries (frontmatter schemas, plugin configs)
- Commander provides CLI structure for future `dream-vault` tool migration from Bash

**Consequences:**
- Bun required on all development machines
- Some npm packages may have Bun-specific edge cases (rare in 2026)
- Shell scripts (`dream-vault.sh`) remain for v1 bootstrap; migration to Commander CLI is a v1.x milestone
- GitHub Actions CI uses `oven-sh/setup-bun` instead of `actions/setup-node`

**Exceptions:**
- GitHub Actions workflow YAML — no TS alternative
- Obsidian plugin JSON config — static data, no runtime
- `dream-vault.sh` — remains Bash until Commander CLI migration

---

_Last updated: 2026-05-24_
