# strangnet agent skills

Skills that make AI coding agents work the way a disciplined engineer does: test-first, in small reviewed steps, with the developer as the architect. The skills are language-agnostic, with worked examples for **Rust, Go, Python and TypeScript**.

## Install

Claude Code (2.1.275 or later):

```text
/plugin install strangnet-skills --marketplace strangnet/agent-skills
```

The repository also ships a Codex marketplace manifest in `.agents/plugins/marketplace.json`.

## Skills

| Skill | Use it to | Reach for it with |
|---|---|---|
| [`tdd-cycle`](skills/engineering/tdd-cycle/SKILL.md) | Drive code with tests in a gated red → green → refactor cycle. The agent stops for review after every phase. | "Let's TDD this", "next test", "make it pass" |
| [`acceptance-testing`](skills/engineering/acceptance-testing/SKILL.md) | Turn scenarios into acceptance tests built in three layers (scenario → DSL → protocol driver) that run against the real system. Gherkin is optional. | "Write acceptance tests for these scenarios", "ATDD" |
| [`test-review`](skills/engineering/test-review/SKILL.md) | Review tests against a quality checklist and report findings with `file:line` evidence, without editing anything. | "Review the tests before I merge" |

They fit together as two loops and a check:

1. `acceptance-testing` writes the outer test. Run test-first, it fails because the behaviour is missing.
2. `tdd-cycle` drives the implementation in small unit-tested steps until the acceptance test passes.
3. `test-review` checks both kinds of test before merge.

Each skill detects the project's language from its manifest (`Cargo.toml`, `go.mod`, `pyproject.toml`, `package.json`) and loads only that language's reference file. Other languages work too, using the same rules and that ecosystem's idioms.

## Repository layout

```text
skills/<category>/<skill>/     SKILL.md plus the skill's own references/
references/<set>/              shared reference sets, vendored into skills (see below)
scripts/sync-references.sh     copies shared sets into skills; --check detects drift
scripts/validate-versions.sh   checks that every plugin manifest has the same version
evals/plugin/                  behavioural evals, run with `claude plugin eval`
```

## Adding a skill

1. Create `skills/<category>/<name>/SKILL.md`. Keep the main file short and move detail into `references/`, which the skill reads only when needed.
2. Skills in an existing category folder load automatically. For a new category, add its folder (for example `"./skills/<category>"`) to the `skills` array in `.claude-plugin/plugin.json`.
3. To use a shared reference set such as the language files, create an empty `references/languages/` folder in the skill and run `scripts/sync-references.sh`. Edit shared files only under the root `references/`; CI fails if a skill's copy drifts.
4. Add eval cases under `evals/plugin/` (see its [README](evals/plugin/README.md)).
5. Check that it loads: `claude plugin validate .` should list the new skill.

## Releasing

Claude Code and Codex use the plugin version to decide whether an installed copy needs updating. If a change ships without a version bump, users may not receive it.

1. Pick the new version using semver: patch for fixes and wording changes, minor for new skills or behaviour, major for removed or renamed skills.
2. Set it in all four manifests: `.claude-plugin/plugin.json` (the source of truth), the root `plugin.json`, `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json`. CI fails if they differ; run `scripts/validate-versions.sh` to check locally.
3. Commit as `chore(release): bump plugin manifests to X.Y.Z`, merge it, then tag that commit and publish a GitHub release whose notes list the changes: `gh release create X.Y.Z --target main --generate-notes`.

## Credits

The workflow skills are inspired by [Augmented AI Development (AAID)](https://github.com/dawid-dahl-umain/augmented-ai-development) by Dawid Dahl. They also build on long-standing practice: Robert C. Martin's three laws of TDD, James Grenning's ZOMBIES test ordering, and Dave Farley's layered acceptance test model.

## License

[MIT](LICENSE)
