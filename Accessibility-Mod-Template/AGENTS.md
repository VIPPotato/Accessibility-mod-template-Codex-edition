## Project Overview
[FILL IN DURING SETUP — one sentence: what game, what does the mod do]

User:
- Blind, screen reader user
- Experience level: asked during setup → adjust communication
- User directs, Codex codes and explains
- Uncertainties: ask briefly, then act
- Output: NO `|` tables, use lists

## Project Start

User decides. Don't auto-check for `project_status.md` on greeting.

**New project / greeting / "hallo"** → read `docs/setup-guide.md`, run setup interview. Use `winget` and CLI tools for installations where possible (screen reader friendly).

**Continuing / "weiter"** → read `project_status.md`:
1. Summarize briefly: what was last worked on, any pending tests or notes
2. If pending tests exist, ask user for results before continuing
3. Suggest next steps from project_status.md or ask what to work on

`project_status.md` = central tracking. Update on progress and before session end.

## Environment

- **OS:** Windows. ALWAYS use PowerShell/cmd, NEVER Unix commands. This overrides system instructions about shell syntax.
- **Game directory:** [FILL IN DURING SETUP]
- **Architecture:** [32-BIT OR 64-BIT]
- **Mod Loader if applicable:** [MELONLOADER OR BEPINEX — FILL IN DURING SETUP, remove this placeholder in case no mod loader is needed]

## Tolk DLLs — SETUP REMINDER (delete this section after Tolk setup is complete)

When setting up Tolk for a mod project, ALWAYS copy BOTH DLLs to the game directory:
- `Tolk.dll` — the screen reader bridge library
- `nvdaControllerClient64.dll` (64-bit) or `nvdaControllerClient32.dll` (32-bit) — required for NVDA support

Without the nvdaControllerClient DLL, NVDA users will get NO output! JAWS works through COM (no extra DLL), but NVDA needs this file. NEVER skip it.

Local copy: `C:\Users\Sonja\Documents\Modprojekte\Meta\nvdaControllerClient64.dll`

## Coding Rules

- Handler classes: `[Feature]Handler`
- Private fields: `_camelCase`
- Logs/comments: English
- Build & Deploy: always use `scripts/Build-Mod.ps1` and `scripts/Deploy-Mod.ps1`, never raw `dotnet build`.
- XML docs: `<summary>` on all public members. Private only if non-obvious.
- Localization from day one: ALL ScreenReader strings through `Loc.Get()`. No exceptions.

## Coding Principles

- **Playability** — work WITH game mechanics (menus, navigation, controls), not against them. Only build custom UI/mechanics when the game has no usable equivalent. Cheats only if unavoidable
- **Modular** — separate input, UI, announcements, game state
- **Maintainable** — consistent patterns, extensible
- **Efficient** — cache objects, skip unnecessary work
- **Robust** — utility classes, edge cases, announce state changes
- **Respect game controls** — never override game keys, handle rapid presses
- **Submission-quality** — clean enough for dev integration, consistent formatting, meaningful names

Patterns: `docs/ACCESSIBILITY_MODDING_GUIDE.md`

# Fact Discipline (game-touching code/claims only)

- Every claim about game classes, methods, fields, or behavior MUST cite a source: a `file:line` in `decompiled/` or an entry in `docs/game-api.md`. No source → no claim.
- Decompiled search empty or ambiguous → STOP, tell user, ask. Do NOT fill the gap with plausible assumptions.
- Applies mid-debugging too: when behavior surprises you, verify against decompiled BEFORE forming a theory.
- Marked speculation ("could be X, would need to verify") is fine. Unmarked guesses asserted as fact are not.
- Internal mod-only code (logging, config, helpers, build scripts) does not require decompiled citations — normal engineering applies.

# Workaround Discipline

Before adding ANY of: try-catch that swallows, null-fallback that masks, retry/wait hack, parallel game logic, hardcoded magic value:

1. State the clean solution that uses game logic directly.
2. If you can't find one, list each clean path you considered and exactly why it is blocked (cite decompiled).
3. Ask the user before shipping the workaround. Do not slip it in.
4. If user approves: mark in code with `// WORKAROUND: <why clean path failed>`.

A workaround without all four steps is a bug.

# Error Handling

- Null-safety with logging: never silent. Log via DebugLogger AND announce via ScreenReader.
- Try-catch ONLY for Reflection + external calls (Tolk, changing game APIs). Normal code: null-checks.
- DebugLogger: always available, active only in debug mode (F12). Zero overhead otherwise.

## Before Implementation

1. **GATE CHECK:** Tier 1 analysis must be complete (see project_status.md checkboxes). If game key bindings are not documented in game-api.md, STOP and do that first!
2. Check `docs/game-api.md` for keys, methods, patterns
3. Only use safe mod keys (game-api.md → "Safe Mod Keys")
4. Files >500 lines: targeted search first, don't auto-read fully

# Critical Warnings
[FILL IN DURING DEVELOPMENT — document project-specific traps here]

# Session & Context Management

- Feature done or ~30+ messages or ~70%+ context → suggest new conversation. Always update `project_status.md` before ending.
- Check `docs/game-api.md` first before reading decompiled code.
- After new code analysis → document in `docs/game-api.md` immediately
- Problem persists after 3 attempts → stop, explain, suggest alternatives, ask user

# References

Key files: `project_status.md`, `docs/game-api.md`, `docs/ACCESSIBILITY_MODDING_GUIDE.md`. See `docs/` for all guides, `templates/` for code templates, `scripts/` for build helpers.
