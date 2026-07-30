# Master Mentor Focused Training Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the `Master Mentor` focused training system: Shift+M focus selection, locked focus state, post-battle permanent attribute gains, and queued relationship-flavored notification events.

**Architecture:** Extend the existing `MentorRookie.Service` as the single source of truth for focus eligibility, relationship state, reward calculation, and post-battle processing. Extend the existing Shift+M custom UI to render selectable focus attribute rows instead of using dropdowns. Use a pending notification queue and a custom world event so mentor-rookie training notifications wait until the vanilla event system is free.

**Tech Stack:** Battle Brothers Squirrel `.nut` scripts, existing Modern Hooks/MSU mod structure, Coherent UI JavaScript/CSS, existing `mod_mentor_rookie` service and custom world screen.

## Global Constraints

- Do not modify `data_001`; it is vanilla reference code only.
- Do not modify community mods.
- Work only inside `mod_mentor_rookie`.
- Write docs before implementation.
- Debug logging must be configurable and default enabled during initial development.
- Use `modbb` for builds; do not hand-build zip files.
- Do not use dropdowns for focus selection; previous attempts were unreliable.
- The focus attribute is locked after selection.
- Default maximum permanent gain per focused attribute is `20`, configurable.
- Mentor loses nothing from training.
- Successful training notifications must show mentor and rookie names and portraits.
- Training notifications must not compete directly with vanilla random events; queue them until event UI is free.

---

## File Structure

- Modify `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie_settings.nut`
  Add Master Mentor focused training settings.

- Modify `mod_mentor_rookie/scripts/ui/screens/world/mentor_rookie_screen.nut`
  Add Squirrel callbacks for previewing and setting focus attribute selection.

- Modify `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
  Add focus attribute definitions, eligibility logic, persisted relationship flags, post-battle reward logic, notification queue, and event firing helper.

- Modify `mod_mentor_rookie/ui/mods/mentor_rookie_screen.js`
  Render the Focused Training section, focus rows, locked states, and selected focus state.

- Modify `mod_mentor_rookie/ui/mods/mentor_rookie_screen.css`
  Add layout and states for focus rows without disturbing the existing mentor/rookie columns.

- Create `mod_mentor_rookie/scripts/events/events/mentor_rookie_master_mentor_training_event.nut`
  Custom world event used only for queued training reward notifications.

- Modify `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_rookie_effect.nut`
  Show focused training state and permanent gain progress in the rookie passive effect tooltip.

- Modify `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_mentor_effect.nut`
  Show the current rookie, focus attribute, and progress in the mentor passive effect tooltip.

- Modify `mod_mentor_rookie/docs/master_mentor_perk_high_level_plan.md`
  Add implementation notes only if decisions change during implementation.

---

### Task 1: Add Settings And Focus Attribute Definitions

**Files:**
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie_settings.nut`
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Produces: `::MentorRookie.Service.FocusAttributes`
- Produces: `::MentorRookie.Service.getFocusAttributeDef(_id)`
- Produces: `::MentorRookie.Service.getSetting(_id)` continues to return MSU setting values
- Consumes: existing `::MentorRookie.Mod.ModSettings`

- [ ] **Step 1: Add settings to the existing `Perk` page**

Add these settings after `MasterMentorPerkRow`:

```nut
perk.addBooleanSetting("MasterMentorFocusedTrainingEnabled", true, "Enable Focused Training", "Enable permanent focused attribute gains from the Master Mentor perk.");
perk.addRangeSetting("MasterMentorRequiredBattles", 5, 1, 200, 1, "Focused Training Battles", "Battles together required before a focused training reward can trigger.");
perk.addRangeSetting("MasterMentorMaxGainPerAttribute", 20, 1, 200, 1, "Max Focused Attribute Gain", "Maximum permanent gain a rookie can receive for one focused attribute from one mentor-rookie relation.");
perk.addBooleanSetting("MasterMentorRequireBothAlive", true, "Require Both Alive", "Mentor and rookie must both survive the battle for focused training progress.");
perk.addBooleanSetting("MasterMentorRequireMentorParticipated", true, "Require Mentor Participation", "Mentor must participate in the battle for focused training progress.");
perk.addRangeSetting("MasterMentorChanceTwoToOne", 80, 0, 100, 1, "2-Star Mentor Bonus Chance", "Chance for Mentor 2 stars and Rookie 1 star to grant an additional +1.");
perk.addRangeSetting("MasterMentorChanceThreeToOne", 95, 0, 100, 1, "3-Star Mentor Bonus Chance", "Chance for Mentor 3 stars and Rookie 1 star to grant an additional +1.");
```

- [ ] **Step 2: Add focus attribute definitions to `MentorRookie.Service`**

Add this table near the top of the service object:

```nut
FocusAttributes = [
	{ ID = "Hitpoints", Name = "Hitpoints", AttributeKey = "Hitpoints", TalentKey = "Hitpoints" },
	{ ID = "Fatigue", Name = "Fatigue", AttributeKey = "Stamina", TalentKey = "Fatigue" },
	{ ID = "Resolve", Name = "Resolve", AttributeKey = "Bravery", TalentKey = "Bravery" },
	{ ID = "Initiative", Name = "Initiative", AttributeKey = "Initiative", TalentKey = "Initiative" },
	{ ID = "MeleeSkill", Name = "Melee Skill", AttributeKey = "MeleeSkill", TalentKey = "MeleeSkill" },
	{ ID = "RangedSkill", Name = "Ranged Skill", AttributeKey = "RangedSkill", TalentKey = "RangedSkill" },
	{ ID = "MeleeDefense", Name = "Melee Defense", AttributeKey = "MeleeDefense", TalentKey = "MeleeDefense" },
	{ ID = "RangedDefense", Name = "Ranged Defense", AttributeKey = "RangedDefense", TalentKey = "RangedDefense" }
],
```

- [ ] **Step 3: Add lookup helper**

Add this service method:

```nut
function getFocusAttributeDef( _id )
{
	foreach (def in this.FocusAttributes)
	{
		if (def.ID == _id)
		{
			return def;
		}
	}

	return null;
}
```

- [ ] **Step 4: Build and check for syntax errors**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds with no syntax errors in settings or service files.

---

### Task 2: Add Focus Eligibility And Screen Data

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Produces: `::MentorRookie.Service.getTalentStars(_actor, _focusID)`
- Produces: `::MentorRookie.Service.hasMasterMentor(_actor)`
- Produces: `::MentorRookie.Service.getFocusAttributeOptions(_mentorID, _rookieID)`
- Modifies: `::MentorRookie.Service.queryScreenData()` response with `SelectedPairFocusOptions`
- Consumes: `getFocusAttributeDef(_id)`

- [ ] **Step 1: Add Master Mentor helper**

```nut
function hasMasterMentor( _actor )
{
	return _actor != null && ::MentorRookie.Helpers.hasSkill(_actor, "perk.master_mentor");
}
```

- [ ] **Step 2: Add talent star helper**

Implement the helper with explicit fallback logging if the expected talent container shape is not available:

```nut
function getTalentStars( _actor, _focusID )
{
	if (_actor == null)
	{
		return 0;
	}

	local def = this.getFocusAttributeDef(_focusID);
	if (def == null)
	{
		return 0;
	}

	if ("Talents" in _actor.m && def.TalentKey in _actor.m.Talents)
	{
		return _actor.m.Talents[def.TalentKey];
	}

	::MentorRookie.Helpers.debugLog("talent stars unavailable actor=" + _actor.getName() + " focus=" + _focusID);
	return 0;
}
```

- [ ] **Step 3: Add focus option builder**

```nut
function getFocusAttributeOptions( _mentorID, _rookieID )
{
	local mentor = ::MentorRookie.Helpers.getActorByID(_mentorID);
	local rookie = ::MentorRookie.Helpers.getActorByID(_rookieID);
	local ret = [];

	foreach (def in this.FocusAttributes)
	{
		local mentorStars = this.getTalentStars(mentor, def.ID);
		local rookieStars = this.getTalentStars(rookie, def.ID);
		local reason = "";

		if (!this.getSetting("MasterMentorFocusedTrainingEnabled"))
		{
			reason = "Focused training is disabled.";
		}
		else if (mentor == null || rookie == null)
		{
			reason = "Select a mentor and rookie first.";
		}
		else if (!this.hasMasterMentor(mentor))
		{
			reason = mentor.getName() + " does not have Master Mentor.";
		}
		else if (mentorStars <= 0)
		{
			reason = mentor.getName() + " has no talent star in " + def.Name + ".";
		}
		else if (rookieStars <= 0)
		{
			reason = rookie.getName() + " has no talent star in " + def.Name + ".";
		}

		ret.push({
			ID = def.ID,
			Name = def.Name,
			MentorStars = mentorStars,
			RookieStars = rookieStars,
			IsValid = reason == "",
			Reason = reason
		});
	}

	return ret;
}
```

- [ ] **Step 4: Extend `queryScreenData()`**

Add `SelectedPairFocusOptions = []` to the returned table. The initial render can send an empty list because JS will request options once mentor and rookie are selected.

```nut
return {
	Roster = this.getRosterForScreen(),
	Relationships = this.getRelationshipsForScreen(),
	SelectedPairFocusOptions = []
};
```

- [ ] **Step 5: Build and inspect logs**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds. If talent shape is wrong at runtime, debug logs in `C:\Users\gujar\Documents\Battle Brothers\log.html` show `talent stars unavailable`.

---

### Task 3: Add UI Backend Callbacks For Focus Preview And Creation

**Files:**
- Modify: `mod_mentor_rookie/scripts/ui/screens/world/mentor_rookie_screen.nut`
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Produces: screen callback `onQueryFocusOptions(_data)`
- Changes: screen callback `onCreateRelationship(_data)` expects `[mentorID, rookieID, focusAttributeID]`
- Changes: service method `createRelationship(_mentorID, _rookieID, _focusAttributeID = null)`
- Consumes: `getFocusAttributeOptions(_mentorID, _rookieID)`

- [ ] **Step 1: Add screen callback for focus options**

Add to `mentor_rookie_screen.nut`:

```nut
function onQueryFocusOptions( _data )
{
	local mentorID = _data[0];
	local rookieID = _data[1];
	return ::MentorRookie.Service.getFocusAttributeOptions(mentorID, rookieID);
}
```

- [ ] **Step 2: Update create relationship callback**

Replace the existing `onCreateRelationship` body:

```nut
function onCreateRelationship( _data )
{
	local mentorID = _data[0];
	local rookieID = _data[1];
	local focusAttributeID = _data.len() > 2 ? _data[2] : null;
	return ::MentorRookie.Service.createRelationship(mentorID, rookieID, focusAttributeID);
}
```

- [ ] **Step 3: Update service method signature**

Change:

```nut
function createRelationship( _mentorID, _rookieID )
```

To:

```nut
function createRelationship( _mentorID, _rookieID, _focusAttributeID = null )
```

- [ ] **Step 4: Validate focus before relationship creation**

Inside `createRelationship`, after base pair validation succeeds and before creating `rel`, add:

```nut
local selectedFocus = null;

if (_focusAttributeID != null)
{
	foreach (option in this.getFocusAttributeOptions(_mentorID, _rookieID))
	{
		if (option.ID == _focusAttributeID)
		{
			selectedFocus = option;
			break;
		}
	}

	if (selectedFocus == null || !selectedFocus.IsValid)
	{
		local reason = selectedFocus == null ? "Selected focus attribute is invalid." : selectedFocus.Reason;
		::MentorRookie.Helpers.debugLog("create relationship rejected: focus invalid mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " focus=" + _focusAttributeID + " reason=" + reason);
		return { Success = false, Message = reason, Data = this.queryScreenData() };
	}
}
```

- [ ] **Step 5: Build**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds and existing relationship creation still works when `_focusAttributeID` is `null`.

---

### Task 4: Persist Focus State On Relationship Flags

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Changes: relationship object includes `FocusAttributeID`, `FocusedTrainingBattles`, `FocusedTrainingGain`
- Changes: actor flags include `MentorRookieFocusAttributeID`, `MentorRookieFocusedTrainingBattles`, `MentorRookieFocusedTrainingGain`
- Consumes: `getFocusAttributeDef(_id)`

- [ ] **Step 1: Extend relationship object creation**

When creating `rel`, include:

```nut
FocusAttributeID = _focusAttributeID,
FocusedTrainingBattles = 0,
FocusedTrainingGain = 0
```

- [ ] **Step 2: Extend `writeRelationshipFlags` signature**

Change:

```nut
function writeRelationshipFlags( _mentor, _rookie, _battles )
```

To:

```nut
function writeRelationshipFlags( _mentor, _rookie, _battles, _focusAttributeID = null, _focusedTrainingBattles = 0, _focusedTrainingGain = 0 )
```

- [ ] **Step 3: Write focus flags to both actors**

Inside `writeRelationshipFlags`, after partner/battle flags:

```nut
if (_focusAttributeID != null)
{
	_mentor.getFlags().set("MentorRookieFocusAttributeID", _focusAttributeID);
	_mentor.getFlags().set("MentorRookieFocusedTrainingBattles", _focusedTrainingBattles);
	_mentor.getFlags().set("MentorRookieFocusedTrainingGain", _focusedTrainingGain);
	_rookie.getFlags().set("MentorRookieFocusAttributeID", _focusAttributeID);
	_rookie.getFlags().set("MentorRookieFocusedTrainingBattles", _focusedTrainingBattles);
	_rookie.getFlags().set("MentorRookieFocusedTrainingGain", _focusedTrainingGain);
}
```

- [ ] **Step 4: Clear focus flags**

In `clearRelationship`, remove these flags from both actors where the other relationship flags are removed:

```nut
getFlags().remove("MentorRookieFocusAttributeID");
getFlags().remove("MentorRookieFocusedTrainingBattles");
getFlags().remove("MentorRookieFocusedTrainingGain");
```

- [ ] **Step 5: Load focus state during relationship reconstruction**

In the relationship reconstruction logic, when pushing reconstructed relationships, read from mentor flags:

```nut
local focusAttributeID = mentor.getFlags().has("MentorRookieFocusAttributeID") ? mentor.getFlags().get("MentorRookieFocusAttributeID") : null;
local focusedTrainingBattles = mentor.getFlags().has("MentorRookieFocusedTrainingBattles") ? mentor.getFlags().get("MentorRookieFocusedTrainingBattles") : 0;
local focusedTrainingGain = mentor.getFlags().has("MentorRookieFocusedTrainingGain") ? mentor.getFlags().get("MentorRookieFocusedTrainingGain") : 0;

this.Relationships.push({
	MentorID = mentor.getID(),
	RookieID = rookie.getID(),
	BattlesTogether = battles,
	FocusAttributeID = focusAttributeID,
	FocusedTrainingBattles = focusedTrainingBattles,
	FocusedTrainingGain = focusedTrainingGain
});
```

- [ ] **Step 6: Build**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds and existing relationships without focus state reconstruct with `FocusAttributeID = null`.

---

### Task 5: Render Focus Attribute Rows In Shift+M UI

**Files:**
- Modify: `mod_mentor_rookie/ui/mods/mentor_rookie_screen.js`
- Modify: `mod_mentor_rookie/ui/mods/mentor_rookie_screen.css`

**Interfaces:**
- Consumes: screen callback `onQueryFocusOptions([mentorID, rookieID])`
- Produces: JS state `this.mSelectedFocusAttributeID`
- Sends: `onCreateRelationship([mentorID, rookieID, selectedFocusAttributeID])`

- [ ] **Step 1: Add JS fields**

In the constructor, add:

```js
this.mFocusSection = null;
this.mFocusList = null;
this.mSelectedFocusAttributeID = null;
```

- [ ] **Step 2: Create focus section in `createDIV()`**

After active relationships title/list creation, add:

```js
this.mFocusSection = $('<div class="mentor-rookie-focus-section"/>');
this.mFocusSection.append($('<div class="mentor-rookie-section-title title-font-normal font-color-title">Focused Training</div>'));
this.mFocusList = $('<div class="mentor-rookie-focus-list"/>');
this.mFocusSection.append(this.mFocusList);
```

Append `this.mFocusSection` to `body` between relationships and message.

- [ ] **Step 3: Query focus options when selection changes**

Inside `createBrotherRow` click handler, after setting mentor or rookie ID:

```js
self.mSelectedFocusAttributeID = null;
self.queryFocusOptions();
self.render();
```

Add method:

```js
MentorRookieScreen.prototype.queryFocusOptions = function()
{
	var self = this;

	if (this.mSelectedMentorID === null || this.mSelectedRookieID === null)
	{
		if (this.mData !== null)
		{
			this.mData.SelectedPairFocusOptions = [];
		}
		return;
	}

	SQ.call(this.mSQHandle, 'onQueryFocusOptions', [this.mSelectedMentorID, this.mSelectedRookieID], function(_options)
	{
		if (self.mData !== null)
		{
			self.mData.SelectedPairFocusOptions = _options || [];
			self.renderFocusOptions();
		}
	});
};
```

- [ ] **Step 4: Render focus options**

Add method:

```js
MentorRookieScreen.prototype.renderFocusOptions = function()
{
	var self = this;
	var options = this.mData && this.mData.SelectedPairFocusOptions ? this.mData.SelectedPairFocusOptions : [];
	this.mFocusList.empty();

	if (this.mSelectedMentorID === null || this.mSelectedRookieID === null)
	{
		this.mFocusList.append($('<div class="mentor-rookie-focus-empty description-font-medium font-color-description">Select a mentor and rookie to see focused training options.</div>'));
		return;
	}

	if (options.length === 0)
	{
		this.mFocusList.append($('<div class="mentor-rookie-focus-empty description-font-medium font-color-description">No focus options available.</div>'));
		return;
	}

	for (var i = 0; i < options.length; i++)
	{
		var option = options[i];
		var row = $('<div class="mentor-rookie-focus-row"/>');
		var name = $('<div class="mentor-rookie-focus-name title-font-normal font-color-title"/>').text(option.Name);
		var stars = $('<div class="mentor-rookie-focus-stars text-font-normal"/>').text('Mentor ' + this.formatStars(option.MentorStars) + ' / Rookie ' + this.formatStars(option.RookieStars));
		var status = $('<div class="mentor-rookie-focus-status description-font-medium"/>').text(option.IsValid ? 'Available' : option.Reason);

		if (option.ID === this.mSelectedFocusAttributeID)
		{
			row.addClass('is-selected');
		}

		if (!option.IsValid)
		{
			row.addClass('is-locked');
		}

		row.data('focus-id', option.ID);
		row.data('is-valid', option.IsValid);
		row.click(function(_event)
		{
			var target = $(_event.currentTarget);
			if (!target.data('is-valid'))
			{
				return;
			}

			self.mSelectedFocusAttributeID = target.data('focus-id');
			self.renderFocusOptions();
		});

		row.append(name);
		row.append(stars);
		row.append(status);
		this.mFocusList.append(row);
	}
};
```

- [ ] **Step 5: Add star formatter**

```js
MentorRookieScreen.prototype.formatStars = function(_count)
{
	var stars = '';
	for (var i = 0; i < _count; i++)
	{
		stars += '*';
	}

	return stars === '' ? '-' : stars;
};
```

- [ ] **Step 6: Send selected focus during create**

Change create call payload:

```js
SQ.call(this.mSQHandle, 'onCreateRelationship', [this.mSelectedMentorID, this.mSelectedRookieID, this.mSelectedFocusAttributeID], function(_result)
{
	self.handleResult(_result);
});
```

- [ ] **Step 7: Add CSS layout**

Add CSS:

```css
.mentor-rookie-focus-section
{
	position: absolute;
	left: 0;
	right: 0;
	top: 47.2rem;
	height: 8.8rem;
}

.mentor-rookie-focus-list
{
	position: absolute;
	left: 0;
	right: 0;
	top: 3.0rem;
	bottom: 0;
	overflow-y: auto;
	background: rgba(15, 10, 6, 0.45);
	border: 0.1rem solid rgba(70, 47, 28, 0.75);
	padding: 0.4rem;
}

.mentor-rookie-focus-row
{
	position: relative;
	height: 2.4rem;
	margin-bottom: 0.3rem;
	background-image: url("coui://gfx/ui/skin/list_item_03.png");
	background-size: 100% 100%;
	cursor: pointer;
}

.mentor-rookie-focus-row.is-selected
{
	box-shadow: inset 0 0 0 0.2rem #d49a32;
}

.mentor-rookie-focus-row.is-locked
{
	opacity: 0.6;
	cursor: default;
}

.mentor-rookie-focus-name
{
	position: absolute;
	left: 0.6rem;
	top: 0;
	width: 15.0rem;
	height: 2.4rem;
	line-height: 2.4rem;
}

.mentor-rookie-focus-stars
{
	position: absolute;
	left: 16.0rem;
	top: 0;
	width: 20.0rem;
	height: 2.4rem;
	line-height: 2.4rem;
	color: #d0b47c;
}

.mentor-rookie-focus-status
{
	position: absolute;
	left: 36.5rem;
	right: 0.6rem;
	top: 0;
	height: 2.4rem;
	line-height: 2.4rem;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
	color: #d27a5c;
}

.mentor-rookie-focus-empty
{
	padding: 0.5rem;
}
```

- [ ] **Step 8: Move message/actions lower if needed**

Because the focus section occupies `47.2rem` to `56.0rem`, move `.mentor-rookie-message` and `.mentor-rookie-actions` if overlap appears:

```css
.mentor-rookie-message
{
	top: 56.2rem;
}
```

Keep actions at the bottom of the existing panel.

- [ ] **Step 9: Run UI smoke test**

Run:

```powershell
modbb build mod_mentor_rookie
```

Then in game, open Shift+M and verify:

- selecting only mentor shows focus empty message
- selecting mentor and rookie renders eight focus rows
- invalid rows are visibly locked
- valid row can be selected
- selected focus has gold border
- create pair sends selected focus

---

### Task 6: Show Focus Data In Active Relationships

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
- Modify: `mod_mentor_rookie/ui/mods/mentor_rookie_screen.js`
- Modify: `mod_mentor_rookie/ui/mods/mentor_rookie_screen.css`

**Interfaces:**
- Changes: `getRelationshipsForScreen()` relationship rows include focus display fields
- Consumes: relationship fields `FocusAttributeID`, `FocusedTrainingBattles`, `FocusedTrainingGain`

- [ ] **Step 1: Extend relationship screen data**

In `getRelationshipsForScreen()`, add:

```nut
local focusDef = "FocusAttributeID" in rel ? this.getFocusAttributeDef(rel.FocusAttributeID) : null;
local requiredBattles = this.getSetting("MasterMentorRequiredBattles");
local maxGain = this.getSetting("MasterMentorMaxGainPerAttribute");
```

Add fields to the returned relationship object:

```nut
FocusAttributeID = "FocusAttributeID" in rel ? rel.FocusAttributeID : null,
FocusAttributeName = focusDef != null ? focusDef.Name : "No focus",
FocusLocked = focusDef != null,
FocusedTrainingBattles = "FocusedTrainingBattles" in rel ? rel.FocusedTrainingBattles : 0,
FocusedTrainingRequiredBattles = requiredBattles,
FocusedTrainingGain = "FocusedTrainingGain" in rel ? rel.FocusedTrainingGain : 0,
FocusedTrainingMaxGain = maxGain
```

- [ ] **Step 2: Render relationship focus text**

Replace relationship row text in JS:

```js
var focusText = rel.FocusAttributeID !== null
	? ' | Focus: ' + rel.FocusAttributeName + ' | Training ' + rel.FocusedTrainingBattles + '/' + rel.FocusedTrainingRequiredBattles + ' | Gain ' + rel.FocusedTrainingGain + '/' + rel.FocusedTrainingMaxGain
	: ' | Focus: None';

relRow.append($('<div class="mentor-rookie-relationship-text title-font-normal font-color-title"/>').text(rel.MentorName + ' -> ' + rel.RookieName + ' (' + rel.BattlesTogether + ' battles)' + focusText));
```

- [ ] **Step 3: Allow relationship row text to fit**

If the row becomes too dense, reduce font size for relationship details:

```css
.mentor-rookie-relationship-text
{
	font-size: 1.1rem;
}
```

- [ ] **Step 4: Build and manual check**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: active relationship rows show focus, battle progress, and gain cap.

---

### Task 7: Implement Reward Calculation

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Produces: `::MentorRookie.Service.calculateFocusedTrainingGain(_mentor, _rookie, _focusAttributeID)`
- Consumes: `getTalentStars(_actor, _focusID)`
- Consumes: settings `MasterMentorChanceTwoToOne`, `MasterMentorChanceThreeToOne`

- [ ] **Step 1: Add reward calculation method**

```nut
function calculateFocusedTrainingGain( _mentor, _rookie, _focusAttributeID )
{
	local mentorStars = this.getTalentStars(_mentor, _focusAttributeID);
	local rookieStars = this.getTalentStars(_rookie, _focusAttributeID);
	local gain = 0;

	if (mentorStars == 1 && rookieStars == 1)
	{
		gain = 2;
	}
	else if (mentorStars == 2 && rookieStars == 1)
	{
		gain = 2;
		if (::Math.rand(1, 100) <= this.getSetting("MasterMentorChanceTwoToOne"))
		{
			gain += 1;
		}
	}
	else if (mentorStars == 3 && rookieStars == 1)
	{
		gain = 2;
		if (::Math.rand(1, 100) <= this.getSetting("MasterMentorChanceThreeToOne"))
		{
			gain += 1;
		}
	}
	else if (mentorStars == 3 && rookieStars == 2)
	{
		gain = 2;
	}
	else if (mentorStars == 3 && rookieStars == 3)
	{
		gain = 3;
	}

	::MentorRookie.Helpers.debugLog("focused training calculated mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " mentorStars=" + mentorStars + " rookieStars=" + rookieStars + " gain=" + gain);
	return gain;
}
```

This plan treats `Mentor 1 star and Rookie 1 star with matching selected focus` as the default selected-focus case, so it grants `+2`.

- [ ] **Step 2: Add cap helper**

```nut
function capFocusedTrainingGain( _currentGain, _proposedGain )
{
	local maxGain = this.getSetting("MasterMentorMaxGainPerAttribute");
	return ::Math.max(0, ::Math.min(_proposedGain, maxGain - _currentGain));
}
```

- [ ] **Step 3: Build**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds.

---

### Task 8: Apply Permanent Attribute Gain After Battle

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Produces: `::MentorRookie.Service.applyFocusedTrainingGain(_rookie, _focusAttributeID, _gain)`
- Produces: `::MentorRookie.Service.processFocusedTraining(_rel, _mentor, _rookie, _mentorAlive, _rookieAlive)`
- Consumes: existing `handleAfterCombat()` relationship loop

- [ ] **Step 1: Add attribute getter**

```nut
function getFocusedAttributeValue( _actor, _focusAttributeID )
{
	local def = this.getFocusAttributeDef(_focusAttributeID);
	if (_actor == null || def == null || !(def.AttributeKey in _actor.m))
	{
		return 0;
	}

	return _actor.m[def.AttributeKey];
}
```

- [ ] **Step 2: Add attribute applier**

```nut
function applyFocusedTrainingGain( _rookie, _focusAttributeID, _gain )
{
	local def = this.getFocusAttributeDef(_focusAttributeID);
	if (_rookie == null || def == null || _gain <= 0)
	{
		return false;
	}

	if (!(def.AttributeKey in _rookie.m))
	{
		::MentorRookie.Helpers.debugLog("focused training apply failed rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " reason=missing_attribute_key");
		return false;
	}

	_rookie.m[def.AttributeKey] += _gain;
	_rookie.getSkills().update();
	return true;
}
```

- [ ] **Step 3: Add focused training processor**

```nut
function processFocusedTraining( _rel, _mentor, _rookie, _mentorAlive, _rookieAlive )
{
	if (!this.getSetting("MasterMentorFocusedTrainingEnabled"))
	{
		return;
	}

	if (!("FocusAttributeID" in _rel) || _rel.FocusAttributeID == null)
	{
		return;
	}

	if (!this.hasMasterMentor(_mentor))
	{
		::MentorRookie.Helpers.debugLog("focused training skipped mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " reason=no_master_mentor");
		return;
	}

	if (this.getSetting("MasterMentorRequireBothAlive") && (!_mentorAlive || !_rookieAlive))
	{
		::MentorRookie.Helpers.debugLog("focused training skipped mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " reason=not_both_alive");
		return;
	}

	local maxGain = this.getSetting("MasterMentorMaxGainPerAttribute");
	if (_rel.FocusedTrainingGain >= maxGain)
	{
		::MentorRookie.Helpers.debugLog("focused training skipped mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " reason=max_gain_reached");
		return;
	}

	_rel.FocusedTrainingBattles += 1;
	local requiredBattles = this.getSetting("MasterMentorRequiredBattles");

	if (_rel.FocusedTrainingBattles < requiredBattles)
	{
		::MentorRookie.Helpers.debugLog("focused training progress mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " focus=" + _rel.FocusAttributeID + " progress=" + _rel.FocusedTrainingBattles + "/" + requiredBattles);
		return;
	}

	_rel.FocusedTrainingBattles = 0;
	local proposedGain = this.calculateFocusedTrainingGain(_mentor, _rookie, _rel.FocusAttributeID);
	local gain = this.capFocusedTrainingGain(_rel.FocusedTrainingGain, proposedGain);

	if (gain <= 0)
	{
		return;
	}

	local oldValue = this.getFocusedAttributeValue(_rookie, _rel.FocusAttributeID);
	if (this.applyFocusedTrainingGain(_rookie, _rel.FocusAttributeID, gain))
	{
		local newValue = this.getFocusedAttributeValue(_rookie, _rel.FocusAttributeID);
		_rel.FocusedTrainingGain += gain;
		this.queueFocusedTrainingNotification(_mentor, _rookie, _rel.FocusAttributeID, oldValue, newValue, gain);
	}
}
```

- [ ] **Step 4: Call processor from `handleAfterCombat()`**

After the relationship battle has been counted and before `writeRelationshipFlags(...)`, call:

```nut
this.processFocusedTraining(rel, mentor, rookie, mentorAlive, rookieAlive);
this.writeRelationshipFlags(mentor, rookie, rel.BattlesTogether, rel.FocusAttributeID, rel.FocusedTrainingBattles, rel.FocusedTrainingGain);
```

- [ ] **Step 5: Build and manual battle test**

Run:

```powershell
modbb build mod_mentor_rookie
```

Manual test in game:

- create a focused relationship
- fight enough battles to reach requirement
- confirm rookie attribute increases
- confirm debug log has focused training progress and reward lines

---

### Task 9: Add Pending Notification Queue

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
- Modify: `mod_mentor_rookie/scripts/!mods_preload/mod_mentor_rookie.nut`

**Interfaces:**
- Produces: `::MentorRookie.Service.PendingTrainingNotifications`
- Produces: `::MentorRookie.Service.queueFocusedTrainingNotification(_mentor, _rookie, _focusAttributeID, _oldValue, _newValue, _gain)`
- Produces: `::MentorRookie.Service.tryShowPendingTrainingNotification()`
- Consumes: `::World.Events.canFireEvent(true, true)`

- [ ] **Step 1: Add pending notification storage**

Add to service object fields:

```nut
PendingTrainingNotifications = [],
ActiveTrainingNotification = null,
```

- [ ] **Step 2: Add queue method**

```nut
function queueFocusedTrainingNotification( _mentor, _rookie, _focusAttributeID, _oldValue, _newValue, _gain )
{
	local def = this.getFocusAttributeDef(_focusAttributeID);
	if (def == null)
	{
		return;
	}

	this.PendingTrainingNotifications.push({
		MentorID = _mentor.getID(),
		MentorName = _mentor.getName(),
		RookieID = _rookie.getID(),
		RookieName = _rookie.getName(),
		FocusAttributeID = _focusAttributeID,
		FocusAttributeName = def.Name,
		OldValue = _oldValue,
		NewValue = _newValue,
		Gain = _gain
	});

	::MentorRookie.Helpers.debugLog("focused training notification queued mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " old=" + _oldValue + " new=" + _newValue + " gain=" + _gain);
}
```

- [ ] **Step 3: Add show helper**

```nut
function tryShowPendingTrainingNotification()
{
	if (this.PendingTrainingNotifications.len() == 0)
	{
		return false;
	}

	if (!::World.Events.canFireEvent(true, true))
	{
		::MentorRookie.Helpers.debugLog("focused training notification delayed reason=event_ui_busy");
		return false;
	}

	this.ActiveTrainingNotification = this.PendingTrainingNotifications.remove(0);
	::MentorRookie.Helpers.debugLog("focused training notification showing mentor=" + this.ActiveTrainingNotification.MentorName + " rookie=" + this.ActiveTrainingNotification.RookieName);
	return ::World.Events.fire("event.mentor_rookie.master_mentor_training", false);
}
```

- [ ] **Step 4: Call show helper after combat and during world updates**

In the existing post-combat hook in `mod_mentor_rookie.nut`, after `handleAfterCombat()`:

```nut
::MentorRookie.Service.tryShowPendingTrainingNotification();
```

Add or extend a world-state update hook so pending notifications retry while the player is in world state:

```nut
::MentorRookie.HooksMod.hook("scripts/states/world_state", function(q) {
	q.update = @(__original) { function update()
	{
		__original();
		if ("MentorRookie" in ::getroottable() && ::MentorRookie.Service != null)
		{
			::MentorRookie.Service.tryShowPendingTrainingNotification();
		}
	}}.update;
});
```

- [ ] **Step 5: Build**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds. Runtime logs show delayed notifications when event UI is busy.

---

### Task 10: Create Training Notification Event

**Files:**
- Create: `mod_mentor_rookie/scripts/events/events/mentor_rookie_master_mentor_training_event.nut`
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Consumes: `::MentorRookie.Service.ActiveTrainingNotification`
- Produces: event ID `event.mentor_rookie.master_mentor_training`

- [ ] **Step 1: Create event file**

```nut
this.mentor_rookie_master_mentor_training_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.mentor_rookie.master_mentor_training";
		this.m.Title = "Master Mentor";
		this.m.IsSpecial = true;
		this.m.Screens.push({
			ID = "A",
			Text = "",
			Image = "",
			Characters = [],
			Options = [
				{
					Text = "Continue",
					function getResult( _event )
					{
						::MentorRookie.Service.ActiveTrainingNotification = null;
						return 0;
					}
				}
			],
			function start( _event )
			{
				local data = ::MentorRookie.Service.ActiveTrainingNotification;
				if (data == null)
				{
					this.Text = "The training lesson has passed.";
					return;
				}

				local mentor = ::MentorRookie.Helpers.getActorByID(data.MentorID);
				local rookie = ::MentorRookie.Helpers.getActorByID(data.RookieID);

				if (mentor != null)
				{
					this.Characters.push(mentor.getImagePath());
				}

				if (rookie != null)
				{
					this.Characters.push(rookie.getImagePath());
				}

				this.Text = "[img]gfx/ui/events/event_05.png[/img]" + data.MentorName + " has guided " + data.RookieName + " through enough battles for the lesson to become instinct.\n\n" + data.RookieName + " improved:\n\n" + data.FocusAttributeName + ": " + data.OldValue + " -> " + data.NewValue + " (+" + data.Gain + ")";
			}
		});
	}
});
```

- [ ] **Step 2: Confirm event loading path**

Battle Brothers event manager enumerates `scripts/events/events/`, so placing this file under `mod_mentor_rookie/scripts/events/events/` makes it available without modifying vanilla.

- [ ] **Step 3: Build and trigger event manually through training**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected after reward:

- full event screen opens
- title is `Master Mentor`
- mentor and rookie portraits appear
- text shows `{attribute}: {old} -> {new} (+{gain})`

---

### Task 11: Update Passive Skill Tooltips

**Files:**
- Modify: `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_rookie_effect.nut`
- Modify: `mod_mentor_rookie/scripts/skills/effects/mentor_rookie_mentor_effect.nut`

**Interfaces:**
- Consumes: actor flags `MentorRookieFocusAttributeID`, `MentorRookieFocusedTrainingBattles`, `MentorRookieFocusedTrainingGain`
- Consumes: `::MentorRookie.Service.getFocusAttributeDef(_id)`
- Consumes: settings `MasterMentorRequiredBattles`, `MasterMentorMaxGainPerAttribute`

- [ ] **Step 1: Add shared tooltip fields to rookie effect**

In rookie tooltip generation, after battle count entry, add:

```nut
if (actor.getFlags().has("MentorRookieFocusAttributeID"))
{
	local focusID = actor.getFlags().get("MentorRookieFocusAttributeID");
	local def = ::MentorRookie.Service.getFocusAttributeDef(focusID);
	local progress = actor.getFlags().has("MentorRookieFocusedTrainingBattles") ? actor.getFlags().get("MentorRookieFocusedTrainingBattles") : 0;
	local gain = actor.getFlags().has("MentorRookieFocusedTrainingGain") ? actor.getFlags().get("MentorRookieFocusedTrainingGain") : 0;
	local required = ::MentorRookie.Service.getSetting("MasterMentorRequiredBattles");
	local maxGain = ::MentorRookie.Service.getSetting("MasterMentorMaxGainPerAttribute");

	ret.push({
		id = 20,
		type = "text",
		icon = "ui/icons/special.png",
		text = "Focused training: [color=" + this.Const.UI.Color.PositiveValue + "]" + (def != null ? def.Name : focusID) + "[/color]"
	});

	ret.push({
		id = 21,
		type = "text",
		icon = "ui/icons/days_wounded.png",
		text = "Training progress: [color=" + this.Const.UI.Color.PositiveValue + "]" + progress + " / " + required + "[/color] battles, gain [color=" + this.Const.UI.Color.PositiveValue + "]" + gain + " / " + maxGain + "[/color]"
	});
}
```

- [ ] **Step 2: Add same summary to mentor effect**

Use the mentor actor as `actor`, read the same flags, and add:

```nut
text = "Focused training: [color=" + this.Const.UI.Color.PositiveValue + "]" + (def != null ? def.Name : focusID) + "[/color] for this mentor-rookie relation."
```

- [ ] **Step 3: Build and inspect tooltips**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: mentor and rookie passive effects show focus, progress, and gain cap.

---

### Task 12: Manual Verification Checklist

**Files:**
- Modify only if defects are found in prior task files.

**Interfaces:**
- Consumes: all tasks above.
- Produces: implementation confidence before user review.

- [ ] **Step 1: Build**

Run:

```powershell
modbb build mod_mentor_rookie
```

Expected: build succeeds.

- [ ] **Step 2: Open Shift+M screen in world state**

Expected:

- screen opens
- mentor list renders
- rookie list renders
- focused training section appears
- no dropdown UI appears

- [ ] **Step 3: Select mentor without Master Mentor**

Expected:

- focus rows render as locked
- reason says mentor does not have `Master Mentor`

- [ ] **Step 4: Select mentor with Master Mentor and rookie**

Expected:

- eight focus rows render
- attributes where both have at least one talent star are selectable
- attributes without matching talent stars are locked with reason

- [ ] **Step 5: Create focused relationship**

Expected:

- relationship appears in Active Relationships
- focus name appears
- progress shows `0 / 5`
- gain shows `0 / 20`
- focus cannot be changed from the relationship row

- [ ] **Step 6: Fight battles until reward triggers**

Expected:

- training progress increments only when the configured requirements are met
- at required battle count, rookie receives permanent attribute gain
- progress resets to `0 / 5`
- total gain increases

- [ ] **Step 7: Confirm notification event**

Expected:

- full world event screen opens after battle
- mentor portrait appears
- rookie portrait appears
- text shows attribute change like `Melee Skill: 55 -> 57 (+2)`

- [ ] **Step 8: Confirm vanilla event safety**

Expected:

- if another world event is active, mentor training notification remains pending
- pending notification appears later when event UI is free
- log has `focused training notification delayed reason=event_ui_busy`

- [ ] **Step 9: Confirm graduation behavior**

Expected:

- when the rookie graduates, relationship clears
- focused training stops for that relation
- passive effects are removed

- [ ] **Step 10: Confirm logs**

Inspect:

```text
C:\Users\gujar\Documents\Battle Brothers\log.html
```

Expected log types:

- focus selected
- focused training progress
- focused training calculated
- attribute gain applied
- notification queued
- notification shown
- notification delayed when event UI is busy

---

## Self-Review

Spec coverage:

- Shift+M focus attribute section is covered in Tasks 3, 5, and 6.
- No dropdown implementation is covered in Task 5.
- Eligible attributes based on mentor and rookie talent stars are covered in Task 2.
- Locked focus behavior is covered in Tasks 4, 5, and 6.
- Configurable battle requirement and max gain are covered in Task 1.
- Post-battle reward processing is covered in Tasks 7 and 8.
- Mentor and rookie notification event with portraits is covered in Task 10.
- Vanilla event conflict safety is covered in Task 9.
- Passive skill tooltip updates are covered in Task 11.
- Debug logging is covered across Tasks 2, 3, 8, 9, and 12.

Placeholder scan:

- No `TBD`, `TODO`, or open-ended "handle edge cases" instructions remain.
- Each task lists concrete files, interfaces, and verification.

Type consistency:

- `FocusAttributeID`, `FocusedTrainingBattles`, and `FocusedTrainingGain` are consistently used in relationship objects and actor flags.
- UI consumes `SelectedPairFocusOptions`, matching the backend callback response.
- Event consumes `ActiveTrainingNotification`, produced by the notification queue.
