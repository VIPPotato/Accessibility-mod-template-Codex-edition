# Changelog

## v2.0.0 (upcoming)

Major expansion of the template with new guides, quality standards, and workflow improvements.

### New: Guides and Documentation

- **Git/GitHub guide** - Explains Git and GitHub from scratch for complete beginners
- **Distribution guide** - How to package, publish, and license your mod (GitHub Releases, NexusMods, license comparison)
- **State management guide** - Managing multiple handlers on shared keys without conflicts
- **Unity Reflection guide** - Accessing private fields, ReflectionHelper patterns
- **Menu accessibility patterns** - Item types, label resolution, navigation patterns, debugging
- **Legacy Unity modding guide** - Unity 5.x and older, Assembly-Patching as fallback

### New: Templates

- **ModConfig.cs** - In-game mod settings via MelonPreferences with keyboard-navigable settings menu (Ctrl+F11)
- **ReflectionHelper.cs** - Utility class for accessing private Unity fields
- **project_status.md** - Central project tracking document for continuity across sessions

### New: Setup Features

- **Game familiarity question** (Step 2b) - Asks how well the user knows the game
- **Tutorial text extraction** (Step 7b) - Offers to extract tutorial/help texts from decompiled code for unfamiliar users
- **Project detection** - Claude now checks if `project_status.md` exists to distinguish new projects from returning sessions
- **Build-test workflow** - Explains the build-test cycle to the user the first time it happens
- **Token management guidance** - When to start new conversations and why

### New: Code Quality Standards

- **Localization from day one** - All ScreenReader strings must go through `Loc.Get()`, no exceptions, from the first prototype
- **XML documentation required** - All public classes and methods must have `<summary>` comments
- **Submission-quality principle** - Code should be clean enough for game developers to consider integrating
- **Error handling rules** - Explicit standards: null-safety with logging, try-catch only for Reflection/external calls
- **.editorconfig** - Consistent formatting across editors, supports C#, Python, GDScript, C++

### New: Accessibility Patterns

- **Announcement priority** - Guidelines for when to interrupt vs. queue speech
- **AnnouncementManager concept** - Documented as optional advanced pattern for games with many simultaneous events
- **SayQueued()** convenience method added to ScreenReader template

### Changed

- **Phase 1 reorganized into tiers** - Essential (do first), Just-in-time (before each feature), When-relevant (later). Prevents information overload for beginners.
- **Step 8 (Languages) rewritten** - Localization is no longer optional. Question is now "which languages?" not "should it be multilingual?"
- **Loc.cs is now part of Phase 2** (basic framework), not a later addition
- **Session management** - Claude suggests new conversations after completed features and updates project_status.md before ending
- **Context management** - Rules to prevent re-reading already-documented code, saving tokens

### Fixed

- **ScreenReader API consistency** - Removed all references to non-existent `ScreenReader.Announce()` and `ScreenReader.SayQueued()` methods across all templates and docs. Everything now uses `Say()` and `SayQueued()` which map to real Tolk functions.
- **Namespace placeholders unified** - All templates now use `NAMESPACE` consistently (was `[MODNAME]` in some files)
- **Handler template language** - All hardcoded German strings replaced with English + Loc.Get()
- **CLAUDE.de.md** - Added all missing reference links that existed in CLAUDE.md

## v1.0.1

- Restructured project into subfolder layout (docs/, templates/, scripts/)
- Expanded README tips section
- Added debit card as payment option note

## v1.0

- Initial release
- Setup interview workflow
- Core templates (Main.cs, Handler.cs, ScreenReader.cs, Loc.cs, DebugLogger.cs, csproj)
- Accessibility Modding Guide
- Menu accessibility checklist
- Localization guide
- Technical reference
- PowerShell helper scripts (Get-MelonLoaderInfo, Test-ModSetup)
- game-api.md template
