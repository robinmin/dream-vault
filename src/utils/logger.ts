/**
 * Dream Vault — logging setup using LogTape.
 * Default: file sink to logs/dream-vault.log, no console output.
 * Call `setupLogging()` once at entry point.
 */
import { createWriteStream, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { Writable } from "node:stream";
import { configure, defaultTextFormatter, getStreamSink } from "@logtape/logtape";

const LOG_PATH = resolve(import.meta.dir, "../../logs/dream-vault.log");

export async function setupLogging(level: string = "info") {
	mkdirSync(dirname(LOG_PATH), { recursive: true });

	const fileStream = createWriteStream(LOG_PATH, { flags: "a" });
	const webStream = Writable.toWeb(fileStream);

	const fileSink = getStreamSink(webStream, {
		formatter: defaultTextFormatter,
	});

	await configure({
		sinks: { file: fileSink },
		loggers: [
			{
				category: "dream-vault",
				lowestLevel: level as "debug" | "info" | "warning" | "error" | "fatal",
				sinks: ["file"],
			},
			{
				category: "logtape",
				lowestLevel: "warning",
				sinks: ["file"],
			},
		],
	});
}
