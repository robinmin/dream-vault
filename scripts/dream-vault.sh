#!/usr/bin/env bash
# =============================================================================
# dream-vault.sh — Dream Vault management CLI
# Usage: ./dream-vault.sh <command> [options]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_DIR="$PROJECT_ROOT/vault"
CONFIG_FILE="$PROJECT_ROOT/CONFIG.md"

# -----------------------------------------------------------------------------
# Color codes
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error() { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
bold() { echo -e "${BOLD}$*${RESET}"; }

usage() {
	bold "dream-vault — Dream Vault management CLI"
	echo ""
	echo "Usage: $0 <command> [options]"
	echo ""
	echo "Commands:"
	echo "  install          Install dependencies and configure the vault"
	echo "    install-basic    Install core tooling (brew/npm packages)"
	echo "    install-skills   Install Claude Code skills for this project"
	echo "    install-plugins  Install Obsidian community plugins"
	echo "    setup_structure  Create vault folder structure and default templates"
	echo "  publish          Run pre-publish checks and sync to cloud"
	echo "  help             Show this help message"
	echo ""
	echo "Examples:"
	echo "  $0 install install-basic"
	echo "  $0 install install-skills"
	echo "  $0 install install-plugins"
	echo "  $0 install setup_structure"
	echo "  $0 install           # Run all install sub-commands"
	echo "  $0 publish"
	echo "  $0 help"
}

# -----------------------------------------------------------------------------
# Check prerequisites
# -----------------------------------------------------------------------------
check_obsidian() {
	if ! command -v obsidian &>/dev/null; then
		error "Obsidian CLI not found. Run: sudo ln -s '/Applications/Obsidian.app/Contents/Resources/app/obsidian.sh' /usr/local/bin/obsidian"
		return 1
	fi
	return 0
}

check_git() {
	if ! command -v git &>/dev/null; then
		error "Git not found."
		return 1
	fi
	return 0
}

check_rclone() {
	if ! command -v rclone &>/dev/null; then
		warn "rclone not found. Install with: brew install rclone"
	fi
}

# -----------------------------------------------------------------------------
# install-basic — install core tooling
# -----------------------------------------------------------------------------
do_install_basic() {
	bold "Installing core tooling..."
	info "Checking for Homebrew..."
	if command -v brew &>/dev/null; then
		success "Homebrew found"
	else
		warn "Homebrew not found. Install from https://brew.sh if needed."
	fi

	info "Checking for obsidian CLI..."
	if command -v obsidian &>/dev/null; then
		success "Obsidian CLI found: $(obsidian --version 2>/dev/null || echo 'unknown version')"
	else
		warn "Obsidian CLI not linked. Run:"
		echo "  sudo ln -s '/Applications/Obsidian.app/Contents/Resources/app/obsidian.sh' /usr/local/bin/obsidian"
	fi

	info "Checking for rclone..."
	if command -v rclone &>/dev/null; then
		success "rclone found: $(rclone version 2>/dev/null | head -1)"
	else
		warn "rclone not found. Run: brew install rclone"
	fi

	info "Checking for AWS CLI..."
	if command -v aws &>/dev/null; then
		success "AWS CLI found: $(aws --version 2>/dev/null)"
	else
		warn "AWS CLI not found. Run: brew install awscli"
	fi

	info "Checking for Node.js..."
	if command -v node &>/dev/null; then
		success "Node.js found: $(node --version)"
	else
		warn "Node.js not found. Run: brew install node"
	fi

	success "Core tooling check complete."
}

# -----------------------------------------------------------------------------
# install-skills — install Claude Code skills
# -----------------------------------------------------------------------------
do_install_skills() {
	bold "Installing Claude Code skills..."
	CLAUDE_DIR="$PROJECT_ROOT/.claude"
	SKILLS_DIR="$CLAUDE_DIR/skills"

	if [ ! -d "$CLAUDE_DIR" ]; then
		mkdir -p "$SKILLS_DIR"
		info "Created $CLAUDE_DIR"
	fi

	# Skill: vault-manager (project-specific)
	mkdir -p "$SKILLS_DIR/vault-manager"
	cat >"$SKILLS_DIR/vault-manager/SKILL.md" <<'EOF'
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
EOF
	success "Installed skill: vault-manager"

	# Skill: image-prompt
	mkdir -p "$SKILLS_DIR/image-prompt"
	cat >"$SKILLS_DIR/image-prompt/SKILL.md" <<'EOF'
---
name: image-prompt
description: Generate optimized image prompts for Midjourney, DALL-E, Flux, and Stable Diffusion from a concept description.
---

## Image Prompt Generator

Given a concept, generate a detailed image prompt suitable for AI image generation tools.

## Usage

When given a concept like "AI knowledge graph", produce prompts for:
- **Midjourney** — artistic, detailed, photorealistic style
- **DALL-E 3** — clear, descriptive, naturalistic
- **Flux.1** — open source, high fidelity
- **Stable Diffusion** — flexible, customizable

## Prompt Format

```
[Subject] in [setting/environment], [style descriptor], [lighting], [camera angle], [resolution hint]
```

## Example

Input: "AI knowledge graph"
Output for Midjourney:
"A glowing neural network knowledge graph floating in a dark digital void, nodes connected by light threads, cinematic lighting, ultra detailed, 4K"

Output for DALL-E:
"A visualized AI knowledge graph with glowing nodes and connection lines on a dark background, futuristic, clean, detailed"
EOF
	success "Installed skill: image-prompt"

	# Skill: seo-optimizer
	mkdir -p "$SKILLS_DIR/seo-optimizer"
	cat >"$SKILLS_DIR/seo-optimizer/SKILL.md" <<'EOF'
---
name: seo-optimizer
description: Optimize Obsidian note frontmatter for SEO — title, description, keywords, tags, and internal links.
---

## SEO Optimizer

When analyzing a note for SEO:

1. **Title** — Check ≤ 60 characters, descriptive
2. **Description** — Check ≤ 160 characters, summarizes content
3. **Keywords** — Extract top 5-8 keywords from content
4. **Tags** — Suggest relevant tags from existing vault tag taxonomy
5. **Internal links** — Add links to related notes in vault
6. **Publish flag** — Set `publish: true` if note is in `vault/05-public/`

## Required Frontmatter

```yaml
---
title: "..."
description: "..."
keywords: ["...", "..."]
publish: false
date: YYYY-MM-DD
author: "Your Name"
og_type: "article"
---
```

## Workflow

```
1. Read note content
2. Check/update frontmatter fields
3. Suggest internal links to related notes
4. Flag missing or malformed fields
```
EOF
	success "Installed skill: seo-optimizer"

	# Skill: content-writer
	mkdir -p "$SKILLS_DIR/content-writer"
	cat >"$SKILLS_DIR/content-writer/SKILL.md" <<'EOF'
---
name: content-writer
description: Enhance Obsidian note structure, clarity, and cross-references. Use when drafting or improving articles.
---

## Content Writer

When enhancing a note:

1. **Structure** — Ensure H1 → H2 → H3 hierarchy is logical
2. **Clarity** — Rewrite ambiguous sentences; prefer active voice
3. **Cross-references** — Link to related notes in vault using [[note-name]] syntax
4. **Action items** — Convert unchecked boxes to task syntax `- [ ]`
5. **Frontmatter** — Ensure title, date, tags are present
6. **Word count** — Flag if < 300 words (may be too sparse)

## Output

After enhancement, provide a brief summary of changes made.
EOF
	success "Installed skill: content-writer"

	# Install kepano/obsidian-skills (official Obsidian skills)
	bold "Installing kepano/obsidian-skills..."
	KEPO_REPO="kepano/obsidian-skills"
	KEPO_TMP=$(mktemp -d)
	KEPO_SKILLS="$KEPO_TMP/obsidian-skills/skills"

	if git clone --depth 1 "https://github.com/$KEPO_REPO.git" "$KEPO_TMP/obsidian-skills" 2>/dev/null; then
		if [ -d "$KEPO_SKILLS" ]; then
			for skill_dir in "$KEPO_SKILLS"/*/; do
				if [ -d "$skill_dir" ]; then
					skill_name=$(basename "$skill_dir")
					mkdir -p "$SKILLS_DIR/$skill_name"
					cp "$skill_dir"*.md "$SKILLS_DIR/$skill_name/" 2>/dev/null || true
					success "Installed skill: $skill_name"
				fi
			done
		else
			warn "No skills/ directory found in $KEPO_REPO"
		fi
		rm -rf "$KEPO_TMP"
	else
		warn "Failed to clone $KEPO_REPO — skipping. Ensure git is available."
		rm -rf "$KEPO_TMP"
	fi

	info "Available skills:"
	ls -1 "$SKILLS_DIR/" | sed 's/^/  - /'

	success "All Claude Code skills installed to $SKILLS_DIR"
}

# -----------------------------------------------------------------------------
# install-plugins — install Obsidian community plugins from GitHub releases
# -----------------------------------------------------------------------------

# Plugin registry: repo-name → GitHub repo path
declare -A PLUGIN_REPOS=(
	[templater - obsidian]="SilentVoid13/Templater"
	[quickadd]="chhoumann/quickadd"
	[obsidian - tasks - plugin]="obsidian-tasks-group/obsidian-tasks"
	[obsidian - advanced - uri]="Vinzent03/obsidian-advanced-uri"
	[obsidian - metatable]="joschahenningsen/obsidian-metatable"
	[obsidian - local - rest - api]="adamgibbons/obsidian-local-rest-api"
	[remotely - save]="remotely-save/remotely-save"
)

do_install_plugins() {
	bold "Installing Obsidian community plugins..."

	PLUGIN_DIR="$VAULT_DIR/.obsidian/plugins"
	mkdir -p "$PLUGIN_DIR"

	installed=0
	skipped=0

	for plugin in "${!PLUGIN_REPOS[@]}"; do
		repo="${PLUGIN_REPOS[$plugin]}"
		target="$PLUGIN_DIR/$plugin"

		if [ -f "$target/main.js" ]; then
			info "  ⊙ $plugin (already installed, skipping)"
			((skipped++)) || true
			continue
		fi

		info "  ↓ $plugin from $repo"
		mkdir -p "$target"

		# Fetch latest release assets from GitHub API
		api_url="https://api.github.com/repos/$repo/releases/latest"
		assets=$(curl -sL "$api_url" | grep -o '"browser_download_url": "[^"]*\(main.js\|manifest.json\|styles.css\)"' | sed 's/.*: "\(.*\)"/\1/')

		for url in $assets; do
			fname=$(basename "$url")
			curl -sL -o "$target/$fname" "$url"
		done

		if [ -f "$target/main.js" ] && [ -f "$target/manifest.json" ]; then
			success "  ✓ $plugin installed"
			((installed++)) || true
		else
			warn "  ✗ $plugin — failed to download (install manually via Obsidian UI)"
			rm -rf "$target"
		fi
	done

	bold "\nPlugin installation: $installed installed, $skipped skipped"
	info "\nRemaining plugins (install via Obsidian UI > Community Plugins):"
	info "  P0: GitHub PR Autocomplete"
	info "  P1: Vault Inspector, Image auto upload, Panic BOT"
	info "  P2: BRAT, Dataview"
	info "\nAfter installing, reload plugins: obsidian command reload-plugins"

	success "Plugin directory: $PLUGIN_DIR"
}

# -----------------------------------------------------------------------------
# setup_structure — create vault folder structure
# -----------------------------------------------------------------------------
do_setup_structure() {
	bold "Setting up vault folder structure..."

	mkdir -p "$VAULT_DIR/.obsidian"
	mkdir -p "$VAULT_DIR/99_templates"
	mkdir -p "$VAULT_DIR/98_attachments/_generated"
	mkdir -p "$VAULT_DIR/00-meta"
	mkdir -p "$VAULT_DIR/01-projects"
	mkdir -p "$VAULT_DIR/02-notes"
	mkdir -p "$VAULT_DIR/03-areas"
	mkdir -p "$VAULT_DIR/04-resources"
	mkdir -p "$VAULT_DIR/05-public"

	# Create vault index if missing
	if [ ! -f "$VAULT_DIR/00-meta/index.md" ]; then
		cat >"$VAULT_DIR/00-meta/index.md" <<'EOF'
---
title: Vault Index
description: Map of Dream Vault content
---

# Vault Index

## Structure

- [[01-projects/]] — Project-specific notes
- [[02-notes/]] — Evergreen knowledge base
- [[03-areas/]] — Areas of responsibility
- [[04-resources/]] — Reference materials
- [[05-public/]] — Notes ready for publishing
- [[99_templates/]] — Note templates
- [[98_attachments/]] — Media and generated assets

## Recent

<!-- auto-generated links to recent notes -->

---
_Last updated: $(date +%Y-%m-%d)_
EOF
		info "Created vault/00-meta/index.md"
	fi

	info "Template files are in vault/99_templates/ — edit directly in Obsidian"
	success "Vault folder structure created at $VAULT_DIR"
}

# -----------------------------------------------------------------------------
# install — run all or specific install sub-command
# -----------------------------------------------------------------------------
do_install() {
	case "${1:-all}" in
	install-basic)
		do_install_basic
		;;
	install-skills)
		do_install_skills
		;;
	install-plugins)
		do_install_plugins
		;;
	setup_structure)
		do_setup_structure
		;;
	install-plugins)
		do_install_plugins
		;;
	all | "")
		do_install_basic
		echo ""
		do_install_skills
		echo ""
		do_install_plugins
		echo ""
		success "All installations complete."
		;;
	*)
		error "Unknown install sub-command: $1"
		echo ""
		usage
		exit 1
		;;
	esac
}

# -----------------------------------------------------------------------------
# publish — pre-publish checks + cloud sync
# -----------------------------------------------------------------------------
do_publish() {
	bold "Running pre-publish checks..."
	check_git || return 1
	check_rclone

	info "Checking vault structure..."
	if [ ! -d "$VAULT_DIR" ]; then
		error "Vault directory not found at $VAULT_DIR"
		return 1
	fi
	success "Vault directory found"

	info "Checking Git status..."
	cd "$PROJECT_ROOT"
	if git diff --quiet && [ -z "$(git status --porcelain)" ]; then
		info "No uncommitted changes — nothing to publish"
	else
		warn "Uncommitted changes detected. Commit before publishing:"
		git status --short
	fi

	info "Checking R2 configuration..."
	if [ ! -f "$CONFIG_FILE" ]; then
		warn "CONFIG.md not found — R2 credentials may not be configured"
	fi

	bold "Pre-publish checks complete."
	info "Run 'git push' to trigger GitHub Actions → R2 sync."
	info "Or manually run: aws s3 sync vault/ s3://<bucket>/vault --endpoint-url https://<endpoint> --delete"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
	if [ $# -eq 0 ]; then
		usage
		exit 0
	fi

	case "$1" in
	install)
		shift
		do_install "${1:-}"
		;;
	publish)
		do_publish
		;;
	help | --help | -h)
		usage
		;;
	*)
		error "Unknown command: $1"
		echo ""
		usage
		exit 1
		;;
	esac
}

main "$@"
