#!/usr/bin/env bash
# =============================================================================
# dream-vault.sh — Dream Vault management CLI
# Usage: ./dream-vault.sh <command> [options]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_DIR="$PROJECT_ROOT/vault"

# -----------------------------------------------------------------------------
# Color codes
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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
	echo "    setup_secrets    Set GitHub Actions secrets from .env"
	echo "  list             Show all installed resources (tooling, skills, plugins, vault)"
	echo "  help             Show this help message"
	echo ""
	echo "Vault operations (publish, health, status, db:init) → bun src/cli/bin.ts <command>"
	echo ""
	echo "Examples:"
	echo "  $0 install install-basic"
	echo "  $0 install install-skills"
	echo "  $0 install install-plugins"
	echo "  $0 install setup_structure"
	echo "  $0 install setup_secrets"
	echo "  $0 install           # Run all install sub-commands"
	echo "  $0 list"
	echo "  $0 help"
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
		success "Obsidian CLI found: $(obsidian version 2>/dev/null || echo 'unknown version')"
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

	info "Checking for GitHub CLI..."
	if command -v gh &>/dev/null; then
		success "GitHub CLI found: $(gh --version 2>/dev/null | head -1)"
	else
		warn "GitHub CLI not found. Run: brew install gh"
	fi

	info "Checking for Wrangler (Cloudflare)..."
	if command -v wrangler &>/dev/null; then
		success "Wrangler found: $(wrangler --version 2>/dev/null)"
	else
		warn "Wrangler not found. Run: npm install -g wrangler"
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

# Plugin registry: parallel arrays (bash 3.2 compat — no declare -A)
PLUGIN_NAMES=(
	templater-obsidian
	quickadd
	obsidian-tasks-plugin
	obsidian-advanced-uri
	obsidian-metatable
	obsidian-local-rest-api
	remotely-save
)
PLUGIN_REPOS=(
	SilentVoid13/Templater
	chhoumann/quickadd
	obsidian-tasks-group/obsidian-tasks
	Vinzent03/obsidian-advanced-uri
	joschahenningsen/obsidian-metatable
	adamgibbons/obsidian-local-rest-api
	remotely-save/remotely-save
)

do_install_plugins() {
	bold "Installing Obsidian community plugins..."

	PLUGIN_DIR="$VAULT_DIR/.obsidian/plugins"
	mkdir -p "$PLUGIN_DIR"

	installed=0
	skipped=0

	for i in "${!PLUGIN_NAMES[@]}"; do
		plugin="${PLUGIN_NAMES[$i]}"
		repo="${PLUGIN_REPOS[$i]}"
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
# -----------------------------------------------------------------------------
# setup_secrets — load .env and set GitHub Actions secrets via gh CLI
# -----------------------------------------------------------------------------
do_setup_secrets() {
	bold "Configuring GitHub Actions secrets..."

	ENV_FILE="$PROJECT_ROOT/.env"
	if [ ! -f "$ENV_FILE" ]; then
		warn ".env not found — skipping secrets setup."
		info "Create .env from .env.example and fill in your Cloudflare R2 credentials."
		return 0
	fi

	if ! command -v gh &>/dev/null; then
		error "GitHub CLI (gh) not found. Install with: brew install gh"
		return 1
	fi

	# Verify gh is authenticated
	if ! gh auth status &>/dev/null; then
		error "gh not authenticated. Run: gh auth login"
		return 1
	fi

	# Verify git remote exists
	if ! git remote get-url origin &>/dev/null; then
		error "No git remote 'origin' found. Add one first:"
		echo "  git remote add origin https://github.com/<you>/dream-vault.git"
		return 1
	fi

	# Load .env (skip comments and blank lines)
	set -a
	# shellcheck disable=SC1090
	while IFS='=' read -r key value; do
		case "$key" in
		'' | \#*) continue ;;
		esac
		export "$key=$value"
	done < <(grep -vE '^\s*(#|$)' "$ENV_FILE")
	set +a

	SECRETS=(
		CLOUDFLARE_R2_ACCOUNT_ID
		CLOUDFLARE_R2_BUCKET_NAME
		CLOUDFLARE_R2_ACCESS_KEY_ID
		CLOUDFLARE_R2_SECRET_ACCESS_KEY
	)

	set=0
	skipped=0
	failed=0
	for secret in "${SECRETS[@]}"; do
		value=$(eval echo "\$$secret" 2>/dev/null || true)
		if [ -z "$value" ]; then
			warn "  $secret — empty or not defined in .env, skipping"
			((skipped++)) || true
			continue
		fi
		if echo "$value" | gh secret set "$secret" 2>&1; then
			success "  $secret"
			((set++)) || true
		else
			error "  $secret — failed to set"
			((failed++)) || true
		fi
	done

	bold "\nSecrets: $set set, $skipped skipped, $failed failed"
	if [ "$failed" -gt 0 ]; then
		error "Some secrets failed to set. See errors above."
		return 1
	fi
	success "GitHub Actions secrets configured."
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
	setup_secrets)
		do_setup_secrets
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
# list — show all installed resources
# -----------------------------------------------------------------------------
do_list() {
	bold "Dream Vault — Installed Resources"
	echo ""

	# Binaries
	bold "Binaries"
	for cmd in brew obsidian rclone gh wrangler node bun git; do
		if command -v "$cmd" &>/dev/null; then
			if [ "$cmd" = "obsidian" ]; then
				ver=$(obsidian version 2>&1 | head -1)
			else
				ver=$("$cmd" --version 2>&1 | head -1)
			fi
			success "  $cmd: $ver"
		else
			warn "  $cmd: not installed"
		fi
	done
	echo ""

	# Obsidian plugins
	bold "Obsidian Plugins"
	PLUGIN_DIR="$VAULT_DIR/.obsidian/plugins"
	if [ -d "$PLUGIN_DIR" ]; then
		count=0
		for dir in "$PLUGIN_DIR"/*/; do
			[ -d "$dir" ] || continue
			name=$(basename "$dir")
			if [ -f "$dir/main.js" ]; then
				# Try to read version from manifest.json
				version=""
				if [ -f "$dir/manifest.json" ]; then
					version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$dir/manifest.json" | head -1 | sed 's/.*: *"\([^"]*\)"/\1/')
				fi
				if [ -n "$version" ]; then
					success "  $name ($version)"
				else
					success "  $name"
				fi
			else
				warn "  $name (incomplete — no main.js)"
			fi
			((count++)) || true
		done
		info "  $count plugin(s) in $PLUGIN_DIR"
	else
		warn "  No plugins directory found"
	fi
	echo ""

	# Claude Code skills
	bold "Claude Code Skills"
	SKILLS_DIR="$PROJECT_ROOT/.claude/skills"
	if [ -d "$SKILLS_DIR" ]; then
		count=0
		for skill in "$SKILLS_DIR"/*/; do
			[ -d "$skill" ] || continue
			name=$(basename "$skill")
			if [ -f "$skill/SKILL.md" ]; then
				success "  $name"
			else
				warn "  $name (no SKILL.md)"
			fi
			((count++)) || true
		done
		info "  $count skill(s) in $SKILLS_DIR"
	else
		warn "  No skills directory found"
	fi
	echo ""

	# Vault structure
	bold "Vault Structure"
	if [ -d "$VAULT_DIR" ]; then
		for folder in .obsidian 00-meta 01-projects 02-notes 03-areas 04-resources 05-public 98_attachments 99_templates; do
			if [ -d "$VAULT_DIR/$folder" ]; then
				file_count=$(find "$VAULT_DIR/$folder" -type f | wc -l | tr -d ' ')
				success "  $folder/ ($file_count files)"
			else
				warn "  $folder/ (missing)"
			fi
		done
	else
		error "  Vault directory not found at $VAULT_DIR"
	fi
	echo ""

	# Git status
	bold "Git Status"
	cd "$PROJECT_ROOT"
	branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
	info "  Branch: $branch"
	changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
	if [ "$changes" -eq 0 ]; then
		success "  Working tree clean"
	else
		warn "  $changes uncommitted change(s)"
	fi
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
	list)
		do_list
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
