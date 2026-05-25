import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { defineConfig } from "drizzle-kit";

const dbPath = "./vault/.dream-vault/metadata.db";
mkdirSync(dirname(dbPath), { recursive: true });

export default defineConfig({
	schema: "./src/db/schema.ts",
	out: "./drizzle",
	dialect: "sqlite",
	dbCredentials: {
		url: dbPath,
	},
});
