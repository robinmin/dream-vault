#!/usr/bin/env bun
import { Command } from "commander";
import { runMigrations } from "../db/index.js";
import { setupLogging } from "../utils/logger.js";
import { runHealthChecks } from "./health.js";
import { runPublishChecks } from "./publish.js";
import { runStatus } from "./status.js";

const VAULT_DIR = import.meta.dir.replace(/\/src\/cli$/, "/vault");

export const program = new Command()
	.name("dream-vault")
	.description("Dream Vault — Obsidian vault management CLI")
	.version("0.1.0")
	.option("--verbose", "Enable debug logging", false);

// ─── health ────────────────────────────────────────────────────────────
program
	.command("health")
	.description("Run vault health checks (orphaned attachments, broken links, missing frontmatter)")
	.option("--fix", "Auto-fix issues where possible", false)
	.action(async (opts) => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		const { db } = runMigrations();
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

// ─── status ────────────────────────────────────────────────────────────
program
	.command("status")
	.description("Show vault directory and database status")
	.action(async () => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		const { dirs, db } = runStatus();

		console.log("\nVault Directory Status:");
		for (const d of dirs) {
			const icon = d.exists ? "✓" : "✗";
			const count = d.exists ? ` (${d.fileCount} files)` : "";
			console.log(`  ${icon} ${d.directory}/${count}`);
		}
		console.log(`\n  ${db.exists ? "✓" : "✗"} .dream-vault/metadata.db`);
	});

// ─── publish ───────────────────────────────────────────────────────────
program
	.command("publish")
	.description("Run pre-publish checks (vault structure, git status, config)")
	.action(async () => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		const results = runPublishChecks();

		console.log("\nPre-Publish Checks:");
		for (const result of results) {
			const icon = result.status === "pass" ? "✓" : result.status === "warn" ? "⚠" : "✗";
			console.log(`  ${icon} ${result.check}: ${result.message}`);
		}

		const failures = results.filter((r) => r.status === "fail").length;
		if (failures > 0) {
			console.error(`\n${failures} check(s) failed — resolve before pushing`);
			process.exit(1);
		}
		console.log("\nReady to publish. Push to main to trigger GitHub Actions → R2 sync.");
	});

// ─── db:init ────────────────────────────────────────────────────────────
program
	.command("db:init")
	.description("Initialize the SQLite metadata database")
	.action(async () => {
		await setupLogging(program.opts().verbose ? "debug" : "info");
		runMigrations();
		console.log("Database initialized successfully");
	});

program.parse();
