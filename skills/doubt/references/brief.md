# Doubt brief

The brief for a fresh subagent when the `doubter` agent isn't available, and for a second model's CLI. Fill in the two blocks and send nothing else: no claim, no reasoning, no session history.

```markdown
Adversarial review. Find what is wrong with this artifact. Assume the author is overconfident.

Look for:
- Ways the contract can be violated, with the concrete input or sequence that does it
- Unstated assumptions the artifact depends on
- Edge cases and failure paths it doesn't handle
- Hidden coupling, shared state, ordering and concurrency hazards
- Conventions of the surrounding code it breaks
- Anything irreversible that happens before it can be checked

Do not validate, praise or summarise. Report only issues. For each one give a location, the
contract clause it breaks, and a concrete failure scenario (this input or sequence leads to
this wrong outcome). Mark an issue "unverified" when you suspect it but can't show it, and say
what would settle it. If you find nothing after a thorough look, say so and list what you checked.

You may read the repository to check callers and conventions. Do not edit anything.

ARTIFACT:
<the diff, function, or proposal>

CONTRACT:
<what it must satisfy>
```
