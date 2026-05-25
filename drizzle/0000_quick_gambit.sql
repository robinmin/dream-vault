CREATE TABLE `attachments` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`path` text NOT NULL,
	`size` integer DEFAULT 0,
	`mime_type` text,
	`referenced_by` text,
	`indexed_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `attachments_path_unique` ON `attachments` (`path`);--> statement-breakpoint
CREATE TABLE `frontmatter_cache` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`note_id` integer NOT NULL,
	`key` text NOT NULL,
	`value` text,
	FOREIGN KEY (`note_id`) REFERENCES `notes`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `notes` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`path` text NOT NULL,
	`title` text,
	`frontmatter` text,
	`content_hash` text,
	`word_count` integer DEFAULT 0,
	`modified_at` text NOT NULL,
	`indexed_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `notes_path_unique` ON `notes` (`path`);--> statement-breakpoint
CREATE TABLE `notes_fts` (
	`rowid` integer PRIMARY KEY NOT NULL,
	`title` text,
	`content` text,
	`path` text
);
--> statement-breakpoint
CREATE TABLE `sync_status` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`last_sync_at` text,
	`status` text DEFAULT 'idle' NOT NULL,
	`error_message` text,
	`files_synced` integer DEFAULT 0
);
