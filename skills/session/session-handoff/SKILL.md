---
name: session-handoff
description: Write a fixed-structure end-of-session handoff (decisions, changes, key files, running state, verification, deferrals, open questions) that a fresh agent with no context can pick up from. Use when the user asks to hand off, wrap up or summarize the session, says they're about to clear context or start a new session, or asks what a new agent would need to know to continue.
---

# Session Handoff

Write a summary that lets the user clear context and start a fresh agent without losing anything. The next agent should be able to continue from this summary alone.

The reader is a future agent with none of this conversation, not a stakeholder. Write for it: paths, commands, decisions, nothing else.

## When to use

The user asks for a handoff, a wrap-up or a session summary, or says they're about to clear context or start over in a new session. If they say they're about to clear and haven't asked for a handoff, offer one first.

## Gather

1. **Read the whole conversation**, not just the last few turns. A handoff built from recent context misses the decisions made early.
2. **Collect state from what this session did:**
   - Plan or spec files that drove the work.
   - The task list, if your agent keeps one: anything in progress or pending.
   - Files created, modified or deleted.
   - Processes you started that are still running: dev servers, watchers, long jobs.
   - Memory or instruction files you wrote or changed, if your agent has them.
   - Questions that never got a clear answer, from you or from the user.
3. **Check, don't recall, where it's cheap.** Memory of a long session is unreliable, especially after context was compacted. Run these read-only commands and reconcile them with what you remember:
   - `git status --short` and `git diff --stat`: what actually changed.
   - `git branch --show-current` and `git worktree list`: where the work lives.
   - For each process you started: confirm it's still alive (`ps -p <pid>`, `lsof -i :<port>`).

   Don't go further than that. No `git log` archaeology, no broad file searches. If this session didn't touch it, it doesn't belong in the handoff.

## Output template

Use exactly this structure every time. A section with nothing to report says "none"; never drop it.

```
# Session Handoff — <one line: what this session was about>

## Where it started
<2-3 sentences: what the user asked for, and the constraints or framing that emerged>

## Decisions and changes
- <decision or change> — <why; where it lives, as an absolute path if it's a file>

## Key files for next session
- Plan or spec: `<absolute path>` — read this first (if one drove the session)
- `<absolute path>` — <why the next agent should read it>
- Memory or instruction files changed: `<absolute paths>`

## Running state
- Processes: <what it is> — PID <pid>, stop with `kill <pid>`; logs at `<path>` — or "none"
- Servers and ports: <url> — find the owner with `lsof -i :<port>` — or "none"
- Branch and worktree: <branch> at `<absolute path>`; uncommitted changes: <yes, which files | no>

## Verification
- `<command>` — <expected outcome>

## Deferred and open questions
- Deferred: <item> — <why it waits>
- Open: <question for the user> — <context>

## Pick up here
<1-2 sentences: the single most likely next action>
```

## Deliver

1. **Post the handoff in chat.** Clearing context deletes it, so end with one line telling the user to copy it before they clear.
2. **Write it to a file only if the user asks**, at the path they give. If they want a file but name no place, ask. Don't add it to version control or memory unless asked.

## Rules

1. **Never invent state.** Every path, PID, port and command must come from this session or from the checks above. If you can't confirm something, say so.
2. **Absolute paths only.** The next agent may start in a different directory.
3. **Running processes need a way to stop them that works from a new session**: a PID, a port or a process name with the command to stop it. Handles that belong to your agent's own session, such as a background job ID, are useless after clearing; don't list them as the only way to stop something.
4. **If a plan or spec drove the session, list it first** under key files.
5. **Terse and concrete.** No praise, no emojis, no retrospective on what went well. Write it like an engineer handing over at the end of a shift.
6. **One next step.** "Pick up here" names the most likely next action and stops; the next agent decides the rest.

## Anti-patterns

- Summarizing the last few turns and calling it a handoff.
- Relative paths.
- Dropping a section because it's empty instead of writing "none".
- Reporting files as changed, or processes as running, from memory when a cheap check would have shown otherwise.
- A list of recommended next steps beyond "Pick up here".
