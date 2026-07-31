# Stale Relationship Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove invalid active mentor-rookie relationships when either partner no longer exists in `World.getPlayerRoster().getAll()`, preventing status tooltips from showing `Unknown`.

**Architecture:** Keep tooltip rendering simple and make relationship validity the source of truth. Add a service-level repair pass that scans active mentor/rookie flags, clears invalid active relationship state from surviving brothers, and logs the reason. Call the repair pass from existing safe entry points where relationship data is rebuilt or displayed.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks/MSU, existing `MentorRookie.Service`, existing `MentorRookie.Helpers.debugLog`, manual in-game verification through `C:\Users\gujar\Documents\Battle Brothers\log.html`.

## Global Constraints

- Work only inside `mod_mentor_rookie`.
- Do not modify `data_001`.
- Do not modify community mod folders.
- Write docs first before making code changes.
- Use `modbb` for builds; do not manually create zip files.
- Keep debug logs configurable through the existing `DebugLogging` setting.
- Do not hide stale relationships by storing only a partner display name in the tooltip.
- Preserve pair history flags; only active relationship flags/effects should be removed.
- Preserve current one-active-mentor and one-active-rookie validation rules.

---

## File Structure

- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
  - Add active relationship repair helpers.
  - Call repair before rebuilding/querying relationship data.
  - Keep relationship history untouched.

- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`
  - Optionally call repair when opening the Mentor Rookie screen if the service call location alone is not enough.

- Modify: `mod_mentor_rookie/docs/testing_list.md`
  - Add manual test cases for dismissed/dead/removed partner cleanup.

- Optionally modify: `mod_mentor_rookie/README.md`
  - Add a short known behavior note only if implementation makes a runtime assumption that cannot be fully proven from code.

---

### Task 1: Add Active Relationship Repair Helpers

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Consumes: `::MentorRookie.Helpers.getActorByID(_actorID)`
- Consumes: `::MentorRookie.Helpers.hasSkill(_actor, _skillID)`
- Consumes: `this.clearRelationshipFlags(_actor)`
- Produces: `::MentorRookie.Service.clearRelationshipWithoutRebuild(_mentor, _rookie)`
- Produces: `::MentorRookie.Service.clearStaleRelationshipActor(_actor, _reason)`
- Produces: `::MentorRookie.Service.repairStaleRelationshipFlags()`

- [ ] **Step 1: Add a no-rebuild relationship clearing helper**

Add this near `clearRelationshipFlags(_actor)`:

```squirrel
function clearRelationshipWithoutRebuild( _mentor, _rookie )
{
	if (_mentor != null)
	{
		this.clearRelationshipFlags(_mentor);
		_mentor.getSkills().removeByID("effects.mentor_rookie_mentor");
	}

	if (_rookie != null)
	{
		this.clearRelationshipFlags(_rookie);
		_rookie.getSkills().removeByID("effects.mentor_rookie_rookie");
	}
}
```

Reason: `clearRelationship()` currently calls `rebuildRelationshipsFromRoster()`. The repair loop must clear bad state without recursively rebuilding while it is already scanning roster flags.

- [ ] **Step 2: Update existing `clearRelationship` to use the helper**

Replace the body of `clearRelationship(_mentor, _rookie)` with:

```squirrel
function clearRelationship( _mentor, _rookie )
{
	this.clearRelationshipWithoutRebuild(_mentor, _rookie);
	this.rebuildRelationshipsFromRoster();
}
```

Expected behavior: manual relationship removal and graduation still clear both effects and active flags, then rebuild active rows as before.

- [ ] **Step 3: Add a single-actor stale cleanup helper**

Add this after `clearRelationshipWithoutRebuild(...)`:

```squirrel
function clearStaleRelationshipActor( _actor, _reason )
{
	if (_actor == null) return;

	local role = _actor.getFlags().has("MentorRookieRole") ? _actor.getFlags().get("MentorRookieRole") : "none";
	local partnerID = _actor.getFlags().has("MentorRookiePartnerID") ? _actor.getFlags().get("MentorRookiePartnerID") : -1;

	::MentorRookie.Helpers.debugLog("cleared stale relationship actor=" + _actor.getName() + " actorID=" + _actor.getID() + " role=" + role + " missingPartnerID=" + partnerID + " reason=" + _reason);

	this.clearRelationshipFlags(_actor);

	if (role == "mentor")
	{
		_actor.getSkills().removeByID("effects.mentor_rookie_mentor");
	}
	else if (role == "rookie")
	{
		_actor.getSkills().removeByID("effects.mentor_rookie_rookie");
	}
}
```

Expected log format:

```text
[MentorRookie] cleared stale relationship actor=Ottmar actorID=123 role=mentor missingPartnerID=456 reason=partner_not_in_roster
```

- [ ] **Step 4: Add full repair scan**

Add this after `clearStaleRelationshipActor(...)`:

```squirrel
function repairStaleRelationshipFlags()
{
	if (!("World" in getroottable()) || ::World.getPlayerRoster() == null) return;

	local roster = ::World.getPlayerRoster().getAll();

	foreach (bro in roster)
	{
		if (!bro.getFlags().has("MentorRookieRole")) continue;
		if (!bro.getFlags().has("MentorRookiePartnerID"))
		{
			this.clearStaleRelationshipActor(bro, "missing_partner_flag");
			continue;
		}

		local role = bro.getFlags().get("MentorRookieRole");
		local partner = ::MentorRookie.Helpers.getActorByID(bro.getFlags().get("MentorRookiePartnerID"));

		if (partner == null)
		{
			this.clearStaleRelationshipActor(bro, "partner_not_in_roster");
			continue;
		}

		if (!partner.getFlags().has("MentorRookieRole") || !partner.getFlags().has("MentorRookiePartnerID"))
		{
			this.clearStaleRelationshipActor(bro, "partner_missing_relationship_flags");
			this.clearStaleRelationshipActor(partner, "partner_missing_relationship_flags");
			continue;
		}

		local partnerRole = partner.getFlags().get("MentorRookieRole");
		local partnerID = partner.getFlags().get("MentorRookiePartnerID");

		if (role == "mentor" && partnerRole != "rookie")
		{
			this.clearStaleRelationshipActor(bro, "partner_role_mismatch");
			this.clearStaleRelationshipActor(partner, "partner_role_mismatch");
			continue;
		}

		if (role == "rookie" && partnerRole != "mentor")
		{
			this.clearStaleRelationshipActor(bro, "partner_role_mismatch");
			this.clearStaleRelationshipActor(partner, "partner_role_mismatch");
			continue;
		}

		if (partnerID != bro.getID())
		{
			this.clearStaleRelationshipActor(bro, "partner_points_elsewhere");
			this.clearStaleRelationshipActor(partner, "partner_points_elsewhere");
			continue;
		}
	}
}
```

Expected behavior:
- If a mentor points to a missing rookie, only the mentor is cleaned.
- If both actors exist but flags disagree, both sides are cleaned.
- Pair history flags named `MentorRookieHistory_*` are not removed.

- [ ] **Step 5: Run static search**

Run:

```powershell
rg "clearRelationshipWithoutRebuild|clearStaleRelationshipActor|repairStaleRelationshipFlags|cleared stale relationship" mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut -n
```

Expected: all new helper names and the log string appear exactly once, except helper calls which appear multiple times.

---

### Task 2: Call Repair From Safe Relationship Entry Points

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
- Optionally modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`

**Interfaces:**
- Consumes: `repairStaleRelationshipFlags()` from Task 1
- Produces: repaired state before screen data, relationship rows, and post-combat processing

- [ ] **Step 1: Call repair before roster rows are built**

At the start of `getRosterRows()`, after the world/roster null guard, add:

```squirrel
this.repairStaleRelationshipFlags();
```

Expected behavior: the assignment screen does not show stale `IsMentor` or `IsRookie` markers after a partner disappears.

- [ ] **Step 2: Call repair before relationships are rebuilt**

At the start of `rebuildRelationshipsFromRoster()`, after the world/roster null guard and before iterating roster, add:

```squirrel
this.repairStaleRelationshipFlags();
```

Expected behavior: relationship rows are based only on valid mirrored flags.

- [ ] **Step 3: Avoid infinite recursion**

Confirm `repairStaleRelationshipFlags()` does not call `rebuildRelationshipsFromRoster()` and does not call `clearRelationship()`.

Run:

```powershell
Select-String -Path mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut -Pattern "function repairStaleRelationshipFlags|rebuildRelationshipsFromRoster\\(|clearRelationship\\("
```

Expected: inside `repairStaleRelationshipFlags`, there is no call to `rebuildRelationshipsFromRoster()` or `clearRelationship()`.

- [ ] **Step 4: Optional screen-open call only if needed**

If in-game testing shows tooltip can be opened before `getRosterRows()` or `rebuildRelationshipsFromRoster()` runs, add this near the start of `::MentorRookie.openScreen()` after world state validation:

```squirrel
::MentorRookie.Service.repairStaleRelationshipFlags();
```

Expected behavior: pressing `shift+m` repairs stale flags before the custom screen displays.

Do not add this optional call if Task 2 Steps 1-2 already repair before all tested stale tooltip paths.

---

### Task 3: Keep Tooltip Behavior As A Canary

**Files:**
- Inspect only: `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_mentor_effect.nut`
- Inspect only: `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_rookie_effect.nut`

**Interfaces:**
- Consumes: valid active flags maintained by `repairStaleRelationshipFlags()`
- Produces: no tooltip masking changes

- [ ] **Step 1: Confirm mentor tooltip still uses actor lookup**

Check:

```powershell
Select-String -Path mod_mentor_rookie/scripts/skills/effects/mentor_rookie_mentor_effect.nut -Pattern "getActorByID|Unknown"
```

Expected:

```text
rookie = ::MentorRookie.Helpers.getActorByID(actor.getFlags().get("MentorRookiePartnerID"));
text = "Rookie: ... " + (rookie != null ? rookie.getName() : "Unknown") + ...
```

- [ ] **Step 2: Confirm rookie tooltip still uses actor lookup**

Check:

```powershell
Select-String -Path mod_mentor_rookie/scripts/skills/effects/mentor_rookie_rookie_effect.nut -Pattern "getActorByID|Unknown"
```

Expected:

```text
mentor = ::MentorRookie.Helpers.getActorByID(actor.getFlags().get("MentorRookiePartnerID"));
text = "Mentor: ... " + (mentor != null ? mentor.getName() : "Unknown") + ...
```

Reason: if `Unknown` appears after repair is implemented, that means stale active flags still exist and should be investigated. The tooltip should not hide this state.

---

### Task 4: Add Manual Test Coverage

**Files:**
- Modify: `mod_mentor_rookie/docs/testing_list.md`

**Interfaces:**
- Consumes: debug log emitted by `clearStaleRelationshipActor(_actor, _reason)`
- Produces: manual verification checklist for stale relationship cleanup

- [ ] **Step 1: Add stale relationship test section**

Append this section to `testing_list.md`:

```markdown
## Stale Relationship Cleanup

- [ ] Create a mentor-rookie relationship.
- [ ] Confirm both brothers show Mentor/Rookie passive effects.
- [ ] Dismiss the rookie from the character screen.
- [ ] Reopen the Mentor Rookie screen.
- [ ] Confirm the mentor passive effect is removed.
- [ ] Confirm the active relationship no longer appears.
- [ ] Confirm `log.html` contains `cleared stale relationship` with `reason=partner_not_in_roster`.
- [ ] Create a second mentor-rookie relationship.
- [ ] Kill the rookie in battle.
- [ ] Return to world map.
- [ ] Confirm the mentor passive effect is removed after combat.
- [ ] Confirm `log.html` contains `cleared stale relationship`.
- [ ] Confirm pair history still works if the same surviving mentor is later paired with a valid rookie.
```

- [ ] **Step 2: Add exact log check command**

Add this command below the stale cleanup section:

```markdown
Log check command:

```powershell
$html = Get-Content -Raw -Path "C:\Users\gujar\Documents\Battle Brothers\log.html"
[regex]::Matches($html, '<div class="time">(?<time>.*?)</div><div class="tag">(?<tag>.*?)</div><div class="text">(?<text>.*?)</div>') | ForEach-Object {
	$raw = $_.Groups['text'].Value
	$clean = ($raw -replace '<br>',' ' -replace '<.*?>','')
	$text = [System.Net.WebUtility]::HtmlDecode($clean)
	if ($text -match 'MentorRookie|cleared stale relationship|partner_not_in_roster') {
		"{0} [{1}] {2}" -f $_.Groups['time'].Value, $_.Groups['tag'].Value, $text
	}
}
```
```

Expected output includes:

```text
[MentorRookie] cleared stale relationship actor=Ottmar actorID=... role=mentor missingPartnerID=... reason=partner_not_in_roster
```

---

### Task 5: Build And Runtime Verification

**Files:**
- No source changes beyond Tasks 1-4

**Interfaces:**
- Consumes: `modbb`
- Consumes: Battle Brothers runtime log at `C:\Users\gujar\Documents\Battle Brothers\log.html`
- Produces: verified mod build and runtime evidence

- [ ] **Step 1: Run code search verification**

Run:

```powershell
rg "repairStaleRelationshipFlags|clearStaleRelationshipActor|cleared stale relationship|partner_not_in_roster" mod_mentor_rookie -n
```

Expected: matches in `mentor_rookie_service.nut` and `testing_list.md`.

- [ ] **Step 2: Build with modbb**

Run:

```powershell
cd mod_mentor_rookie
modbb --game-data-dir test-results\build-stale-relationship-cleanup
```

Expected: build succeeds and deploys `mod_mentor_rookie.zip` to `test-results\build-stale-relationship-cleanup`.

- [ ] **Step 3: Runtime test with a dismissed rookie**

In game:
- Create a mentor-rookie pair.
- Dismiss the rookie.
- Open the Mentor Rookie screen or trigger a relationship rebuild.
- Inspect the mentor status tooltip.

Expected:
- Mentor status effect is removed from the surviving mentor.
- Tooltip no longer has a chance to show `Rookie: Unknown` because the stale mentor effect is gone.
- `log.html` includes `cleared stale relationship` and `reason=partner_not_in_roster`.

- [ ] **Step 4: Runtime test with a dead rookie**

In game:
- Create a mentor-rookie pair.
- Kill the rookie in combat.
- Return to world map.
- Open the Mentor Rookie screen or inspect the mentor after post-combat processing.

Expected:
- Mentor status effect is removed from the surviving mentor.
- Active relationship no longer appears.
- `log.html` includes `cleared stale relationship`.

- [ ] **Step 5: Regression checks**

In game:
- Create a normal valid mentor-rookie pair.
- Confirm both effects appear.
- Fight a valid battle with both alive.
- Confirm XP/focused training logs still use the correct mentor and rookie names.
- Remove the relationship manually from the Mentor Rookie screen.

Expected:
- Normal relationship creation still works.
- Valid battle processing still works.
- Manual removal still preserves pair history.
- No new `Unknown` tooltip appears for valid pairs.

---

## Self-Review

- Spec coverage: covers stale partner IDs, dismissed rookies, dead rookies, event/mod removals through repair scanning, debug logs, docs-first workflow, and preserving active tooltip behavior as a signal instead of masking it.
- Placeholder scan: no `TBD`, `TODO`, or unspecified implementation steps remain.
- Type consistency: helper names are consistent across tasks: `clearRelationshipWithoutRebuild`, `clearStaleRelationshipActor`, and `repairStaleRelationshipFlags`.
- Risk: calling repair from `getRosterRows()` and `rebuildRelationshipsFromRoster()` may perform duplicate scans when the Mentor Rookie screen opens. Roster size is small, and this is acceptable unless runtime profiling shows a problem.
- Assumption to verify in-game: a dismissed/dead partner is absent from `World.getPlayerRoster().getAll()` by the time repair runs. This matches vanilla removal paths inspected in `data_001`, but still needs runtime confirmation in `log.html`.
