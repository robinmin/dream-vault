import fs from "node:fs";
import path from "node:path";

const PROJECT_ROOT = path.resolve(import.meta.dir, "../../");
const VAULT_DIR = path.join(PROJECT_ROOT, "vault");
const CONFIG_FILE = path.join(PROJECT_ROOT, "CONFIG.md");

export interface PublishCheckResult {
	check: string;
	status: "pass" | "warn" | "fail";
	message: string;
}

export function runPublishChecks(): PublishCheckResult[] {
	const results: PublishCheckResult[] = [];

	// Vault directory exists
	if (!fs.existsSync(VAULT_DIR)) {
		results.push({
			check: "Vault Directory",
			status: "fail",
			message: `Not found at ${VAULT_DIR}`,
		});
		return results;
	}
	results.push({ check: "Vault Directory", status: "pass", message: "Found" });

	// Content directories present
	const contentDirs = [
		"00-meta",
		"01-projects",
		"02-notes",
		"03-areas",
		"04-resources",
		"05-public",
		"98_attachments",
		"99_templates",
	];
	const missing = contentDirs.filter((d) => !fs.existsSync(path.join(VAULT_DIR, d)));
	if (missing.length === 0) {
		results.push({
			check: "Vault Structure",
			status: "pass",
			message: "All content directories present",
		});
	} else {
		results.push({
			check: "Vault Structure",
			status: "warn",
			message: `Missing: ${missing.join(", ")}`,
		});
	}

	// Database exists
	const dbPath = path.join(VAULT_DIR, ".dream-vault/metadata.db");
	results.push({
		check: "Metadata DB",
		status: fs.existsSync(dbPath) ? "pass" : "warn",
		message: fs.existsSync(dbPath) ? "Found" : "Not found — run `bun src/cli/bin.ts db:init`",
	});

	// Config file exists
	results.push({
		check: "Config File",
		status: fs.existsSync(CONFIG_FILE) ? "pass" : "warn",
		message: fs.existsSync(CONFIG_FILE)
			? "CONFIG.md found"
			: "CONFIG.md not found — R2 credentials may not be configured",
	});

	// Git status
	try {
		const proc = Bun.spawnSync(["git", "status", "--porcelain"], { cwd: PROJECT_ROOT });
		const output = proc.stdout?.toString().trim() ?? "";
		if (output.length === 0) {
			results.push({ check: "Git Status", status: "pass", message: "Working tree clean" });
		} else {
			const count = output.split("\n").length;
			results.push({
				check: "Git Status",
				status: "warn",
				message: `${count} uncommitted change(s)`,
			});
		}
	} catch {
		results.push({ check: "Git Status", status: "fail", message: "Git not available" });
	}

	return results;
}
