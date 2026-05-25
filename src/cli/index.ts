import fs from "node:fs";
import path from "node:path";
import { Command } from "commander";
import { runMigrations } from "../db/index.js";
import { setupLogging } from "../utils/logger.js";

const logger = await import("@logtape/logtape").then((m) => m.getLogger(["dream-vault", "cli"]));

const PROJECT_ROOT = path.resolve(import.meta.dir, "../../");
const VAULT_DIR = path.join(PROJECT_ROOT, "vault");
const SCRIPT_PATH = path.join(PROJECT_ROOT, "scripts/dream-vault.sh");

export const program = new Command()
	.name("dream-vault")
	.description("Dream Vault — Obsidian vault management CLI")
	.version("0.1.0")
	.option("--verbose", "Enable debug logging", false);

// ─── install ────────────────────────────────────────────────────────────
program
	.command("install")
	.description("Install dependencies and configure the vault")
	.option("--basic", "Check core tooling only")
	.option("--skills", "Install Claude Code skills")
	.option("--plugins", "Install Obsidian community plugins")
	.option("--structure", "Create vault folder structure")
	.action(async (opts) => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		logger.info`Running install command`;

		if (opts.basic || (!opts.skills && !opts.plugins && !opts.structure)) {
			runShell("install install-basic");
		}
		if (opts.skills || (!opts.basic && !opts.plugins && !opts.structure)) {
			runShell("install install-skills");
		}
		if (opts.plugins || (!opts.basic && !opts.skills && !opts.structure)) {
			runShell("install install-plugins");
		}
		if (opts.structure || (!opts.basic && !opts.skills && !opts.plugins)) {
			runShell("install setup_structure");
		}
	});

// ─── publish ────────────────────────────────────────────────────────────
program
	.command("publish")
	.description("Run pre-publish checks and sync to cloud")
	.action(async () => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		logger.info`Running publish checks`;
		runShell("publish");
	});

// ─── status ─────────────────────────────────────────────────────────────
program
	.command("status")
	.description("Show vault status summary")
	.action(async () => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		logger.info`Checking vault status`;

		const dirs = [
			"00-meta",
			"01-projects",
			"02-notes",
			"03-areas",
			"04-resources",
			"05-public",
			"98_attachments",
			"99_templates",
		];
		console.log("\nVault Directory Status:");
		for (const dir of dirs) {
			const fullPath = path.join(VAULT_DIR, dir);
			const exists = fs.existsSync(fullPath);
			const icon = exists ? "✓" : "✗";
			console.log(`  ${icon} ${dir}/`);
		}

		// Check DB
		const dbPath = path.join(VAULT_DIR, ".dream-vault/metadata.db");
		console.log(`\n  ${fs.existsSync(dbPath) ? "✓" : "✗"} .dream-vault/metadata.db`);
	});

// ─── health ─────────────────────────────────────────────────────────────
program
	.command("health")
	.description("Run vault health checks (orphaned attachments, broken links, missing frontmatter)")
	.option("--fix", "Auto-fix issues where possible", false)
	.action(async (opts) => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		logger.info`Running health checks (fix=${opts.fix})`;

		const { db } = runMigrations();
		// Import health check module
		const { runHealthChecks } = await import("./health.js");
		const results = await runHealthChecks(db, VAULT_DIR, { fix: opts.fix });

		console.log("\nHealth Check Results:");
		for (const result of results) {
			const icon = result.status === "pass" ? "✓" : result.status === "warn" ? "⚠" : "✗";
			console.log(`  ${icon} ${result.check}: ${result.message}`);
		}

		const failures = results.filter((r) => r.status === "fail").length;
		if (failures > 0) {
			console.error(`\n${failures} check(s) failed`);
			process.exit(1);
		}
		console.log("\nAll checks passed");
	});

// ─── db ─────────────────────────────────────────────────────────────────
program
	.command("db:init")
	.description("Initialize the SQLite metadata database")
	.action(async () => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		runMigrations();
		logger.info`Database initialized`;
		console.log("Database initialized successfully");
	});

// ─── helpers ────────────────────────────────────────────────────────────
function runShell(subcommand: string) {
	if (!fs.existsSync(SCRIPT_PATH)) {
		logger.error`dream-vault.sh not found at ${SCRIPT_PATH}`;
		process.exit(1);
	}
	logger.info`Delegating to shell: ${subcommand}`;
	const proc = Bun.spawn(["bash", SCRIPT_PATH, ...subcommand.split(" ")], {
		stdout: "inherit",
		stderr: "inherit",
	});
	const exitCode = proc.exitCode;
	if (exitCode !== 0) {
		logger.error`Shell command failed with exit code ${exitCode}`;
		process.exit(exitCode ?? 1);
	}
}
