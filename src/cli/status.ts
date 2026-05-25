import fs from "node:fs";
import path from "node:path";

const PROJECT_ROOT = path.resolve(import.meta.dir, "../../");
const VAULT_DIR = path.join(PROJECT_ROOT, "vault");

export interface StatusResult {
	directory: string;
	exists: boolean;
	fileCount: number;
}

export interface DbStatus {
	exists: boolean;
	path: string;
}

export function runStatus(): { dirs: StatusResult[]; db: DbStatus } {
	const dirs = [
		"00-meta",
		"01-projects",
		"02-notes",
		"03-areas",
		"04-resources",
		"05-public",
		"98_attachments",
		"99_templates",
	].map((dir) => {
		const fullPath = path.join(VAULT_DIR, dir);
		const exists = fs.existsSync(fullPath);
		let fileCount = 0;
		if (exists) {
			fileCount = countFiles(fullPath);
		}
		return { directory: dir, exists, fileCount };
	});

	const dbPath = path.join(VAULT_DIR, ".dream-vault/metadata.db");
	const db: DbStatus = { exists: fs.existsSync(dbPath), path: dbPath };

	return { dirs, db };
}

function countFiles(dir: string): number {
	let count = 0;
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const fullPath = path.join(dir, entry.name);
		if (entry.isDirectory()) {
			count += countFiles(fullPath);
		} else {
			count++;
		}
	}
	return count;
}
