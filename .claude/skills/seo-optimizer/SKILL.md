---
name: seo-optimizer
description: Optimize Obsidian note frontmatter for SEO — validates title, description, keywords, tags, internal links, and OG metadata using Zod schemas.
---

# SEO Optimizer Skill

Analyzes and optimizes Obsidian note frontmatter for search engine visibility and social sharing.

## Activation

User asks to "optimize SEO", "check SEO", "analyze frontmatter", or passes a note path for SEO review.

## Required Frontmatter Schema

All public notes (`vault/05-public/` or `publish: true`) must satisfy:

```yaml
title: string        # ≤ 60 chars, descriptive
description: string  # ≤ 160 chars, content summary
keywords: string[]   # 3-8 relevant terms
publish: boolean     # true for public notes
date: YYYY-MM-DD     # ISO date
author: string       # author name
image: string        # optional, path to cover image
og_type: article|website|profile  # default: article
```

## Validation Rules

### Title (`title`)
- **PASS**: ≤ 60 characters, contains primary keyword
- **WARN**: 61-70 characters (truncated in some SERPs)
- **FAIL**: > 70 characters, missing, or generic ("Untitled", "New Note")

### Description (`description`)
- **PASS**: ≤ 160 characters, summarizes content, includes keyword
- **WARN**: 161-200 characters
- **FAIL**: > 200 characters, missing, or same as title

### Keywords (`keywords`)
- **PASS**: 3-8 keywords, lowercase, no duplicates
- **WARN**: 1-2 or 9+ keywords
- **FAIL**: missing or empty array

### Date (`date`)
- **PASS**: valid YYYY-MM-DD format
- **FAIL**: missing or invalid format

### Publish Flag (`publish`)
- If note is in `vault/05-public/` → must be `true`
- If `publish: true` → note should be in `vault/05-public/`

### Image (`image`)
- **WARN**: missing (no OG image for social sharing)
- **PASS**: path exists in `vault/98_attachments/`

## Analysis Workflow

1. **Read** the target note from vault
2. **Parse** YAML frontmatter (between `---` delimiters)
3. **Validate** each field against rules above
4. **Check content** for:
   - Word count (minimum 300 words for articles)
   - Heading structure (H1 title, H2 sections, H3 subsections)
   - Internal links (`[[wikilinks]]` or `[md](links)`)
   - External links (at least 1 authoritative reference)
   - Image references (at least 1)
5. **Suggest keywords** from content frequency analysis
6. **Suggest internal links** by matching note topics against other vault notes
7. **Output** structured report

## Output Format

```
## SEO Report: [note-title]

| Check | Status | Value | Note |
|-------|--------|-------|------|
| Title | ✅ PASS | "..." | 45 chars |
| Description | ⚠️ WARN | "..." | 175 chars (truncate recommended) |
| Keywords | ❌ FAIL | — | Missing; suggested: ["k1", "k2", "k3"] |
| Date | ✅ PASS | 2026-05-24 | — |
| Word Count | ✅ PASS | 847 | — |
| Headings | ⚠️ WARN | 1 H2 only | Add H2/H3 sections |
| Internal Links | ❌ FAIL | 0 | Add links to related notes |
| Images | ⚠️ WARN | 0 | Add cover image for OG |

### Suggested Changes

```yaml
# Apply these frontmatter updates:
title: "..."
description: "..."
keywords: [...]
```
```

## File References

- Zod schema: `src/db/schemas.ts` → `seoFrontmatterSchema`
- Frontmatter standard: `docs/01_PRD.md` §7.1
- Vault conventions: `AGENTS.md` §3.6
