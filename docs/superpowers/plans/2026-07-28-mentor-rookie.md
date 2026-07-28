# Mentor Rookie Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `mod_mentor_rookie`, a Battle Brothers mod where one higher-level brother mentors one lower-level brother through battle-based XP catch-up and visible passive relationship effects.

**Architecture:** Use MSU settings and Modern Hooks. Store active one-to-one mentor relationships in a small service keyed by actor ID, expose assignment through a world keybind screen, and apply bonus XP after valid battles by comparing each rookie's `CombatStats.XPGained` before and after vanilla combat resolution. The first release implements XP catch-up only; talent star and trait transfer are explicitly out of scope.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks, MSU settings, vanilla UI bridge (`UI.connect` / JS `registerScreen`), CSS/JS under `ui/mods`, static PowerShell validation scripts, `modbb` for build/deploy.

## Global Constraints

- Read `context.md` before implementation and follow it as project policy.
- Do not modify `data_001`.
- Do not modify community mods.
- Use `mod_bro_editor` only as a reference for world keybind and screen structure.
- Use MSU settings.
- Use Modern Hooks.
- Create debug logs programmatically and expose a `DebugLogging` setting.
- `DebugLogging` default must be `true` for the first version.
- Build with `modbb`; do not build ZIP archives manually.
- Keep all behavior isolated inside `mod_mentor_rookie`.
- First release must not transfer talent stars.
- First release must not transfer traits.
- Mentoring progress is based on valid battles together, not days.
- A battle counts only if mentor and rookie both participate and survive.
- Default minimum mentor level is `6`.
- Default maximum rookie level is `10`.
- Default graduation battle check begins after `50` valid battles together.
- Immediate graduation happens if the rookie reaches or passes the mentor's level.
- Normal graduation happens after the graduation check begins and the rookie reaches the configured graduation level, default `10`.
- Bonus XP is calculated from the rookie's own vanilla battle XP gained, not from mentor XP, to keep the system bounded and easy to reason about.

---

## File Structure

- Create `mod_mentor_rookie/mod.json`
  - Declares mod metadata and dependency expectations.
- Create `mod_mentor_rookie/README.md`
  - Documents behavior, assumptions, settings, debug logging, and manual test steps.
- Create `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`
  - Registers Modern Hooks, MSU dependency, settings, JS/CSS assets, and hooks.
- Create `mod_mentor_rookie/scripts/config/z_mentor_rookie.nut`
  - Defines globals, perk registration, debug helper, settings access helpers, and shared constants.
- Create `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
  - Owns relationship creation/removal, eligibility checks, battle tracking, XP bonus calculation, graduation, serialization payloads, and UI query payloads.
- Create `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_mentor_effect.nut`
  - Visible passive effect on mentor.
- Create `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_rookie_effect.nut`
  - Visible passive effect on rookie.
- Create `mod_mentor_rookie/scripts/skills/perks/master_mentor_perk.nut`
  - Visible perk shell for future expansion and relationship flavor.
- Create `mod_mentor_rookie/scripts/ui/screens/world/mentor_rookie_screen.nut`
  - Squirrel backend for assignment screen.
- Create `mod_mentor_rookie/ui/mods/mentor_rookie_screen.js`
  - Two-column mentor/rookie assignment UI.
- Create `mod_mentor_rookie/ui/mods/mentor_rookie_screen.css`
  - Screen layout and row states.
- Create `mod_mentor_rookie/ui/mods/mentor_rookie.js`
  - Lightweight UI bootstrap if needed by local pattern.
- Create `mod_mentor_rookie/ui/mods/mentor_rookie.css`
  - Shared lightweight CSS if needed by local pattern.
- Create `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`
  - Static validator for required files, IDs, settings, forbidden star/trait transfer, and core hook tokens.
- Create `mod_mentor_rookie/test-results/mentor-rookie-manual-matrix.md`
  - Manual testing matrix.

---

### Task 1: Scaffold Metadata, Settings, Globals, and Static Validator

**Files:**
- Create: `mod_mentor_rookie/mod.json`
- Create: `mod_mentor_rookie/README.md`
- Create: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`
- Create: `mod_mentor_rookie/scripts/config/z_mentor_rookie.nut`
- Create: `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`

**Interfaces:**
- Produces: `::MentorRookie`
- Produces: `::MentorRookie.ID = "mod_mentor_rookie"`
- Produces: `::MentorRookie.Mod`
- Produces: `::MentorRookie.HooksMod`
- Produces: `::MentorRookie.getSetting(_key)`
- Produces: `::MentorRookie.debugLog(_message)`
- Produces MSU settings:
  - `DebugLogging`
  - `MinimumMentorLevel`
  - `MaximumRookieLevel`
  - `Level1To3XPBonusPercent`
  - `Level4To6XPBonusPercent`
  - `Level7To10XPBonusPercent`
  - `EnableMasterMentorPerk`
  - `MasterMentorPerkRow`
  - `BattlesForFirstMilestone`
  - `BattlesForSecondMilestone`
  - `BattlesForAdvancedMilestone`
  - `BattlesBeforeGraduationCheck`
  - `GraduationRookieLevel`

- [ ] **Step 1: Create the validator with expected initial failures**

Create `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`:

```powershell
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

function Assert-File($RelativePath) {
    $Path = Join-Path $Root $RelativePath
    if (!(Test-Path -LiteralPath $Path)) {
        throw "Missing required file: $RelativePath"
    }
}

function Assert-Contains($RelativePath, $Token) {
    $Path = Join-Path $Root $RelativePath
    Assert-File $RelativePath
    $Content = Get-Content -LiteralPath $Path -Raw
    if ($Content -notlike "*$Token*") {
        throw "Missing token '$Token' in $RelativePath"
    }
}

function Assert-NotContains($RelativePath, $Token) {
    $Path = Join-Path $Root $RelativePath
    Assert-File $RelativePath
    $Content = Get-Content -LiteralPath $Path -Raw
    if ($Content -like "*$Token*") {
        throw "Forbidden token '$Token' found in $RelativePath"
    }
}

Assert-File "mod.json"
Assert-File "README.md"
Assert-File "scripts/!mods_preload/mod_mentor_rookie.nut"
Assert-File "scripts/config/z_mentor_rookie.nut"

Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "::Hooks.register"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "mod_msu >= 1.9.0"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "DebugLogging"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "MinimumMentorLevel"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "BattlesBeforeGraduationCheck"

Assert-Contains "scripts/config/z_mentor_rookie.nut" "::MentorRookie"
Assert-Contains "scripts/config/z_mentor_rookie.nut" "mod_mentor_rookie"
Assert-Contains "scripts/config/z_mentor_rookie.nut" "debugLog"
Assert-NotContains "scripts/config/z_mentor_rookie.nut" "setTalent"
Assert-NotContains "scripts/config/z_mentor_rookie.nut" "trait."

Write-Host "Mentor Rookie layout validation passed."
```

- [ ] **Step 2: Run validator to verify it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_mentor_rookie\tools\validate_mentor_rookie_layout.ps1
```

Expected: FAIL with `Missing required file`.

- [ ] **Step 3: Create `mod.json`**

Create:

```json
{
  "name": "Mentor Rookie",
  "description": "One veteran brother can mentor one lower-level brother through battle-based XP catch-up.",
  "version": "0.1.0",
  "author": "Gujarat Santana",
  "mod_id": "mod_mentor_rookie"
}
```

- [ ] **Step 4: Create initial README**

Create `mod_mentor_rookie/README.md`:

```markdown
# Mentor Rookie

Mentor Rookie lets one higher-level brother mentor one lower-level brother. Mentoring progresses through valid battles together, not calendar days.

## First Release Scope

- One mentor can have one rookie.
- One rookie can have one mentor.
- Rookies gain configurable bonus XP after valid battles.
- Mentors and rookies receive visible passive effects.
- Relationships graduate when the rookie catches the mentor, or after the graduation check begins and the rookie reaches the configured graduation level.
- Talent star transfer is not implemented in the first release.
- Trait transfer is not implemented in the first release.

## Assumptions

Bonus XP is calculated from the rookie's vanilla battle XP gained. This avoids double-counting mentor kills and keeps hiring balance intact.

## Debugging

Debug logging is enabled by default in the first version. Check `C:\Users\gujar\Documents\Battle Brothers\log.html` for lines prefixed with `[MentorRookie]`.

## Manual Testing

Use the world keybind to open the mentor assignment screen. Assign a level 6+ mentor to a lower-level rookie, fight battles with both in the active formation, and confirm battle count, bonus XP, and graduation behavior in the log.
```

- [ ] **Step 5: Create globals/config**

Create `scripts/config/z_mentor_rookie.nut`:

```squirrel
if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

::MentorRookie.ID <- "mod_mentor_rookie";
::MentorRookie.Name <- "Mentor Rookie";
::MentorRookie.Version <- "0.1.0";

::MentorRookie.getSetting <- function( _key )
{
	return ::MentorRookie.Mod.ModSettings.getSetting(_key).getValue();
}

::MentorRookie.debugLog <- function( _message )
{
	if (::MentorRookie.getSetting("DebugLogging"))
	{
		::MentorRookie.Mod.Debug.printLog("[MentorRookie] " + _message);
	}
}

::MentorRookie.getXPBonusPercentForLevel <- function( _level )
{
	if (_level <= 3) return ::MentorRookie.getSetting("Level1To3XPBonusPercent");
	if (_level <= 6) return ::MentorRookie.getSetting("Level4To6XPBonusPercent");
	return ::MentorRookie.getSetting("Level7To10XPBonusPercent");
}
```

- [ ] **Step 6: Create preload and MSU settings**

Create `scripts/!mods_preload/mod_mentor_rookie.nut`:

```squirrel
if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

::MentorRookie.ID <- "mod_mentor_rookie";
::MentorRookie.Name <- "Mentor Rookie";
::MentorRookie.Version <- "0.1.0";
::MentorRookie.HooksMod <- ::Hooks.register(::MentorRookie.ID, ::MentorRookie.Version, ::MentorRookie.Name);
::MentorRookie.HooksMod.require("mod_msu >= 1.9.0");

::MentorRookie.HooksMod.queue(">mod_msu", function()
{
	::include("scripts/config/z_mentor_rookie");

	::MentorRookie.Mod <- ::MSU.Class.Mod(::MentorRookie.ID, ::MentorRookie.Version, ::MentorRookie.Name);

	local general = ::MentorRookie.Mod.ModSettings.addPage("General");
	general.addBooleanSetting("DebugLogging", true, "Debug Logging", "Write Mentor Rookie debug lines to log.html.");
	general.addRangeSetting("MinimumMentorLevel", 6, 1, 33, 1, "Minimum Mentor Level", "Minimum level required for a brother to mentor a rookie.");
	general.addRangeSetting("MaximumRookieLevel", 10, 1, 33, 1, "Maximum Rookie Level", "Maximum level that can be mentored by default.");
	general.addBooleanSetting("EnableMasterMentorPerk", true, "Enable Master Mentor Perk", "Adds the Master Mentor perk to the configured perk row.");
	general.addRangeSetting("MasterMentorPerkRow", 6, 1, 7, 1, "Master Mentor Perk Row", "Perk row used for Master Mentor. Requires restart.");

	local xp = ::MentorRookie.Mod.ModSettings.addPage("XP");
	xp.addRangeSetting("Level1To3XPBonusPercent", 20, 0, 100, 1, "Level 1-3 XP Bonus (%)", "Bonus XP awarded to mentored rookies from level 1 through 3.");
	xp.addRangeSetting("Level4To6XPBonusPercent", 15, 0, 100, 1, "Level 4-6 XP Bonus (%)", "Bonus XP awarded to mentored rookies from level 4 through 6.");
	xp.addRangeSetting("Level7To10XPBonusPercent", 12, 0, 100, 1, "Level 7-10 XP Bonus (%)", "Bonus XP awarded to mentored rookies from level 7 through 10.");

	local progress = ::MentorRookie.Mod.ModSettings.addPage("Progress");
	progress.addRangeSetting("BattlesForFirstMilestone", 5, 1, 200, 1, "First Milestone Battles", "Valid battles together required for the first relationship milestone.");
	progress.addRangeSetting("BattlesForSecondMilestone", 15, 1, 200, 1, "Second Milestone Battles", "Valid battles together required for the second relationship milestone.");
	progress.addRangeSetting("BattlesForAdvancedMilestone", 30, 1, 200, 1, "Advanced Milestone Battles", "Valid battles together required for the advanced relationship milestone.");
	progress.addRangeSetting("BattlesBeforeGraduationCheck", 50, 1, 300, 1, "Graduation Check Battles", "Valid battles together required before normal graduation can happen.");
	progress.addRangeSetting("GraduationRookieLevel", 10, 1, 33, 1, "Graduation Rookie Level", "Rookie level required for normal graduation once graduation checks begin.");

	::MentorRookie.debugLog("settings registered");
});
```

- [ ] **Step 7: Run validator**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_mentor_rookie\tools\validate_mentor_rookie_layout.ps1
```

Expected: PASS with `Mentor Rookie layout validation passed.`

---

### Task 2: Relationship Service and Passive Effects

**Files:**
- Create: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
- Create: `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_mentor_effect.nut`
- Create: `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_rookie_effect.nut`
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`
- Modify: `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`

**Interfaces:**
- Produces: `::MentorRookie.Service`
- Produces: `Service.createRelationship(_mentorID, _rookieID) -> table`
- Produces: `Service.removeRelationship(_mentorID, _reason) -> table`
- Produces: `Service.getRelationshipByMentorID(_mentorID) -> table|null`
- Produces: `Service.getRelationshipByRookieID(_rookieID) -> table|null`
- Produces: `Service.getActorByID(_actorID) -> actor|null`
- Produces: `Service.isEligibleMentor(_actor) -> bool`
- Produces: `Service.isEligibleRookie(_mentor, _rookie) -> bool`
- Produces: `Service.ensureEffects(_relationship) -> void`
- Produces: `effects.mentor_rookie_mentor`
- Produces: `effects.mentor_rookie_rookie`

- [ ] **Step 1: Extend validator for service/effects**

Append checks:

```powershell
Assert-File "scripts/mods/mentor_rookie_service.nut"
Assert-File "scripts/skills/effects/mentor_rookie_mentor_effect.nut"
Assert-File "scripts/skills/effects/mentor_rookie_rookie_effect.nut"
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "createRelationship"
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "removeRelationship"
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "MentorID"
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "RookieID"
Assert-Contains "scripts/skills/effects/mentor_rookie_mentor_effect.nut" "effects.mentor_rookie_mentor"
Assert-Contains "scripts/skills/effects/mentor_rookie_rookie_effect.nut" "effects.mentor_rookie_rookie"
```

- [ ] **Step 2: Run validator to verify it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_mentor_rookie\tools\validate_mentor_rookie_layout.ps1
```

Expected: FAIL with missing service/effect file.

- [ ] **Step 3: Create mentor effect**

Create `scripts/skills/effects/mentor_rookie_mentor_effect.nut`:

```squirrel
this.mentor_rookie_mentor_effect <- this.inherit("scripts/skills/skill", {
	m = {
		RookieID = 0,
		RookieName = "",
		BattlesTogether = 0
	},

	function create()
	{
		this.m.ID = "effects.mentor_rookie_mentor";
		this.m.Name = "Mentor";
		this.m.Description = "This brother is mentoring a lower-level rookie through shared battle experience.";
		this.m.Icon = "skills/status_effect_106.png";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsRemovedAfterBattle = false;
	}

	function setRelationship( _rookieID, _rookieName, _battlesTogether )
	{
		this.m.RookieID = _rookieID;
		this.m.RookieName = _rookieName;
		this.m.BattlesTogether = _battlesTogether;
	}

	function getTooltip()
	{
		local ret = this.skill.getTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/xp_received.png",
			text = "Mentoring " + this.m.RookieName + ". Valid battles together: [color=" + this.Const.UI.Color.PositiveValue + "]" + this.m.BattlesTogether + "[/color]."
		});
		return ret;
	}
});
```

- [ ] **Step 4: Create rookie effect**

Create `scripts/skills/effects/mentor_rookie_rookie_effect.nut`:

```squirrel
this.mentor_rookie_rookie_effect <- this.inherit("scripts/skills/skill", {
	m = {
		MentorID = 0,
		MentorName = "",
		BattlesTogether = 0,
		BonusPercent = 0
	},

	function create()
	{
		this.m.ID = "effects.mentor_rookie_rookie";
		this.m.Name = "Mentored Rookie";
		this.m.Description = "This brother is learning from a more experienced mentor.";
		this.m.Icon = "skills/status_effect_106.png";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsRemovedAfterBattle = false;
	}

	function setRelationship( _mentorID, _mentorName, _battlesTogether, _bonusPercent )
	{
		this.m.MentorID = _mentorID;
		this.m.MentorName = _mentorName;
		this.m.BattlesTogether = _battlesTogether;
		this.m.BonusPercent = _bonusPercent;
	}

	function getTooltip()
	{
		local ret = this.skill.getTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/xp_received.png",
			text = "Learning from " + this.m.MentorName + ". Valid battles together: [color=" + this.Const.UI.Color.PositiveValue + "]" + this.m.BattlesTogether + "[/color]. Current bonus XP: [color=" + this.Const.UI.Color.PositiveValue + "]" + this.m.BonusPercent + "%[/color]."
		});
		return ret;
	}
});
```

- [ ] **Step 5: Create service**

Create `scripts/mods/mentor_rookie_service.nut`:

```squirrel
::MentorRookie.Service <- {
	Relationships = {},

	function getActorByID( _actorID )
	{
		if (!("World" in getroottable()) || ::World.getPlayerRoster() == null) return null;

		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.getID() == _actorID) return bro;
		}

		return null;
	}

	function getRelationshipByMentorID( _mentorID )
	{
		local key = "" + _mentorID;
		return key in this.Relationships ? this.Relationships[key] : null;
	}

	function getRelationshipByRookieID( _rookieID )
	{
		foreach (relationship in this.Relationships)
		{
			if (relationship.RookieID == _rookieID) return relationship;
		}

		return null;
	}

	function isEligibleMentor( _actor )
	{
		if (_actor == null || _actor.getSkills() == null) return false;
		if (_actor.getLevel() < ::MentorRookie.getSetting("MinimumMentorLevel")) return false;
		return this.getRelationshipByMentorID(_actor.getID()) == null && this.getRelationshipByRookieID(_actor.getID()) == null;
	}

	function isEligibleRookie( _mentor, _rookie )
	{
		if (_mentor == null || _rookie == null || _rookie.getSkills() == null) return false;
		if (_rookie.getID() == _mentor.getID()) return false;
		if (_rookie.getLevel() >= _mentor.getLevel()) return false;
		if (_rookie.getLevel() > ::MentorRookie.getSetting("MaximumRookieLevel")) return false;
		return this.getRelationshipByMentorID(_rookie.getID()) == null && this.getRelationshipByRookieID(_rookie.getID()) == null;
	}

	function createRelationship( _mentorID, _rookieID )
	{
		local mentor = this.getActorByID(_mentorID);
		local rookie = this.getActorByID(_rookieID);

		if (!this.isEligibleMentor(mentor))
		{
			return { Success = false, Reason = "invalid_mentor", Message = "The selected mentor is not eligible." };
		}

		if (!this.isEligibleRookie(mentor, rookie))
		{
			return { Success = false, Reason = "invalid_rookie", Message = "The selected rookie is not eligible." };
		}

		local relationship = {
			MentorID = _mentorID,
			RookieID = _rookieID,
			MentorName = mentor.getName(),
			RookieName = rookie.getName(),
			BattlesTogether = 0,
			LastAwardedXP = 0
		};

		this.Relationships["" + _mentorID] <- relationship;
		this.ensureEffects(relationship);
		::MentorRookie.debugLog("relationship created mentor=" + mentor.getName() + " rookie=" + rookie.getName());
		return { Success = true, Reason = "ok", Message = rookie.getName() + " is now mentored by " + mentor.getName() + "." };
	}

	function removeRelationship( _mentorID, _reason )
	{
		local key = "" + _mentorID;
		if (!(key in this.Relationships))
		{
			return { Success = false, Reason = "not_found", Message = "No mentor relationship found." };
		}

		local relationship = this.Relationships[key];
		local mentor = this.getActorByID(relationship.MentorID);
		local rookie = this.getActorByID(relationship.RookieID);

		if (mentor != null && mentor.getSkills() != null) mentor.getSkills().removeByID("effects.mentor_rookie_mentor");
		if (rookie != null && rookie.getSkills() != null) rookie.getSkills().removeByID("effects.mentor_rookie_rookie");

		delete this.Relationships[key];
		::MentorRookie.debugLog("relationship removed mentorID=" + relationship.MentorID + " rookieID=" + relationship.RookieID + " reason=" + _reason);
		return { Success = true, Reason = _reason, Message = "Mentor relationship removed." };
	}

	function ensureEffects( _relationship )
	{
		local mentor = this.getActorByID(_relationship.MentorID);
		local rookie = this.getActorByID(_relationship.RookieID);
		if (mentor == null || rookie == null) return;

		if (!mentor.getSkills().hasSkill("effects.mentor_rookie_mentor"))
		{
			mentor.getSkills().add(::new("scripts/skills/effects/mentor_rookie_mentor_effect"));
		}

		if (!rookie.getSkills().hasSkill("effects.mentor_rookie_rookie"))
		{
			rookie.getSkills().add(::new("scripts/skills/effects/mentor_rookie_rookie_effect"));
		}

		local mentorEffect = mentor.getSkills().getSkillByID("effects.mentor_rookie_mentor");
		local rookieEffect = rookie.getSkills().getSkillByID("effects.mentor_rookie_rookie");
		mentorEffect.setRelationship(rookie.getID(), rookie.getName(), _relationship.BattlesTogether);
		rookieEffect.setRelationship(mentor.getID(), mentor.getName(), _relationship.BattlesTogether, ::MentorRookie.getXPBonusPercentForLevel(rookie.getLevel()));
	}
};
```

- [ ] **Step 6: Include service from preload**

Inside the MSU queue after `::include("scripts/config/z_mentor_rookie");`, add:

```squirrel
::include("scripts/mods/mentor_rookie_service");
```

- [ ] **Step 7: Run validator**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_mentor_rookie\tools\validate_mentor_rookie_layout.ps1
```

Expected: PASS.

---

### Task 3: Battle Tracking, XP Bonus, Graduation, and Save Persistence

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`
- Modify: `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`

**Interfaces:**
- Produces: `Service.captureBeforeCombat() -> void`
- Produces: `Service.handleAfterCombat() -> void`
- Produces: `Service.validateRelationships(_reason) -> void`
- Produces: `Service.serializeRelationships(_out) -> void`
- Produces: `Service.deserializeRelationships(_in) -> void`

- [ ] **Step 1: Extend validator for combat/persistence hooks**

Append:

```powershell
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "captureBeforeCombat"
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "handleAfterCombat"
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "serializeRelationships"
Assert-Contains "scripts/mods/mentor_rookie_service.nut" "deserializeRelationships"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "onCombatStarted"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "onCombatFinished"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "onSerialize"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "onDeserialize"
```

- [ ] **Step 2: Run validator to verify it fails**

Run validator.

Expected: FAIL on missing `captureBeforeCombat`.

- [ ] **Step 3: Add battle tracking fields and methods to service**

Add to `Service`:

```squirrel
BeforeCombatXP = {},

function captureBeforeCombat()
{
	this.BeforeCombatXP.clear();
	if (!("World" in getroottable()) || ::World.getPlayerRoster() == null) return;

	foreach (bro in ::World.getPlayerRoster().getAll())
	{
		this.BeforeCombatXP["" + bro.getID()] <- bro.m.CombatStats.XPGained;
	}

	::MentorRookie.debugLog("captured pre-combat XP for roster");
}

function wasInBattleAndAlive( _actor )
{
	return _actor != null && _actor.isAlive() && _actor.isPlacedOnMap();
}

function getRookieBattleXPGained( _rookie )
{
	local key = "" + _rookie.getID();
	local before = key in this.BeforeCombatXP ? this.BeforeCombatXP[key] : _rookie.m.CombatStats.XPGained;
	return ::Math.max(0, _rookie.m.CombatStats.XPGained - before);
}

function handleAfterCombat()
{
	this.validateRelationships("after_combat");

	local toRemove = [];
	foreach (key, relationship in this.Relationships)
	{
		local mentor = this.getActorByID(relationship.MentorID);
		local rookie = this.getActorByID(relationship.RookieID);

		if (!this.wasInBattleAndAlive(mentor) || !this.wasInBattleAndAlive(rookie))
		{
			::MentorRookie.debugLog("battle ignored mentorID=" + relationship.MentorID + " rookieID=" + relationship.RookieID);
			this.ensureEffects(relationship);
			continue;
		}

		local baseXP = this.getRookieBattleXPGained(rookie);
		if (baseXP <= 0)
		{
			::MentorRookie.debugLog("battle counted without XP mentor=" + mentor.getName() + " rookie=" + rookie.getName());
			relationship.BattlesTogether++;
			this.ensureEffects(relationship);
			continue;
		}

		local pct = ::MentorRookie.getXPBonusPercentForLevel(rookie.getLevel());
		local bonus = ::Math.floor(baseXP * pct / 100.0);
		if (bonus > 0)
		{
			rookie.addXP(bonus, false);
			relationship.LastAwardedXP = bonus;
		}

		relationship.BattlesTogether++;
		::MentorRookie.debugLog("valid battle counted mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " baseXP=" + baseXP + " bonusXP=" + bonus + " battles=" + relationship.BattlesTogether);
		this.ensureEffects(relationship);

		if (rookie.getLevel() >= mentor.getLevel())
		{
			toRemove.push({ MentorID = relationship.MentorID, Reason = "rookie_reached_mentor_level" });
		}
		else if (relationship.BattlesTogether >= ::MentorRookie.getSetting("BattlesBeforeGraduationCheck") && rookie.getLevel() >= ::MentorRookie.getSetting("GraduationRookieLevel"))
		{
			toRemove.push({ MentorID = relationship.MentorID, Reason = "graduated" });
		}
	}

	foreach (entry in toRemove)
	{
		this.removeRelationship(entry.MentorID, entry.Reason);
	}
}

function validateRelationships( _reason )
{
	local toRemove = [];
	foreach (key, relationship in this.Relationships)
	{
		local mentor = this.getActorByID(relationship.MentorID);
		local rookie = this.getActorByID(relationship.RookieID);

		if (mentor == null || rookie == null)
		{
			toRemove.push({ MentorID = relationship.MentorID, Reason = "missing_actor_" + _reason });
		}
		else if (rookie.getLevel() >= mentor.getLevel())
		{
			toRemove.push({ MentorID = relationship.MentorID, Reason = "rookie_reached_mentor_level" });
		}
		else
		{
			this.ensureEffects(relationship);
		}
	}

	foreach (entry in toRemove)
	{
		this.removeRelationship(entry.MentorID, entry.Reason);
	}
}
```

- [ ] **Step 4: Add persistence methods**

Add:

```squirrel
function serializeRelationships( _out )
{
	_out.writeU16(this.Relationships.len());
	foreach (relationship in this.Relationships)
	{
		_out.writeU32(relationship.MentorID);
		_out.writeU32(relationship.RookieID);
		_out.writeString(relationship.MentorName);
		_out.writeString(relationship.RookieName);
		_out.writeU16(relationship.BattlesTogether);
	}
}

function deserializeRelationships( _in )
{
	this.Relationships.clear();
	local count = _in.readU16();

	for (local i = 0; i < count; i++)
	{
		local relationship = {
			MentorID = _in.readU32(),
			RookieID = _in.readU32(),
			MentorName = _in.readString(),
			RookieName = _in.readString(),
			BattlesTogether = _in.readU16(),
			LastAwardedXP = 0
		};

		this.Relationships["" + relationship.MentorID] <- relationship;
	}

	this.validateRelationships("deserialize");
}
```

- [ ] **Step 5: Hook world state combat and save methods**

Inside the MSU queue in preload:

```squirrel
::MentorRookie.HooksMod.hook("scripts/states/world_state", function(q)
{
	q.onCombatStarted = @(__original) function()
	{
		::MentorRookie.Service.captureBeforeCombat();
		return __original();
	}

	q.onCombatFinished = @(__original) function()
	{
		local ret = __original();
		::MentorRookie.Service.handleAfterCombat();
		return ret;
	}

	q.onSerialize = @(__original) function( _out )
	{
		__original(_out);
		::MentorRookie.Service.serializeRelationships(_out);
	}

	q.onDeserialize = @(__original) function( _in )
	{
		__original(_in);
		::MentorRookie.Service.deserializeRelationships(_in);
	}
});
```

- [ ] **Step 6: Run validator**

Run validator.

Expected: PASS.

**Implementation note:** If `world_state.onCombatStarted` is not present in runtime, switch capture to the earliest stable tactical/world handoff found during implementation and document the change in README before code is finalized.

---

### Task 4: Master Mentor Perk Shell

**Files:**
- Create: `mod_mentor_rookie/scripts/skills/perks/master_mentor_perk.nut`
- Modify: `mod_mentor_rookie/scripts/config/z_mentor_rookie.nut`
- Modify: `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`

**Interfaces:**
- Produces: `perk.master_mentor`
- Produces: `::MentorRookie.registerPerks()`

- [ ] **Step 1: Extend validator for perk**

Append:

```powershell
Assert-File "scripts/skills/perks/master_mentor_perk.nut"
Assert-Contains "scripts/skills/perks/master_mentor_perk.nut" "perk.master_mentor"
Assert-Contains "scripts/config/z_mentor_rookie.nut" "registerPerks"
Assert-Contains "scripts/config/z_mentor_rookie.nut" "Master Mentor"
```

- [ ] **Step 2: Run validator to verify it fails**

Expected: FAIL on missing perk file.

- [ ] **Step 3: Add perk registration helper**

Append to `z_mentor_rookie.nut`:

```squirrel
::MentorRookie.registerPerks <- function()
{
	if (!::MentorRookie.getSetting("EnableMasterMentorPerk")) return;

	local perk = {
		ID = "perk.master_mentor",
		Script = "scripts/skills/perks/master_mentor_perk",
		Name = "Master Mentor",
		Tooltip = "This brother is skilled at mentoring rookies through battle experience.",
		Icon = "ui/perks/perk_31.png",
		IconDisabled = "ui/perks/perk_31_sw.png",
		Row = ::MentorRookie.getSetting("MasterMentorPerkRow")
	};

	perk.Unlocks <- perk.Row;
	perk.verifyPrerequisites <- function( _player, _tooltip )
	{
		return true;
	}

	if (!(perk.ID in ::Const.Perks.LookupMap))
	{
		::Const.Perks.LookupMap[perk.ID] <- perk;
	}
}
```

- [ ] **Step 4: Create perk skill**

Create:

```squirrel
this.master_mentor_perk <- this.inherit("scripts/skills/skill", {
	function create()
	{
		this.m.ID = "perk.master_mentor";
		this.m.Name = "Master Mentor";
		this.m.Description = "This brother is skilled at mentoring rookies through shared battle experience.";
		this.m.Icon = "ui/perks/perk_31.png";
		this.m.IconDisabled = "ui/perks/perk_31_sw.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
	}

	function getTooltip()
	{
		local ret = this.skill.getTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/xp_received.png",
			text = "Improves mentoring flavor and unlocks future mentoring expansions. The first release does not transfer talent stars or traits."
		});
		return ret;
	}
});
```

- [ ] **Step 5: Call perk registration**

In preload after settings registration:

```squirrel
::MentorRookie.registerPerks();
```

- [ ] **Step 6: Run validator**

Expected: PASS.

---

### Task 5: World Keybind Screen Backend and Frontend

**Files:**
- Create: `mod_mentor_rookie/scripts/ui/screens/world/mentor_rookie_screen.nut`
- Create: `mod_mentor_rookie/ui/mods/mentor_rookie_screen.js`
- Create: `mod_mentor_rookie/ui/mods/mentor_rookie_screen.css`
- Create: `mod_mentor_rookie/ui/mods/mentor_rookie.js`
- Create: `mod_mentor_rookie/ui/mods/mentor_rookie.css`
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`
- Modify: `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`

**Interfaces:**
- Produces: `MentorRookieScreen`
- Produces: `Service.queryAssignmentData() -> table`
- Produces: `Service.assignFromUI(_mentorID, _rookieID) -> table`

- [ ] **Step 1: Extend validator for UI**

Append:

```powershell
Assert-File "scripts/ui/screens/world/mentor_rookie_screen.nut"
Assert-File "ui/mods/mentor_rookie_screen.js"
Assert-File "ui/mods/mentor_rookie_screen.css"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "registerJS"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "registerCSS"
Assert-Contains "scripts/ui/screens/world/mentor_rookie_screen.nut" "queryAssignmentData"
Assert-Contains "ui/mods/mentor_rookie_screen.js" "registerScreen"
Assert-Contains "ui/mods/mentor_rookie_screen.js" "MentorRookieScreen"
```

- [ ] **Step 2: Add UI data helpers to service**

Add:

```squirrel
function queryAssignmentData()
{
	local mentors = [];
	local rookiesByMentor = {};
	if (!("World" in getroottable()) || ::World.getPlayerRoster() == null)
	{
		return { Mentors = mentors, RookiesByMentor = rookiesByMentor };
	}

	local roster = ::World.getPlayerRoster().getAll();
	foreach (mentor in roster)
	{
		if (!this.isEligibleMentor(mentor)) continue;

		local mentorID = mentor.getID();
		mentors.push({
			ID = mentorID,
			Name = mentor.getName(),
			Level = mentor.getLevel(),
			ImagePath = mentor.getImagePath(),
			ImageOffsetX = mentor.getImageOffsetX(),
			ImageOffsetY = mentor.getImageOffsetY(),
			BackgroundImagePath = mentor.getBackground().getIconColored()
		});

		rookiesByMentor["" + mentorID] <- [];
		foreach (rookie in roster)
		{
			if (!this.isEligibleRookie(mentor, rookie)) continue;

			rookiesByMentor["" + mentorID].push({
				ID = rookie.getID(),
				Name = rookie.getName(),
				Level = rookie.getLevel(),
				ImagePath = rookie.getImagePath(),
				ImageOffsetX = rookie.getImageOffsetX(),
				ImageOffsetY = rookie.getImageOffsetY(),
				BackgroundImagePath = rookie.getBackground().getIconColored()
			});
		}
	}

	return { Mentors = mentors, RookiesByMentor = rookiesByMentor };
}

function assignFromUI( _mentorID, _rookieID )
{
	return this.createRelationship(_mentorID, _rookieID);
}
```

- [ ] **Step 3: Create screen backend**

Create `scripts/ui/screens/world/mentor_rookie_screen.nut`:

```squirrel
this.mentor_rookie_screen <- {
	m = {
		JSHandle = null,
		Visible = false
	},

	function connect()
	{
		this.m.JSHandle = this.UI.connect("MentorRookieScreen", this);
	}

	function destroy()
	{
		if (this.m.JSHandle != null)
		{
			this.m.JSHandle = this.UI.disconnect(this.m.JSHandle);
		}
	}

	function show()
	{
		this.m.Visible = true;
		this.m.JSHandle.asyncCall("show", ::MentorRookie.Service.queryAssignmentData());
	}

	function hide()
	{
		this.m.Visible = false;
		this.m.JSHandle.asyncCall("hide", null);
	}

	function isVisible()
	{
		return this.m.Visible;
	}

	function onScreenConnected()
	{
	}

	function onScreenDisconnected()
	{
	}

	function onClose()
	{
		this.hide();
		::World.State.m.WorldScreen.show();
	}

	function onAssign( _data )
	{
		local result = ::MentorRookie.Service.assignFromUI(_data.MentorID, _data.RookieID);
		this.m.JSHandle.asyncCall("loadFromData", ::MentorRookie.Service.queryAssignmentData());
		return result;
	}
};
```

- [ ] **Step 4: Register screen and assets in preload**

Add in queue:

```squirrel
::Hooks.registerJS("ui/mods/mentor_rookie.js");
::Hooks.registerCSS("ui/mods/mentor_rookie.css");
::Hooks.registerJS("ui/mods/mentor_rookie_screen.js");
::Hooks.registerCSS("ui/mods/mentor_rookie_screen.css");

::MentorRookie.HooksMod.hook("scripts/states/world_state", function(q)
{
	q.create = @(__original) function()
	{
		__original();
		this.m.MentorRookieScreen <- this.new("scripts/ui/screens/world/mentor_rookie_screen");
		this.m.MentorRookieScreen.connect();
	}
});
```

If the world-state `create` hook conflicts with Task 3's world-state hook, merge them into one hook block instead of registering two separate hook blocks.

- [ ] **Step 5: Add keybind behavior**

Use `mod_bro_editor/scripts/!mods_preload/mod_breditor.nut` as the reference. Add a world key handler that opens the screen only when no blocking menus are visible:

```squirrel
// Use the same world screen visibility guards as mod_bro_editor where possible.
// Default key should be documented in README after the final keybinding mechanism is confirmed.
```

Runtime keybinding APIs vary by MSU/keybind setup; if this repo already exposes an MSU keybind helper during implementation, use it. If not, hook the same vanilla key event route used by `mod_bro_editor` and document the exact key.

- [ ] **Step 6: Create JS/CSS**

Create a minimal two-column screen:

```javascript
"use strict";

var MentorRookieScreen = function()
{
	this.mSQHandle = null;
	this.mContainer = null;
	this.mMentorList = null;
	this.mRookieList = null;
	this.mData = null;
	this.mSelectedMentorID = null;
};

MentorRookieScreen.prototype.onConnection = function (_handle)
{
	this.mSQHandle = _handle;
	this.register($('.root-screen'));
};

MentorRookieScreen.prototype.onDisconnection = function()
{
	this.mSQHandle = null;
	this.unregister();
};

MentorRookieScreen.prototype.register = function(_parentDiv)
{
	if (this.mContainer !== null) return;
	this.mContainer = $('<div class="mentor-rookie-screen display-none opacity-none"/>');
	_parentDiv.append(this.mContainer);
	this.mContainer.append($('<div class="mentor-rookie-dialog"><div class="title title-font-big font-bold font-color-title">Mentor Rookie</div><div class="mentor-rookie-columns"><div class="mentor-list"></div><div class="rookie-list"></div></div><div class="mentor-rookie-footer"></div></div>'));
	this.mMentorList = this.mContainer.find('.mentor-list');
	this.mRookieList = this.mContainer.find('.rookie-list');
	var self = this;
	this.mContainer.find('.mentor-rookie-footer').createTextButton('Close', function() { SQ.call(self.mSQHandle, 'onClose'); }, '', 1);
};

MentorRookieScreen.prototype.unregister = function()
{
	if (this.mContainer === null) return;
	this.mContainer.remove();
	this.mContainer = null;
};

MentorRookieScreen.prototype.loadFromData = function(_data)
{
	this.mData = _data;
	this.mMentorList.empty();
	this.mRookieList.empty();
	var self = this;
	for (var i = 0; i < _data.Mentors.length; i++)
	{
		var mentor = _data.Mentors[i];
		var row = $('<div class="mentor-row text-font-normal"/>').text(mentor.Name + ' (Level ' + mentor.Level + ')');
		row.data('id', mentor.ID);
		row.on('click', function()
		{
			self.mSelectedMentorID = $(this).data('id');
			self.renderRookies();
		});
		this.mMentorList.append(row);
	}
};

MentorRookieScreen.prototype.renderRookies = function()
{
	this.mRookieList.empty();
	var self = this;
	var rows = this.mData.RookiesByMentor['' + this.mSelectedMentorID] || [];
	for (var i = 0; i < rows.length; i++)
	{
		var rookie = rows[i];
		var row = $('<div class="rookie-row text-font-normal"/>').text(rookie.Name + ' (Level ' + rookie.Level + ')');
		row.data('id', rookie.ID);
		row.on('click', function()
		{
			SQ.call(self.mSQHandle, 'onAssign', { MentorID: self.mSelectedMentorID, RookieID: $(this).data('id') });
		});
		this.mRookieList.append(row);
	}
};

MentorRookieScreen.prototype.show = function(_data)
{
	this.loadFromData(_data);
	this.mContainer.removeClass('display-none').addClass('display-block').css({ opacity: 1 });
};

MentorRookieScreen.prototype.hide = function()
{
	this.mContainer.removeClass('display-block').addClass('display-none').css({ opacity: 0 });
};

registerScreen("MentorRookieScreen", new MentorRookieScreen());
```

Create CSS with fixed readable layout:

```css
.mentor-rookie-screen {
	position: absolute;
	left: 0;
	top: 0;
	width: 100%;
	height: 100%;
	background-color: rgba(0, 0, 0, 0.65);
	z-index: 10;
}

.mentor-rookie-dialog {
	position: absolute;
	left: 50%;
	top: 50%;
	width: 76rem;
	height: 56rem;
	margin-left: -38rem;
	margin-top: -28rem;
	padding: 2rem;
	background-image: url("coui://gfx/ui/skin/dialog_background_01.png");
	background-size: 100% 100%;
}

.mentor-rookie-columns {
	width: 100%;
	height: 42rem;
	display: flex;
	gap: 2rem;
	margin-top: 2rem;
}

.mentor-list,
.rookie-list {
	flex: 1;
	overflow-y: auto;
}

.mentor-row,
.rookie-row {
	height: 3rem;
	line-height: 3rem;
	padding-left: 1rem;
	color: #d7c69a;
	cursor: pointer;
}

.mentor-row:hover,
.rookie-row:hover {
	background-color: rgba(129, 50, 24, 0.8);
}

.mentor-rookie-footer {
	height: 5rem;
	text-align: center;
}
```

Create empty bootstrap/shared files if required by `registerJS/registerCSS`:

```javascript
"use strict";
```

```css
```

- [ ] **Step 7: Run validator**

Expected: PASS.

---

### Task 6: Manual Test Matrix, README Finalization, and Build

**Files:**
- Create: `mod_mentor_rookie/test-results/mentor-rookie-manual-matrix.md`
- Modify: `mod_mentor_rookie/README.md`
- Modify: `mod_mentor_rookie/tools/validate_mentor_rookie_layout.ps1`

**Interfaces:**
- Produces manual validation checklist.
- Produces final documented assumptions.

- [ ] **Step 1: Create manual matrix**

Create:

```markdown
# Mentor Rookie Manual Test Matrix

| Scenario | Setup | Expected result |
|---|---|---|
| Eligible assignment | Mentor level 6+, rookie lower level | Relationship is created; both effects appear |
| Invalid mentor | Mentor below configured minimum level | Mentor does not appear in mentor list |
| Invalid rookie same/higher level | Rookie level >= mentor level | Rookie does not appear for that mentor |
| One-to-one mentor | Mentor already assigned | Mentor does not appear for second assignment |
| One-to-one rookie | Rookie already assigned | Rookie does not appear for another mentor |
| Valid battle together | Both participate and survive | BattlesTogether increments; bonus XP logged |
| Reserve rookie | Mentor fights, rookie reserve | Battle ignored; no XP bonus |
| Reserve mentor | Rookie fights, mentor reserve | Battle ignored; no XP bonus |
| Rookie catches mentor | Rookie reaches mentor level | Relationship graduates/removes immediately |
| Normal graduation | 50+ valid battles and rookie reaches level 10 | Relationship graduates/removes |
| Save/load | Save with relationship, reload | Relationship persists and effects are restored |
| Death/removal | Mentor or rookie dies/leaves | Relationship is removed with debug reason |
```

- [ ] **Step 2: Extend validator for documentation**

Append:

```powershell
Assert-File "test-results/mentor-rookie-manual-matrix.md"
Assert-Contains "README.md" "Bonus XP is calculated from the rookie's vanilla battle XP gained"
Assert-Contains "README.md" "Talent star transfer is not implemented"
Assert-Contains "README.md" "Trait transfer is not implemented"
Assert-Contains "test-results/mentor-rookie-manual-matrix.md" "Valid battle together"
```

- [ ] **Step 3: Finalize README**

Update README to include:

```markdown
## Settings

- `DebugLogging`: default true for first release.
- `MinimumMentorLevel`: default 6.
- `MaximumRookieLevel`: default 10.
- `Level1To3XPBonusPercent`: default 20.
- `Level4To6XPBonusPercent`: default 15.
- `Level7To10XPBonusPercent`: default 12.
- `BattlesBeforeGraduationCheck`: default 50.
- `GraduationRookieLevel`: default 10.

## XP Formula

Bonus XP is calculated from the rookie's vanilla battle XP gained:

`bonusXP = floor(rookieBattleXP * configuredPercent / 100)`

The bonus is applied with `addXP(bonusXP, false)` so it is not scaled twice by vanilla difficulty/global XP multipliers.
```

- [ ] **Step 4: Run static validator**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_mentor_rookie\tools\validate_mentor_rookie_layout.ps1
```

Expected: PASS.

- [ ] **Step 5: Build with modbb**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds using the project CLI. Do not manually zip files.

- [ ] **Step 6: Manual runtime checks**

Run the game, enable debug logging, and inspect:

```text
C:\Users\gujar\Documents\Battle Brothers\log.html
```

Expected log lines include:

```text
[MentorRookie] settings registered
[MentorRookie] relationship created
[MentorRookie] captured pre-combat XP for roster
[MentorRookie] valid battle counted
[MentorRookie] relationship removed
```

---

## Self-Review

- Spec coverage: covered one-to-one relationship, battle-based progress, XP bonuses, effects, keybind UI, MSU settings, debug logs, graduation by level 10 after 50 battles, immediate graduation when rookie reaches mentor level, and no star/trait transfer.
- Placeholder scan: no `TBD` or `TODO` remains. One runtime uncertainty is explicitly documented as an implementation note for `world_state.onCombatStarted`.
- Type consistency: service method names are consistent across tasks: `createRelationship`, `removeRelationship`, `queryAssignmentData`, `captureBeforeCombat`, `handleAfterCombat`, `serializeRelationships`, `deserializeRelationships`.
