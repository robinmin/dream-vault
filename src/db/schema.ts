import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

/**
 * Notes — indexed vault markdown files.
 * One row per .md file in vault/.
 */
export const notes = sqliteTable("notes", {
	id: integer("id").primaryKey({ autoIncrement: true }),
	path: text("path").notNull().unique(),
	title: text("title"),
	frontmatter: text("frontmatter"), // raw YAML string
	contentHash: text("content_hash"), // SHA-256 of file content
	wordCount: integer("word_count").default(0),
	modifiedAt: text("modified_at").notNull(), // ISO 8601
	indexedAt: text("indexed_at").notNull(), // when we last indexed this file
});

/**
 * Frontmatter cache — parsed key-value pairs from YAML frontmatter.
 * Enables querying by any frontmatter field without re-parsing.
 */
export const frontmatterCache = sqliteTable("frontmatter_cache", {
	id: integer("id").primaryKey({ autoIncrement: true }),
	noteId: integer("note_id")
		.notNull()
		.references(() => notes.id, { onDelete: "cascade" }),
	key: text("key").notNull(),
	value: text("value"), // JSON-encoded value (string, number, array, object)
});

/**
 * Sync status — tracks R2 sync state.
 * Single-row table (id=1).
 */
export const syncStatus = sqliteTable("sync_status", {
	id: integer("id").primaryKey({ autoIncrement: true }),
	lastSyncAt: text("last_sync_at"),
	status: text("status", { enum: ["idle", "syncing", "error"] })
		.notNull()
		.default("idle"),
	errorMessage: text("error_message"),
	filesSynced: integer("files_synced").default(0),
});

/**
 * Attachments — tracked media files in vault/98_attachments/.
 */
export const attachments = sqliteTable("attachments", {
	id: integer("id").primaryKey({ autoIncrement: true }),
	path: text("path").notNull().unique(),
	size: integer("size").default(0), // bytes
	mimeType: text("mime_type"),
	referencedBy: text("referenced_by"), // JSON array of note paths that reference this file
	indexedAt: text("indexed_at").notNull(),
});

/**
 * Notes FTS — full-text search index using SQLite FTS5.
 */
export const notesFts = sqliteTable("notes_fts", {
	rowid: integer("rowid").primaryKey(),
	title: text("title"),
	content: text("content"),
	path: text("path"),
});
