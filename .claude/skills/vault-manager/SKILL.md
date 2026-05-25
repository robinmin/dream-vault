---
name: vault-manager
description: Manage Dream Vault structure, check sync status, and run maintenance tasks. Use when asked about vault status, structure, or maintenance.
---

## Dream Vault Structure

Vault lives at `vault/` in the project root.

Standard folders:
- `vault/99_templates/` — Note templates
- `vault/98_attachments/` — Media files and AI-generated assets
- `vault/00-meta/` — Vault index
- `vault/01-projects/` — Project notes
- `vault/02-notes/` — Evergreen notes
- `vault/03-areas/` — Areas of responsibility
- `vault/04-resources/` — Reference materials
- `vault/05-public/` — Notes ready for publishing

## Commands

### Check vault health
```bash
obsidian vaults list
obsidian search query=""
```

### Count notes
```bash
obsidian eval "app.vault.getFiles().length"
```

### Find unresolved links
```bash
obsidian unresolved
```
