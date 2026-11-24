# strangnet agent skills

> **Scope:** this file is for agents working on this repository. It is not a template for other projects; the reusable parts are the skills in `skills/`. For what each skill does and how users install them, see `README.md`.

## Layout

- `skills/<skill>/SKILL.md`: one folder per skill, with its own `references/`. Keep the layout flat, with no category folders: several harnesses only discover skills in direct subfolders of `skills/`.
- `references/<set>/`: shared reference sets (for example `languages/`), vendored into the skills that opt in.
- `agents/`: Claude Code subagents (`code-reviewer`, `doubter`). Other harnesses don't load them.
- `evals/plugin/`: behavioural evals for `claude plugin eval`.
- Manifests: `.claude-plugin/plugin.json` (source of truth; Claude Code and Copilot read it), `.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`.

## Rules

- **Skills are self-contained.** A skill must work when installed alone (skills.sh copies single folders). Never link from a skill to a file outside its own folder. Edit shared reference files only under the root `references/`, then run `scripts/sync-references.sh`.
- **Skills are harness-neutral.** Write for Claude Code, Codex, Copilot, pi and skills.sh installs alike. A skill that uses an agent from `agents/` must say what to do when agents aren't available (a fresh subagent) and when subagents aren't available either (say so, don't fake it). See `doubt` for the pattern.
- **Frontmatter:** `name` matches the folder; `description` says what the skill does, then when to use it ("Use when ..."). Skills the user should start by name only get `disable-model-invocation: true` (currently `shape` and `constraints`), and the README tells users how to start them.
- **Keep `SKILL.md` short.** Move detail into `references/` that the skill reads only when needed.
- **Adding, renaming or removing a skill** also means updating: the Skills table in `README.md` (name linked to its `SKILL.md`), "Where to start" if it changes a path, eval cases under `evals/plugin/` and its README table, and Credits if the skill derives from someone else's work. Manifests need no change: every harness finds skills in `skills/`.
- **Install instructions** live only in the Install section of `README.md`. Don't repeat them elsewhere; link to it.
- **Versions:** every manifest carries the same version. Releases follow the Releasing section of `README.md`. Don't bump versions in feature PRs unless asked.

## Checks

Run these before calling a change done (CI runs the first three):

```bash
scripts/sync-references.sh --check   # vendored references match references/
scripts/validate-versions.sh         # all manifests share one version
scripts/test-floor-guard.sh          # constraints skill's floor guard
claude plugin validate .             # manifests and skills load
```

Evals cost money and time; run them only when asked or when a skill's behaviour changed. See `evals/plugin/README.md`.

## Writing style

Plain, direct prose in skills and docs. Short sentences, active voice, concrete examples. Use British or American spelling consistently within a file.
