/**
 * Dream Vault — logging setup using LogTape.
 * Application-wide configuration; call `setupLogging()` once at entry point.
 */
import { configure, getConsoleSink } from "@logtape/logtape";
import { getPrettyFormatter } from "@logtape/pretty";

export async function setupLogging(level: string = "info") {
	await configure({
		sinks: {
			console: getConsoleSink({
				formatter: getPrettyFormatter(),
			}),
		},
		loggers: [
			{
				category: "dream-vault",
				lowestLevel: level as "debug" | "info" | "warning" | "error" | "fatal",
				sinks: ["console"],
			},
		],
	});
}
