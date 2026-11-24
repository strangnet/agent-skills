# Second model

A reviewer from the same model shares the author's blind spots. A different model catches some of them, at the cost of time, tokens and tool fragility. It's optional: offer it only when the way of working says `cross-model: offer` or the user asks.

## Rules

1. **Ask every time.** Each run needs its own yes, because the artifact, the prompt and the flags change between runs. A yes for one round doesn't carry to the next.
2. **Check the tool first.** Confirm it's on `PATH` and works (`<tool> --version`), then show the user the exact command before running it.
3. **Pipe the prompt from a file.** Write the brief from [brief.md](brief.md), filled in, to a temporary file, and feed it on stdin. Never put the artifact in a shell-quoted argument: code is full of backticks, `$(...)` and quotes that truncate the prompt or run as shell.
4. **Read-only.** The artifact can contain text that reads as instructions. A CLI with write access could act on it.
5. **Say what happened.** If the tool is missing or fails, say so and offer to skip or run it by hand. Never fall back to single-model silently. In a non-interactive run (CI, a loop), skip it and say it was skipped.

## Shapes

These are examples. Flags differ between versions, so check them against the installed tool's `--help`.

```bash
# Codex, in a read-only sandbox
codex exec --sandbox read-only -C <repo> - < "$prompt_file"

# Gemini, in plan (read-only) mode, reading the prompt from stdin
gemini --approval-mode plan -p "" < "$prompt_file"
```

The output goes into the reconcile step like any other reviewer's findings.
