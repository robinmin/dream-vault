import fs from "node:fs";
import path from "node:path";
import type { BetterSQLite3Database } from "drizzle-orm/better-sqlite3";

/* eslint-disable */

interface HealthCheckResult {
	check: string;
	status: "pass" | "warn" | "fail";
	message: string;
}

interface HealthOptions {
	fix?: boolean;
}

/**
 * Run all vault health checks.
 */
export async function runHealthChecks(
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	_db: BetterSQLite3Database<any>,
	vaultDir: string,
	_options: HealthOptions,
): Promise<HealthCheckResult[]> {
	const results: HealthCheckResult[] = [];

	results.push(...checkOrphanedAttachments(vaultDir));
	results.push(...checkMissingFrontmatter(vaultDir));
	results.push(...checkBrokenInternalLinks(vaultDir));
	results.push(...checkEmptyDirectories(vaultDir));

	return results;
}

/**
 * Find attachments in 98_attachments/ that aren't referenced by any note.
 */
function checkOrphanedAttachments(vaultDir: string): HealthCheckResult[] {
	const results: HealthCheckResult[] = [];
	const attachDir = path.join(vaultDir, "98_attachments");

	if (!fs.existsSync(attachDir)) return results;

	const attachments = new Set<string>();
	collectFiles(attachDir, attachments);

	const referenced = new Set<string>();
	const mdFiles = collectMarkdownFiles(vaultDir);

	for (const mdFile of mdFiles) {
		const content = fs.readFileSync(mdFile, "utf-8");
		const refs = content.match(/!\[[^\]]*\]\([^)]+\)/g) || [];
		for (const ref of refs) {
			const match = ref.match(/\]\(([^)]+)\)/);
			if (match) {
				const refPath = match[1].replace(/^\.\//, "");
				referenced.add(refPath);
			}
		}
		// Also check wikilinks with ! prefix (Obsidian embeds)
		const embeds = content.match(/!\[\[([^\]]+)\]\]/g) || [];
		for (const embed of embeds) {
			const match = embed.match(/!\[\[([^\]]+)\]\]/);
			if (match) referenced.add(match[1]);
		}
	}

	const orphans: string[] = [];
	for (const att of attachments) {
		const relPath = path.relative(vaultDir, att);
		const isReferenced = [...referenced].some(
			(ref) => relPath.endsWith(ref) || ref.endsWith(path.basename(relPath)),
		);
		if (!isReferenced) orphans.push(relPath);
	}

	if (orphans.length === 0) {
		results.push({
			check: "Orphaned Attachments",
			status: "pass",
			message: "No orphaned attachments",
		});
	} else {
		results.push({
			check: "Orphaned Attachments",
			status: "warn",
			message: `${orphans.length} orphaned: ${orphans.slice(0, 3).join(", ")}${orphans.length > 3 ? "..." : ""}`,
		});
	}

	return results;
}

/**
 * Check public notes for required frontmatter (title, date).
 */
function checkMissingFrontmatter(vaultDir: string): HealthCheckResult[] {
	const results: HealthCheckResult[] = [];
	const publicDir = path.join(vaultDir, "05-public");

	if (!fs.existsSync(publicDir)) {
		results.push({
			check: "Public Frontmatter",
			status: "pass",
			message: "No public notes directory",
		});
		return results;
	}

	const mdFiles = collectMarkdownFiles(publicDir);
	let missing = 0;

	for (const file of mdFiles) {
		const content = fs.readFileSync(file, "utf-8");
		if (!content.startsWith("---")) continue;
		const fmEnd = content.indexOf("---", 3);
		if (fmEnd === -1) continue;

		const frontmatter = content.slice(3, fmEnd);
		const hasTitle = /^title:/m.test(frontmatter);
		const hasDate = /^date:/m.test(frontmatter);

		if (!hasTitle || !hasDate) missing++;
	}

	if (missing === 0) {
		results.push({
			check: "Public Frontmatter",
			status: "pass",
			message: "All public notes have required frontmatter",
		});
	} else {
		results.push({
			check: "Public Frontmatter",
			status: "fail",
			message: `${missing} public note(s) missing title or date`,
		});
	}

	return results;
}

/**
 * Check for broken internal wikilinks [[...]] that don't resolve to files.
 */
function checkBrokenInternalLinks(vaultDir: string): HealthCheckResult[] {
	const results: HealthCheckResult[] = [];
	const mdFiles = collectMarkdownFiles(vaultDir);
	const allFiles = new Set<string>();

	for (const file of mdFiles) {
		allFiles.add(path.relative(vaultDir, file).replace(/\.md$/, ""));
	}

	let broken = 0;
	for (const file of mdFiles) {
		const content = fs.readFileSync(file, "utf-8");
		const links = content.match(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/g) || [];
		for (const link of links) {
			const target = link.match(/\[\[([^\]|]+)/)?.[1];
			if (!target || target.startsWith("http")) continue;
			if (!allFiles.has(target) && !allFiles.has(target.toLowerCase())) {
				broken++;
			}
		}
	}

	if (broken === 0) {
		results.push({ check: "Internal Links", status: "pass", message: "No broken internal links" });
	} else {
		results.push({
			check: "Internal Links",
			status: "fail",
			message: `${broken} broken internal link(s)`,
		});
	}

	return results;
}

/**
 * Check for empty content directories (excluding templates and meta).
 */
function checkEmptyDirectories(vaultDir: string): HealthCheckResult[] {
	const results: HealthCheckResult[] = [];
	const contentDirs = ["01-projects", "02-notes", "03-areas", "04-resources", "05-public"];

	const emptyDirs: string[] = [];
	for (const dir of contentDirs) {
		const fullPath = path.join(vaultDir, dir);
		if (!fs.existsSync(fullPath)) continue;
		const files = fs.readdirSync(fullPath).filter((f) => f !== ".gitkeep");
		if (files.length === 0) emptyDirs.push(dir);
	}

	if (emptyDirs.length === 0) {
		results.push({
			check: "Empty Directories",
			status: "pass",
			message: "All content directories have files",
		});
	} else {
		results.push({
			check: "Empty Directories",
			status: "warn",
			message: `Empty: ${emptyDirs.join(", ")}`,
		});
	}

	return results;
}

// ─── Helpers ────────────────────────────────────────────────────────────

function collectFiles(dir: string, result: Set<string>): void {
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const fullPath = path.join(dir, entry.name);
		if (entry.isDirectory()) {
			collectFiles(fullPath, result);
		} else if (entry.isFile() && !entry.name.startsWith(".")) {
			result.add(fullPath);
		}
	}
}

function collectMarkdownFiles(dir: string): string[] {
	const results: string[] = [];
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const fullPath = path.join(dir, entry.name);
		if (entry.isDirectory() && entry.name !== ".obsidian" && entry.name !== ".dream-vault") {
			results.push(...collectMarkdownFiles(fullPath));
		} else if (entry.isFile() && entry.name.endsWith(".md")) {
			results.push(fullPath);
		}
	}
	return results;
}
