# AI-led development workflow

## One responsible integrator

Use roles, not a permanent swarm. A context scout may cheaply identify existing code and produce path/line references. An implementer changes only the task's owned paths. A read-only reviewer checks the original contract against the diff and evidence. The integrator resolves shared interfaces and makes the final truthful report. Humans retain creative direction and merge/release approval.

Model selection is empirical: cost per accepted task, repair rounds and missed defects on this repository. Do not hard-code model brand rankings. Parallel writers are limited to two and require disjoint files; three nominally different tasks touching one scene are one ownership zone.

## Repeatable cycle

1. Read root AGENTS, relevant design/architecture sections and the active task. Inspect `git status`, existing code, branches and open PRs. Search -> reuse -> extend -> compose -> create.
2. Write a small contract using `docs/tasks/TEMPLATE.md`: observable behavior, owned paths, forbidden changes, success/failure examples and exact verification commands. Do not start by rewriting the architecture.
3. Implement one behavior; update its tests in the same change. Use named game parameters and resources. Preserve ordinary Godot editor workflows.
4. Run `python3 tools/dev.py check`. Read logs rather than trusting the exit code alone. The wrapper also rejects Godot script/error output.
5. For visual changes, run `capture`, inspect the images and perform an interactive pass. For sound, actually listen. Run `export` and launch the exported client. Automated fixtures are labelled fixtures, not playtests.
6. Review independently against the contract. Look for unwired systems, client authority, hidden timers, duplicate objects, stale evidence, shared Resource mutation and unreachable interactions.
7. Update the same PR with focused commits and an evidence receipt. Do not merge or promote stable without owner approval.

## Branch / PR policy

Hard ceiling: five branches total (`main`, eventually `stable`, at most three feature branches); three open PRs total. Normal bootstrap operation is stricter: one feature branch, one PR. Initializing a truly empty repository is the sole bootstrap exception to making a PR into an existing main. Never force-push, delete unrelated work, or silently change branch protection. The written ceiling is a workflow rule; repository administrator protection is a separate owner setting.

`main` is integration, not autodeploy. `stable` is a separately approved exact tested commit and its workflow exports release artifacts. This scaffold does not create a public web deployment, auto-merge or automatically advance stable. Do not claim otherwise.

## Evidence receipt

Record commit SHA, engine version, commands, pass/fail/NOT RUN, artifact paths and known limitations. CI checks out the exact PR head rather than attributing merge-ref results to a different SHA. A source archive and `commit.txt` travel with the logs.

A green import is not a playable game. A headless scene launch is not a visual review. An ENet protocol probe is not a multiplayer playthrough. Software-rendered captures are not target-GPU benchmarks. Dummy audio is not a listening review. Do not erase these distinctions to make a task appear finished.

## Art and tool use

Resolve existing licensed assets first. For unique art, use Blender -> GLB with source `.blend` or reproducible generator and a recorded tool version. An MCP bridge may assist an agent but is not the sole record of edits and is not a required dependency. This bootstrap does not install a Blender/Godot MCP server.

Install no arbitrary plugins or credentials. CI is read-only for repository contents, uses pinned action revisions and publishes only sources/builds/test artifacts. Local debug fixtures are gated by debug builds, never callable through a network command.

## Bootstrap test caveats
The scene-interaction fixture places actors at named test positions, then exercises real ray queries and intent signal wiring. It is not a walking/navigation or human keyboard playtest. Linux headless/Dummy shutdown currently reports retained WAV/playback objects; record this warning as an open audio-lifecycle issue rather than claiming a warning-free build. `.gd.uid` and shader UID sidecars belong in Git; `.godot/` import caches and generated vendor output do not.
