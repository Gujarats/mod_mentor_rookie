# Legends Master Mentor Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `Master Mentor` perk available to every Legends player background as a real, selectable Legends perk at the configured tier.

**Architecture:** Add an isolated Mentor Rookie compatibility module that runs only after Legends. The module will register the existing `perk.master_mentor` definition with Legends, then hook Legends' `character_background.buildPerkTree` and call its `addPerk` API for each player background. The existing generic UI perk-tree injection will be skipped under Legends because Legends must own the authoritative `PerkTreeMap` and `CustomPerkTree` data.

**Tech Stack:** Battle Brothers Squirrel, Modern Hooks, MSU 1.9.0+, Legends perk-tree APIs, `modbb`.

## Global Constraints

- Modify only `mod_mentor_rookie`; never edit `data_001` or `mod_legends`.
- Compatibility code must be inert when `mod_legends` is absent.
- Preserve the canonical perk ID `perk.master_mentor`; do not create a second perk ID.
- Add the perk to every Legends player background, with the existing `MasterMentorPerkRow` setting determining the preferred row.
- Use Legends' `background.addPerk(perkDefIndex, preferredRow, isRefundable)` API, which selects another row when the preferred row has reached Legends' row capacity.
- Debug logging remains enabled by default and writes to `C:\Users\gujar\Documents\Battle Brothers\log.html`.
- Build with `modbb build mod_mentor_rookie`; do not create a ZIP manually.

---

## Files and Responsibilities

- Create: `mod_mentor_rookie/scripts/mods/compatibility/legends_master_mentor_patch.nut`
  - Detects Legends, registers the existing perk definition with Legends, and inserts it into each Legends background's authoritative perk tree.
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`
  - Includes and registers the compatibility module after Legends, and prevents the generic UI-only injection from running when Legends is active.
- Modify: `mod_mentor_rookie/README.md`
  - Documents Legends support, the all-background behavior, and row relocation when the selected tier is full.
- Create: `mod_mentor_rookie/docs/legends_compatibility.md`
  - Documents the runtime contract, assumptions about Legends APIs, load-order behavior, and manual test matrix.

### Task 1: Document the Legends Compatibility Contract

**Files:**
- Create: `mod_mentor_rookie/docs/legends_compatibility.md`
- Modify: `mod_mentor_rookie/README.md`

**Interfaces:**
- Consumes: Mentor Rookie setting `MasterMentorPerkRow`, existing perk definition in `scripts/config/z_mentor_rookie.nut`, and Legends `character_background.addPerk` behavior.
- Produces: Documentation that defines support as one canonical `perk.master_mentor` entry for every Legends player background.

- [x] **Step 1: Write the compatibility document before changing runtime code**

Create `docs/legends_compatibility.md` with these exact sections:

```markdown
# Legends Compatibility

## Scope

When `mod_legends` is installed, Mentor Rookie adds the existing `Master Mentor` perk (`perk.master_mentor`) to every Legends player background.

## Perk Placement

The `Master Mentor Perk Row` setting selects the preferred row. Mentor Rookie calls Legends' `background.addPerk` API instead of appending directly to a tree. Legends may move the perk to another row when the preferred row has reached its row capacity; this keeps the perk visible in the character-screen perk tree.

## Runtime Requirements

The compatibility module requires `mod_legends`, `::Legends.Perk`, `::Const.Perks.PerkDefObjects`, and `::Const.Perks.addPerkDefObjects`. If any requirement is unavailable, Mentor Rookie logs the reason and leaves Legends perk trees unchanged.

## Assumptions

- Legends assigns a numeric perk definition index after `::Const.Perks.addPerkDefObjects` completes.
- `character_background.buildPerkTree` has initialized `m.PerkTreeMap` before Mentor Rookie invokes `background.addPerk`.
- Legends' `background.addPerk` prevents duplicates and searches other rows before falling back to the preferred row.

## Debugging

With Debug Logging enabled, inspect `C:\\Users\\gujar\\Documents\\Battle Brothers\\log.html` for `[MentorRookie][Legends]` entries covering registration, insertion, duplicate skips, and unavailable APIs.
```

- [x] **Step 2: Add a concise README compatibility note**

After the `Master Mentor Perk` section in `README.md`, add:

```markdown
## Legends Compatibility

When Legends is installed, `Master Mentor` is added to every Legends player background. The configured Master Mentor perk row is treated as a preference: Legends can place the perk in another row when that row is full so the perk remains visible and selectable.
```

- [x] **Step 3: Review the documentation against the implementation contract**

Confirm the document explicitly states all of the following:

- `perk.master_mentor` remains the only supported perk ID.
- Every Legends player background receives the perk once.
- Legends owns row selection and duplicate prevention.
- Missing Legends APIs fail safely without changing a perk tree.

### Task 2: Implement an Isolated Legends Perk-Tree Adapter

**Files:**
- Create: `mod_mentor_rookie/scripts/mods/compatibility/legends_master_mentor_patch.nut`

**Interfaces:**
- Consumes: `::MentorRookie.Mod.ModSettings.getSetting("MasterMentorPerkRow")`, `::Hooks.hasMod("mod_legends")`, `::Const.Perks.PerkDefObjects`, `::Const.Perks.addPerkDefObjects`, and `background.addPerk(_perk, _preferredRow, _isRefundable)`.
- Produces: `::MentorRookie.Compatibility.Legends.registerHooks(_mod)` and `::MentorRookie.Compatibility.Legends.addMasterMentorToBackground(_background)`.

- [x] **Step 1: Define the compatibility namespace and runtime guard**

Create `legends_master_mentor_patch.nut` using Aura Routing's compatibility-module structure. Define `::MentorRookie.Compatibility.Legends` with:

```nut
MasterMentorPerkDef = null,

function hasRuntime()
{
    return ::Hooks.hasMod("mod_legends")
        && ("Legends" in getroottable())
        && ("Perk" in ::Legends)
        && ("PerkDefObjects" in ::Const.Perks)
        && ("addPerkDefObjects" in ::Const.Perks);
}

function getConfiguredRow()
{
    local row = ::MentorRookie.Mod.ModSettings.getSetting("MasterMentorPerkRow").getValue() - 1;
    return row < 0 ? 0 : row;
}
```

Use `::MentorRookie.Helpers.debugLog` for each rejected runtime condition. Prefix all messages with `[Legends]` so the final log output begins with `[MentorRookie] [Legends]`.

- [x] **Step 2: Register or discover the canonical Legends perk definition**

Add `registerPerkDef()` that first scans `::Const.Perks.PerkDefObjects` for `ID == "perk.master_mentor"`. When found, cache its numeric index in `MasterMentorPerkDef` and expose it as `::Legends.Perk.MasterMentor` and `::Const.Perks.PerkDefs.MasterMentor`.

When absent, call:

```nut
::Const.Perks.addPerkDefObjects([
    {
        ID = "perk.master_mentor",
        Script = "scripts/skills/perks/master_mentor_perk",
        Name = "Master Mentor",
        Tooltip = "This brother is especially effective at guiding rookies.",
        Icon = "ui/perks/mentor_rookie_perk.png",
        IconDisabled = "ui/perks/mentor_rookie_perk_sw.png",
        Const = "MasterMentor"
    }
]);
```

Then cache `::Legends.Perk.MasterMentor`. Do not add the vanilla-style `verifyPrerequisites` function to this Legends definition.

- [x] **Step 3: Insert the perk into each Legends background through Legends' API**

Implement:

```nut
function addMasterMentorToBackground( _background )
{
    if (_background == null || _background.m.PerkTreeMap == null) return false;

    local perkDefIndex = this.getMasterMentorPerkDefNumber();
    if (perkDefIndex == null) return false;
    if (_background.getPerk("perk.master_mentor") != null) return false;

    return _background.addPerk(perkDefIndex, this.getConfiguredRow(), true);
}
```

Log each outcome with the background ID or name, configured row, successful placement, duplicate skip, or unavailable tree state. Do not inspect or mutate `CustomPerkTree`, `PerkTreeMap`, or row arrays directly.

- [x] **Step 4: Hook buildPerkTree after Legends has built its tree**

Implement `registerHooks(_mod)` so it calls `registerPerkDef()`, returns immediately without Legends, and wraps `scripts/skills/backgrounds/character_background`:

```nut
_mod.hook("scripts/skills/backgrounds/character_background", function(q)
{
    q.buildPerkTree = @(__original) function()
    {
        local attributes = __original();
        module.addMasterMentorToBackground(this);
        return attributes;
    }
});
```

This preserves the original build result, guarantees Legends initializes the tree first, and makes the patch run for every background that executes `buildPerkTree`.

### Task 3: Wire the Adapter and Avoid UI-Only Legends Injection

**Files:**
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut:12-13`
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut:130-184`

**Interfaces:**
- Consumes: `::MentorRookie.Compatibility.Legends.registerHooks(mod)`.
- Produces: One source of truth per mode: Legends background data under Legends, or existing UI-tree augmentation without Legends.

- [x] **Step 1: Include the adapter with the other Mentor Rookie modules**

Immediately after the service include, add:

```nut
::include("scripts/mods/compatibility/legends_master_mentor_patch");
```

- [x] **Step 2: Register the adapter inside the existing queued initialization callback**

After `local mod = ::MentorRookie.HookMod;`, add:

```nut
::MentorRookie.Compatibility.Legends.registerHooks(mod);
```

The existing queue already waits for `>mod_legends`, so do not add another queue or change its current dependencies.

- [x] **Step 3: Leave normal UI injection intact but skip it when Legends is installed**

At the start of `convertEntityToUIData`, after `local result = __original(...)`, add this early return:

```nut
if (::Hooks.hasMod("mod_legends"))
{
    return result;
}
```

This ensures the normal branch continues to add `mentor_rookie_perkTree` for vanilla and other compatible mods, while Legends uses only its persistent background tree.

- [x] **Step 4: Add mode-selection debug logs**

Before the early return, log:

```nut
::MentorRookie.Helpers.debugLog("[Legends] skipped UI-only Master Mentor injection for " + _entity.getName());
```

Guard the log with `_entity != null` to retain the current null safety.

### Task 4: Build and Verify Both Runtime Modes

**Files:**
- Verify: `mod_mentor_rookie/build/`
- Verify: `C:\Users\gujar\Documents\Battle Brothers\log.html`

**Interfaces:**
- Consumes: Built Mentor Rookie mod and a save with Legends enabled or disabled.
- Produces: Evidence that the perk is selectable, persists, and does not duplicate in all supported modes.

- [x] **Step 1: Build the mod**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: the command succeeds and produces the build output under `mod_mentor_rookie/build/` without a manually created archive.

- [ ] **Step 2: Verify startup with Legends absent**

Launch with Mentor Rookie, MSU, and Modern Hooks, but without Legends. Open a player character screen and verify one `Master Mentor` icon appears in the configured row. Confirm the log does not contain a Legends API error and the existing `mentor_rookie_perkTree` behavior remains active.

- [ ] **Step 3: Verify a sparse Legends background**

Launch with Legends enabled, recruit or load a player character with a Legends background, and open its character screen. Confirm exactly one `Master Mentor` perk appears in the configured row and can be selected. Save, reload, and confirm it remains selectable or retained if purchased.

Expected log evidence:

```text
[MentorRookie] [Legends] registered Master Mentor perk definition index=
[MentorRookie] [Legends] added Master Mentor background=
[MentorRookie] [Legends] skipped UI-only Master Mentor injection for 
```

- [ ] **Step 4: Verify full-row relocation**

Use a Legends background whose configured `MasterMentorPerkRow` already has at least 13 perks. Confirm Legends moves `Master Mentor` to another row instead of allowing a hidden, oversized row. Record the actual selected row from the debug log.

- [ ] **Step 5: Verify duplicate prevention**

Open the same Legends character screen repeatedly, rebuild/load the campaign, and reload the save. Confirm the background tree contains one `perk.master_mentor`, the UI displays one icon, and the log reports a duplicate skip rather than a second insertion.

- [ ] **Step 6: Verify focused training end to end**

Purchase `Master Mentor`, create a mentor-rookie relationship, select a valid focused attribute, and complete the configured number of valid joint battles. Confirm Mentor Rookie recognizes the purchased skill and grants the focused-training reward exactly once.

Expected log evidence:

```text
[MentorRookie] focused training calculated mentor=
[MentorRookie] focused training applied rookie=
```

## Assumptions and Risks

- This plan assumes the checked-in Legends version continues to expose `PerkDefObjects`, `addPerkDefObjects`, `character_background.buildPerkTree`, `getPerk`, and `addPerk` with the observed signatures. The adapter must log and do nothing when that contract is absent.
- Legends' `addPerk` only guarantees a below-13 row when at least one of its seven rows has space. If every row is full, Legends itself falls back to the preferred row; the compatibility log must make this rare UI-overflow risk visible.
- Existing save backgrounds that have already built their perk trees must execute Legends' tree build/load path for the new perk to be added. Runtime testing must include both a new recruit and an existing save.

## Execution Handoff

Plan complete and saved to `mod_mentor_rookie/docs/superpowers/plans/2026-08-02-legends-master-mentor-compatibility.md`. Two execution options:

1. **Subagent-Driven (recommended)** - Dispatch a fresh subagent per task and review each task before continuing.
2. **Inline Execution** - Execute the tasks in this session with implementation checkpoints.
