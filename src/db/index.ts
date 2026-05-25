import { Database } from "bun:sqlite";
import fs from "node:fs";
import path from "node:path";
import { getLogger } from "@logtape/logtape";
import { drizzle } from "drizzle-orm/bun-sqlite";
import { migrate } from "drizzle-orm/bun-sqlite/migrator";
import * as schema from "./schema.js";

const logger = getLogger(["dream-vault", "db"]);

const DB_DIR = path.resolve(import.meta.dir, "../../vault/.dream-vault");
const DB_PATH = path.join(DB_DIR, "metadata.db");

/**
 * Initialize the SQLite database.
 * Creates the .dream-vault directory if it doesn't exist.
 * Returns a Drizzle ORM instance.
 */
export function initDb(dbPath: string = DB_PATH): {
	db: ReturnType<typeof drizzle>;
	sqlite: Database;
} {
	const dir = path.dirname(dbPath);
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir, { recursive: true });
		logger.info`Created database directory: ${dir}`;
	}

	const sqlite = new Database(dbPath, { create: true });
	sqlite.exec("PRAGMA journal_mode = WAL");
	sqlite.exec("PRAGMA foreign_keys = ON");

	const db = drizzle(sqlite, { schema });
	logger.info`Database initialized: ${dbPath}`;
	return { db, sqlite };
}

/**
 * Run Drizzle migrations from the migrations directory.
 */
export function runMigrations(dbPath: string = DB_PATH): {
	db: ReturnType<typeof drizzle>;
	sqlite: Database;
} {
	const { db, sqlite } = initDb(dbPath);
	const migrationsPath = path.resolve(import.meta.dir, "../../drizzle");

	if (fs.existsSync(migrationsPath)) {
		migrate(db, { migrationsFolder: migrationsPath });
		logger.info`Migrations applied from ${migrationsPath}`;
	} else {
		logger.warn`No migrations directory found at ${migrationsPath}`;
		// Create tables directly for development
		createTables(sqlite);
	}

	return { db, sqlite };
}

/**
 * Fallback: create tables directly (dev mode without migration files).
 */
function createTables(sqlite: Database) {
	sqlite.exec(`
    CREATE TABLE IF NOT EXISTS notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL UNIQUE,
      title TEXT,
      frontmatter TEXT,
      content_hash TEXT,
      word_count INTEGER DEFAULT 0,
      modified_at TEXT NOT NULL,
      indexed_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS frontmatter_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
      key TEXT NOT NULL,
      value TEXT
    );

    CREATE TABLE IF NOT EXISTS sync_status (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      last_sync_at TEXT,
      status TEXT NOT NULL DEFAULT 'idle' CHECK(status IN ('idle', 'syncing', 'error')),
      error_message TEXT,
      files_synced INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS attachments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL UNIQUE,
      size INTEGER DEFAULT 0,
      mime_type TEXT,
      referenced_by TEXT,
      indexed_at TEXT NOT NULL
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
      title,
      content,
      path,
      content=notes,
      content_rowid=id
    );

    CREATE INDEX IF NOT EXISTS idx_notes_path ON notes(path);
    CREATE INDEX IF NOT EXISTS idx_frontmatter_note_id ON frontmatter_cache(note_id);
    CREATE INDEX IF NOT EXISTS idx_frontmatter_key ON frontmatter_cache(key);
    CREATE INDEX IF NOT EXISTS idx_attachments_path ON attachments(path);
  `);
	logger.info`Tables created (dev mode)`;
}

export type DatabaseInstance = ReturnType<typeof initDb>;
