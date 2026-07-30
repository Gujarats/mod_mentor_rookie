# Pair-Specific Relationship History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve mentor-rookie battle and focused-training progress when the same mentor and rookie are removed and later re-coupled.

**Architecture:** Keep current active relationship flags for UI/effects/runtime reconstruction, but add a separate pair-specific history record stored on both actors. The history key is based on `mentorID:rookieID`, so Mentor A + Rookie B has different saved progress from Mentor C + Rookie B. Removing a relationship clears active role/link/effect flags only; it does not delete pair history.

**Tech Stack:** Battle Brothers Squirrel `.nut` scripts, existing Modern Hooks/MSU mod structure, Markdown documentation, `modbb` build workflow.

## Global Constraints

- Use the current active branch; do not create or switch branches.
- Work only inside `mod_mentor_rookie`.
- Do not modify `data_001`; it is vanilla reference code only.
- Do not modify community mods.
- Preserve current one-active-mentor and one-active-rookie validation rules.
- Preserve existing active relationship UI behavior.
- Preserve existing Focused Training UI and reward behavior.
- Pair history must be pair-specific, not rookie-global.
- Removing a relationship must not reset previous battles or focused-training gain for the same mentor-rookie pair.
- Graduation should remain a final relationship end and should clear active relationship state. Whether graduation deletes pair history is intentionally not required for this change; preserve history unless a later design says otherwise.

---

## File Structure

- Modify `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
  Add pair-history key helpers, history read/write helpers, preserve history on remove, restore history on create, and update history after battle/focus changes.

- Modify `mod_mentor_rookie/README.md`
  Explain that removing and re-coupling the same pair preserves pair-specific history.

- Modify `mod_mentor_rookie/docs/testing_list.md`
  Add manual tests for remove/re-couple persistence and pair-specific anti-exploit behavior.

---

### Task 1: Add Pair-History Key And Read/Write Helpers

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Produces: `::MentorRookie.Service.getPairHistoryKey(_mentorID, _rookieID)`
- Produces: `::MentorRookie.Service.getPairHistoryPrefix(_mentorID, _rookieID)`
- Produces: `::MentorRookie.Service.readPairHistory(_mentor, _rookie)`
- Produces: `::MentorRookie.Service.writePairHistory(_mentor, _rookie, _battles, _focusAttributeID = null, _focusedTrainingBattles = 0, _focusedTrainingGain = 0)`
- Consumes: actor flags from `_mentor.getFlags()` and `_rookie.getFlags()`

- [ ] **Step 1: Add pair key helper**

Add near other service helper methods:

```nut
function getPairHistoryKey( _mentorID, _rookieID )
{
	return "" + _mentorID + ":" + _rookieID;
}
```

- [ ] **Step 2: Add flag prefix helper**

Add this method after `getPairHistoryKey`:

```nut
function getPairHistoryPrefix( _mentorID, _rookieID )
{
	return "MentorRookieHistory_" + _mentorID + "_" + _rookieID + "_";
}
```

The exact prefix for mentor ID `10` and rookie ID `20` is:

```text
MentorRookieHistory_10_20_
```

- [ ] **Step 3: Add history read helper**

Add this method after `getPairHistoryPrefix`:

```nut
function readPairHistory( _mentor, _rookie )
{
	local empty = {
		BattlesTogether = 0,
		FocusAttributeID = null,
		FocusedTrainingBattles = 0,
		FocusedTrainingGain = 0
	};

	if (_mentor == null || _rookie == null) return empty;

	local prefix = this.getPairHistoryPrefix(_mentor.getID(), _rookie.getID());
	local flags = _rookie.getFlags();

	if (!flags.has(prefix + "BattlesTogether"))
	{
		return empty;
	}

	return {
		BattlesTogether = flags.get(prefix + "BattlesTogether"),
		FocusAttributeID = flags.has(prefix + "FocusAttributeID") ? flags.get(prefix + "FocusAttributeID") : null,
		FocusedTrainingBattles = flags.has(prefix + "FocusedTrainingBattles") ? flags.get(prefix + "FocusedTrainingBattles") : 0,
		FocusedTrainingGain = flags.has(prefix + "FocusedTrainingGain") ? flags.get(prefix + "FocusedTrainingGain") : 0
	};
}
```

Reasoning: read from the rookie because re-coupling starts from selecting a rookie, and rookie history should travel with that rookie in the save. The same data will also be written to mentor flags as a backup/debug convenience.

- [ ] **Step 4: Add history write helper**

Add this method after `readPairHistory`:

```nut
function writePairHistory( _mentor, _rookie, _battles, _focusAttributeID = null, _focusedTrainingBattles = 0, _focusedTrainingGain = 0 )
{
	if (_mentor == null || _rookie == null) return;

	local prefix = this.getPairHistoryPrefix(_mentor.getID(), _rookie.getID());
	local mentorFlags = _mentor.getFlags();
	local rookieFlags = _rookie.getFlags();

	mentorFlags.set(prefix + "BattlesTogether", _battles);
	mentorFlags.set(prefix + "FocusedTrainingBattles", _focusedTrainingBattles);
	mentorFlags.set(prefix + "FocusedTrainingGain", _focusedTrainingGain);

	rookieFlags.set(prefix + "BattlesTogether", _battles);
	rookieFlags.set(prefix + "FocusedTrainingBattles", _focusedTrainingBattles);
	rookieFlags.set(prefix + "FocusedTrainingGain", _focusedTrainingGain);

	if (_focusAttributeID != null)
	{
		mentorFlags.set(prefix + "FocusAttributeID", _focusAttributeID);
		rookieFlags.set(prefix + "FocusAttributeID", _focusAttributeID);
	}
	else
	{
		mentorFlags.remove(prefix + "FocusAttributeID");
		rookieFlags.remove(prefix + "FocusAttributeID");
	}

	::MentorRookie.Helpers.debugLog("pair history saved key=" + this.getPairHistoryKey(_mentor.getID(), _rookie.getID()) + " battles=" + _battles + " focus=" + (_focusAttributeID == null ? "<none>" : _focusAttributeID) + " trainingBattles=" + _focusedTrainingBattles + " trainingGain=" + _focusedTrainingGain);
}
```

- [ ] **Step 5: Build check**

Run:

```powershell
modbb --game-data-dir test-results\build-pair-history-helpers
```

Expected: build succeeds with no Squirrel syntax errors.

---

### Task 2: Restore History When Creating The Same Pair

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Consumes: `readPairHistory(_mentor, _rookie)` from Task 1
- Consumes: `writeRelationshipFlags(_mentor, _rookie, _battles, _focusAttributeID = null, _focusedTrainingBattles = 0, _focusedTrainingGain = 0)`
- Produces: `createRelationship(_mentorID, _rookieID)` restores previous pair progress

- [ ] **Step 1: Replace zero initialization in `createRelationship`**

Find this block:

```nut
this.Relationships.push({
	MentorID = mentor.getID(),
	RookieID = rookie.getID(),
	BattlesTogether = 0,
	FocusAttributeID = null,
	FocusedTrainingBattles = 0,
	FocusedTrainingGain = 0
});
this.writeRelationshipFlags(mentor, rookie, 0);
```

Replace it with:

```nut
local history = this.readPairHistory(mentor, rookie);

this.Relationships.push({
	MentorID = mentor.getID(),
	RookieID = rookie.getID(),
	BattlesTogether = history.BattlesTogether,
	FocusAttributeID = history.FocusAttributeID,
	FocusedTrainingBattles = history.FocusedTrainingBattles,
	FocusedTrainingGain = history.FocusedTrainingGain
});
this.writeRelationshipFlags(mentor, rookie, history.BattlesTogether, history.FocusAttributeID, history.FocusedTrainingBattles, history.FocusedTrainingGain);
```

- [ ] **Step 2: Add restore debug log**

After `writeRelationshipFlags(...)`, add:

```nut
::MentorRookie.Helpers.debugLog("relationship history restored mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " battles=" + history.BattlesTogether + " focus=" + (history.FocusAttributeID == null ? "<none>" : history.FocusAttributeID) + " trainingBattles=" + history.FocusedTrainingBattles + " trainingGain=" + history.FocusedTrainingGain);
```

- [ ] **Step 3: Keep existing relationship effects**

Do not change:

```nut
this.ensureRelationshipEffects(mentor, rookie);
```

Expected behavior: restored relationships still get Mentor/Rookie passive effects immediately after re-coupling.

- [ ] **Step 4: Build check**

Run:

```powershell
modbb --game-data-dir test-results\build-pair-history-create
```

Expected: build succeeds. A brand-new pair with no history still starts at `0` because `readPairHistory` returns empty defaults.

---

### Task 3: Save History Whenever Relationship State Changes

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Consumes: `writePairHistory(_mentor, _rookie, _battles, _focusAttributeID = null, _focusedTrainingBattles = 0, _focusedTrainingGain = 0)` from Task 1
- Consumes: existing `writeRelationshipFlags(...)`
- Produces: pair history stays current after focus selection and after combat progress

- [ ] **Step 1: Save history after focus selection**

In `setRelationshipFocusAttribute`, find:

```nut
this.writeRelationshipFlags(mentor, rookie, rel.BattlesTogether, _focusAttributeID, 0, 0);
```

Add this immediately after it:

```nut
this.writePairHistory(mentor, rookie, rel.BattlesTogether, _focusAttributeID, 0, 0);
```

Expected: if the player removes and re-couples after choosing focus, the locked focus returns.

- [ ] **Step 2: Save history after battle processing**

In `handleAfterCombat`, find the existing write call:

```nut
this.writeRelationshipFlags(mentor, rookie, rel.BattlesTogether, rel.FocusAttributeID, rel.FocusedTrainingBattles, rel.FocusedTrainingGain);
```

Add this immediately after it:

```nut
this.writePairHistory(mentor, rookie, rel.BattlesTogether, rel.FocusAttributeID, rel.FocusedTrainingBattles, rel.FocusedTrainingGain);
```

Expected: battle count, focused-training progress, and focused-training gain are persisted after every valid battle.

- [ ] **Step 3: Save history on relationship creation**

In `createRelationship`, after the new `writeRelationshipFlags(...)` call from Task 2, add:

```nut
this.writePairHistory(mentor, rookie, history.BattlesTogether, history.FocusAttributeID, history.FocusedTrainingBattles, history.FocusedTrainingGain);
```

Expected: first-time creation writes an initial history record with zero values, making later restore behavior explicit.

- [ ] **Step 4: Build check**

Run:

```powershell
modbb --game-data-dir test-results\build-pair-history-save
```

Expected: build succeeds and debug logs include `pair history saved` after creation, focus selection, and valid battle processing.

---

### Task 4: Make Remove Clear Only Active Relationship State

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Consumes: active relationship flags written by `writeRelationshipFlags(...)`
- Produces: `removeRelationshipByRookieID(_rookieID)` preserves pair history flags

- [ ] **Step 1: Confirm active clear helper only removes active flags**

Keep `clearRelationshipFlags(_actor)` removing only active relationship flags:

```nut
_actor.getFlags().remove("MentorRookieRole");
_actor.getFlags().remove("MentorRookiePartnerID");
_actor.getFlags().remove("MentorRookieBattlesTogether");
_actor.getFlags().remove("MentorRookieFocusAttributeID");
_actor.getFlags().remove("MentorRookieFocusedTrainingBattles");
_actor.getFlags().remove("MentorRookieFocusedTrainingGain");
```

Do not add removal for flags beginning with:

```text
MentorRookieHistory_
```

- [ ] **Step 2: Save current active state before clearing**

In `removeRelationshipByRookieID`, before this line:

```nut
this.clearRelationship(mentor, rookie);
```

Add:

```nut
this.writePairHistory(mentor, rookie, rel.BattlesTogether, rel.FocusAttributeID, rel.FocusedTrainingBattles, rel.FocusedTrainingGain);
```

Expected: pressing Remove saves the latest active state immediately before clearing active flags/effects.

- [ ] **Step 3: Improve remove debug log**

Replace the current remove debug log:

```nut
::MentorRookie.Helpers.debugLog("removed relationship rookieID=" + _rookieID);
```

With:

```nut
::MentorRookie.Helpers.debugLog("removed active relationship but preserved pair history mentor=" + (mentor == null ? "<null>" : mentor.getName()) + " rookie=" + (rookie == null ? "<null>" : rookie.getName()) + " battles=" + rel.BattlesTogether + " focus=" + (rel.FocusAttributeID == null ? "<none>" : rel.FocusAttributeID) + " trainingBattles=" + rel.FocusedTrainingBattles + " trainingGain=" + rel.FocusedTrainingGain);
```

- [ ] **Step 4: Build check**

Run:

```powershell
modbb --game-data-dir test-results\build-pair-history-remove
```

Expected: build succeeds. Remove still removes active UI relationship and passive effects, but does not delete `MentorRookieHistory_*` flags.

---

### Task 5: Update Player Docs

**Files:**
- Modify: `mod_mentor_rookie/README.md`

**Interfaces:**
- Consumes: pair-specific restore behavior from Tasks 1-4
- Produces: player-facing explanation of remove/re-couple persistence

- [ ] **Step 1: Add a relationship history section**

Add this section after `## Graduation` and before `## Settings`:

```markdown
## Relationship History

Removing a mentor-rookie relationship from the `Shift+M` screen removes the active relationship and passive effects, but the pair's history is preserved.

If the same mentor and same rookie are coupled again later, the mod restores that pair's previous battle count, focused attribute, focused-training progress, and focused-training gain.

History is pair-specific. For example, Mentor A with Rookie B has separate history from Mentor C with Rookie B. This prevents progress from one mentor being transferred freely to another mentor.
```

- [ ] **Step 2: Keep graduation text unchanged**

Do not change the existing graduation rules in this task.

Reasoning: graduation behavior is not being redesigned here. This change only addresses manual Remove followed by re-coupling the same pair.

---

### Task 6: Update Manual Testing Checklist

**Files:**
- Modify: `mod_mentor_rookie/docs/testing_list.md`

**Interfaces:**
- Consumes: pair-specific history behavior from Tasks 1-4
- Produces: manual tests for persistence after Remove and anti-transfer behavior

- [ ] **Step 1: Add remove/re-couple persistence test**

In `## 18. Remove Relationship Test`, add these checks:

```markdown
- [ ] Create a mentor-rookie relationship.
- [ ] Fight valid battles until battle count is greater than `0`.
- [ ] Select a focused attribute if the mentor has `Master Mentor`.
- [ ] Trigger partial focused-training progress or focused-training gain.
- [ ] Press `Remove` on the active relationship.
- [ ] Confirm active relationship disappears.
- [ ] Confirm mentor and rookie passive effects are removed.
- [ ] Re-couple the same mentor and same rookie.
- [ ] Confirm previous battle count is restored.
- [ ] Confirm previous focused attribute is restored if one was selected.
- [ ] Confirm previous focused-training progress is restored.
- [ ] Confirm previous focused-training total gain is restored.
```

- [ ] **Step 2: Add pair-specific anti-transfer test**

Add this section after `## 18. Remove Relationship Test`:

```markdown
## 18A. Pair-Specific History Test

- [ ] Create Mentor A + Rookie B.
- [ ] Fight valid battles until battle count is greater than `0`.
- [ ] Press `Remove`.
- [ ] Create Mentor C + Rookie B.
- [ ] Confirm Mentor C + Rookie B starts from its own history, usually `0` if they were never paired before.
- [ ] Press `Remove`.
- [ ] Re-create Mentor A + Rookie B.
- [ ] Confirm Mentor A + Rookie B restores the original battle count.
```

- [ ] **Step 3: Add useful debug logs**

Under the remove/re-couple checks, add:

```markdown
Useful debug log lines:

- `pair history saved`
- `relationship history restored`
- `removed active relationship but preserved pair history`
```

---

### Task 7: In-Game Verification

**Files:**
- No code files modified in this task.

**Interfaces:**
- Consumes: implementation from Tasks 1-4
- Consumes: documentation from Tasks 5-6
- Produces: confidence that remove/re-couple persistence works in game

- [ ] **Step 1: Build the mod**

Run:

```powershell
modbb --game-data-dir test-results\build-pair-history-final
```

Expected: build succeeds.

- [ ] **Step 2: Test same-pair restore**

In game:

```text
Create Mentor A + Rookie B.
Fight one valid battle.
Open Shift+M.
Confirm battle count is 1.
Press Remove.
Create Mentor A + Rookie B again.
```

Expected: battle count is restored to `1`, not reset to `0`.

- [ ] **Step 3: Test same-pair focused training restore**

In game:

```text
Create Mentor A + Rookie B.
Activate Focused Training.
Choose an eligible attribute.
Fight until focused-training progress or gain changes.
Press Remove.
Create Mentor A + Rookie B again.
```

Expected: focused attribute, progress, and total gain are restored.

- [ ] **Step 4: Test pair-specific separation**

In game:

```text
Create Mentor A + Rookie B.
Fight one valid battle.
Press Remove.
Create Mentor C + Rookie B.
```

Expected: Mentor C + Rookie B does not inherit Mentor A + Rookie B progress.

- [ ] **Step 5: Test return to original pair**

Continue from Step 4:

```text
Press Remove on Mentor C + Rookie B.
Create Mentor A + Rookie B again.
```

Expected: Mentor A + Rookie B restores its original progress.

---

## Self-Review

Spec coverage:

- Same mentor-rookie pair re-coupling restores previous battle count in Tasks 1-4 and 7.
- Pair-specific history is implemented by the `MentorRookieHistory_<mentorID>_<rookieID>_` prefix in Task 1.
- Remove preserves previous data in Task 4.
- Re-couple restores previous data in Task 2.
- Focused-training focus/progress/gain persistence is covered in Tasks 2-4.
- Player docs are covered in Task 5.
- Manual test coverage is covered in Tasks 6-7.

Placeholder scan:

- No `TBD`, `TODO`, or open-ended placeholder steps are present.
- Every code step provides exact function names and concrete snippets.

Type consistency:

- `BattlesTogether`, `FocusAttributeID`, `FocusedTrainingBattles`, and `FocusedTrainingGain` are consistently used in relationship objects, active flags, and history flags.
- History helpers consistently accept actor objects for read/write and ID values for key/prefix generation.
- The history flag prefix is consistently `MentorRookieHistory_<mentorID>_<rookieID>_`.
