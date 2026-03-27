#!/usr/bin/env npx tsx
import { spawn } from "node:child_process";
import ora from "ora";

// Everything before "--" is the prompt, everything after is passed to claude
const rawArgs = process.argv.slice(2);
const sepIdx = rawArgs.indexOf("--");
const prompt = sepIdx === -1 ? rawArgs.join(" ") : rawArgs.slice(0, sepIdx).join(" ");
const claudeFlags = sepIdx === -1 ? [] : rawArgs.slice(sepIdx + 1);

if (!prompt) {
  console.error("Usage: claude-runner <prompt> [-- <claude flags...>]");
  process.exit(1);
}

const proc = spawn(
  "claude",
  ["-p", prompt, "--verbose", "--output-format", "stream-json", ...claudeFlags],
  { stdio: ["ignore", "pipe", "pipe"] },
);

const spinner = ora({ text: "", stream: process.stderr }).start();
let finalResult = "";
let buffer = "";

proc.stdout.on("data", (chunk: Buffer) => {
  buffer += chunk.toString();
  const lines = buffer.split("\n");
  buffer = lines.pop()!;

  for (const line of lines) {
    if (!line.trim()) continue;
    try {
      const msg = JSON.parse(line);
      if (msg.type === "assistant") {
        const content = msg.message?.content ?? [];
        for (const block of content) {
          if (block.type === "text") {
            finalResult += block.text;
            const preview = finalResult.slice(-60).replace(/\n/g, " ");
            spinner.text = preview;
          } else if (block.type === "tool_use") {
            const detail = block.input?.command ?? block.input?.pattern ?? block.input?.file_path ?? "";
            const short = String(detail).split("\n")[0].slice(0, 60);
            spinner.text = short ? `[${block.name}] ${short}` : `[${block.name}]`;
          }
        }
      } else if (msg.type === "result") {
        finalResult = msg.result ?? finalResult;
      }
    } catch {
      // ignore malformed lines
    }
  }
});

proc.stderr.on("data", () => {});

proc.on("close", (code: number | null) => {
  spinner.stop();
  if (finalResult) {
    process.stdout.write(finalResult);
    if (!finalResult.endsWith("\n")) process.stdout.write("\n");
  }
  process.exit(code ?? 0);
});
