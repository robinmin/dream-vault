import { z } from "zod";

/**
 * Zod schemas mirroring DB tables for validation at system boundaries.
 */

export const noteSchema = z.object({
	path: z.string().min(1),
	title: z.string().optional(),
	frontmatter: z.string().optional(),
	contentHash: z.string().optional(),
	wordCount: z.number().int().nonnegative().default(0),
	modifiedAt: z.string().datetime(),
	indexedAt: z.string().datetime(),
});

export const frontmatterEntrySchema = z.object({
	noteId: z.number().int().positive(),
	key: z.string().min(1),
	value: z.string().optional(),
});

export const syncStatusSchema = z.object({
	status: z.enum(["idle", "syncing", "error"]).default("idle"),
	lastSyncAt: z.string().datetime().optional(),
	errorMessage: z.string().optional(),
	filesSynced: z.number().int().nonnegative().default(0),
});

export const attachmentSchema = z.object({
	path: z.string().min(1),
	size: z.number().int().nonnegative().default(0),
	mimeType: z.string().optional(),
	referencedBy: z.string().optional(), // JSON array
	indexedAt: z.string().datetime(),
});

/**
 * SEO frontmatter schema — validates public note metadata per PRD §7.1.
 */
export const seoFrontmatterSchema = z.object({
	title: z.string().max(60, "Title should be under 60 characters"),
	description: z.string().max(160, "Description should be under 160 characters"),
	keywords: z.array(z.string()).optional(),
	publish: z.boolean().default(false),
	date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be YYYY-MM-DD"),
	author: z.string().optional(),
	image: z.string().optional(),
	og_type: z.enum(["article", "website", "profile"]).default("article"),
});

export type Note = z.infer<typeof noteSchema>;
export type FrontmatterEntry = z.infer<typeof frontmatterEntrySchema>;
export type SyncStatus = z.infer<typeof syncStatusSchema>;
export type Attachment = z.infer<typeof attachmentSchema>;
export type SeoFrontmatter = z.infer<typeof seoFrontmatterSchema>;
