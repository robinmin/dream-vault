---
name: content-writer
description: Enhance Obsidian note structure, clarity, and cross-references. Analyzes content quality, suggests improvements, injects internal links, and flags incomplete sections.
---

# Content Writer Skill

Enhances Obsidian note quality through structure analysis, cross-reference injection, clarity improvements, and completeness checks.

## Activation

User asks to "enhance note", "improve content", "add cross-references", "review structure", or passes a note path for content improvement.

## Analysis Workflow

### Step 1: Read and Parse

1. Read the target note from vault
2. Parse frontmatter (YAML between `---` delimiters)
3. Extract: title, tags, existing links, heading structure
4. Count words, paragraphs, code blocks, images

### Step 2: Structure Analysis

| Check | Criteria | Status |
|-------|----------|--------|
| Heading hierarchy | Single H1 (title), sequential H2→H3, no skipped levels | PASS/WARN/FAIL |
| Section balance | No section > 500 words without subheadings | PASS/WARN |
| Introduction | First paragraph summarizes the topic | PASS/WARN |
| Conclusion | Final section wraps up or provides next steps | PASS/WARN |
| Word count | ≥ 300 words for articles, ≥ 100 for notes | PASS/WARN |

### Step 3: Clarity Review

- **Passive voice**: Flag sentences like "was done by" → suggest "did"
- **Long sentences**: Flag > 40 words → suggest splitting
- **Undefined jargon**: Flag terms without context or definition
- **Weak openings**: Flag "There is/are", "It is important to note"

### Step 4: Cross-Reference Injection

Scan vault for related notes and suggest internal links:

1. Extract key terms and concepts from the current note
2. Search vault for notes containing matching terms
3. Score relevance by: title match, tag overlap, shared keywords
4. Suggest top 5-8 `[[wikilinks]]` to insert at appropriate locations

Priority link targets:
- Notes in same folder (e.g., same project in `01-projects/`)
- Notes with shared tags
- Notes referenced by the current note's references

### Step 5: Action Item Detection

Find and flag:
- `TODO:` markers → convert to `- [ ]` task syntax
- `FIXME:` markers → convert to `- [ ]` with urgency note
- Unfinished sentences ending in `...`
- Empty sections (headings with no content)

## Enhancement Output

```
## Content Report: [note-title]

### Structure
| Check | Status | Detail |
|-------|--------|--------|
| Headings | ✅ PASS | H1→H2→H3 hierarchy correct |
| Sections | ⚠️ WARN | "Architecture" section is 620 words, add H3 subheadings |
| Word Count | ✅ PASS | 847 words |
| Intro | ✅ PASS | First paragraph summarizes topic |
| Conclusion | ❌ FAIL | No conclusion section |

### Suggested Cross-References
- `[[related-note-1]]` — shares 3 keywords, same project
- `[[related-note-2]]` — tag overlap: #architecture, #dream-vault

### Action Items Found
- Line 42: `TODO: add diagram` → `- [ ] Add architecture diagram`
- Line 87: `FIXME: broken link` → `- [ ] Fix broken link reference`

### Suggested Changes
[Diff-style output of proposed edits]
```

## Modification Rules

When making changes directly:

1. **Never delete content** — only restructure, rephrase, or add
2. **Preserve code blocks** — don't modify fenced code content
3. **Keep frontmatter order** — only add missing fields
4. **Use wikilinks** — `[[note-name]]` for internal links (Obsidian convention)
5. **Add edit markers** — wrap new content in `%%NEW%%` comments for review (remove before commit)

## File References

- Vault structure: `AGENTS.md` §3.6
- SEO schema: `src/db/schemas.ts` → `seoFrontmatterSchema`
- Content pipeline: `docs/01_PRD.md` §6.1
