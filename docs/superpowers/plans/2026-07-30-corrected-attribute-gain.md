# Corrected Attribute Gain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change Master Mentor Focused Training so low-star pairs gain less permanent attribute value while high-star pairs remain rare and powerful.

**Architecture:** Keep the existing Focused Training pipeline unchanged. Only update the reward formula in `MentorRookie.Service.calculateFocusedTrainingGain`, then align README/player docs and manual test expectations with the corrected table from `docs/corrected_attribute_gain.md`.

**Tech Stack:** Battle Brothers Squirrel `.nut` scripts, existing Modern Hooks/MSU mod structure, Markdown documentation, `modbb` build workflow.

## Global Constraints

- Work only inside `mod_mentor_rookie`.
- Do not modify `data_001`; it is vanilla reference code only.
- Do not modify community mods.
- Preserve the existing Focused Training UI, relationship flags, notification event, and max gain setting.
- Keep the default maximum focused attribute gain at `20`.
- Keep the default focused training requirement at `5` valid battles.
- Keep graduation behavior unchanged.
- Use the corrected gain table from `mod_mentor_rookie/docs/corrected_attribute_gain.md`.

---

## File Structure

- Modify `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`
  Update only `calculateFocusedTrainingGain(_mentor, _rookie, _focusAttributeID)` so the first three cases use `+1` base gain instead of `+2`.

- Modify `mod_mentor_rookie/README.md`
  Update the player-facing Master Mentor Attribute Gain section so it matches the corrected formula.

- Modify `mod_mentor_rookie/docs/testing_list.md`
  Add or update focused-training test cases for the corrected gain values.

- Reference `mod_mentor_rookie/docs/corrected_attribute_gain.md`
  Treat this file as the source of truth for the corrected table. Do not rewrite it unless the user changes the design again.

---

### Task 1: Update Focused Training Gain Formula

**Files:**
- Modify: `mod_mentor_rookie/scripts/mods/mentor_rookie_service.nut`

**Interfaces:**
- Consumes: `::MentorRookie.Service.getTalentStars(_actor, _focusAttributeID)`
- Consumes: `::MentorRookie.Service.getSetting("MasterMentorChanceTwoToOne")`
- Consumes: `::MentorRookie.Service.getSetting("MasterMentorChanceThreeToOne")`
- Produces: corrected return value from `::MentorRookie.Service.calculateFocusedTrainingGain(_mentor, _rookie, _focusAttributeID)`

- [ ] **Step 1: Locate the existing formula**

Find this method in `mentor_rookie_service.nut`:

```nut
function calculateFocusedTrainingGain( _mentor, _rookie, _focusAttributeID )
```

Expected current behavior before this change:

```text
1-star mentor + 1-star rookie = +2
2-star mentor + 1-star rookie = +2, chance for +1 extra
3-star mentor + 1-star rookie = +2, chance for +1 extra
3-star mentor + 2-star rookie = +2
3-star mentor + 3-star rookie = +3
```

- [ ] **Step 2: Replace the first three base gains**

Change only these three cases:

```nut
if (mentorStars == 1 && rookieStars == 1)
{
	gain = 1;
}
else if (mentorStars == 2 && rookieStars == 1)
{
	gain = 1;
	if (::Math.rand(1, 100) <= this.getSetting("MasterMentorChanceTwoToOne")) gain += 1;
}
else if (mentorStars == 3 && rookieStars == 1)
{
	gain = 1;
	if (::Math.rand(1, 100) <= this.getSetting("MasterMentorChanceThreeToOne")) gain += 1;
}
else if (mentorStars == 3 && rookieStars == 2)
{
	gain = 2;
}
else if (mentorStars == 3 && rookieStars == 3)
{
	gain = 3;
}
```

- [ ] **Step 3: Preserve debug logging**

Keep the existing debug line after the formula:

```nut
::MentorRookie.Helpers.debugLog("focused training calculated mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " mentorStars=" + mentorStars + " rookieStars=" + rookieStars + " gain=" + gain);
```

Expected logs after this task:

```text
focused training calculated ... mentorStars=1 rookieStars=1 gain=1
focused training calculated ... mentorStars=2 rookieStars=1 gain=1
focused training calculated ... mentorStars=2 rookieStars=1 gain=2
focused training calculated ... mentorStars=3 rookieStars=1 gain=1
focused training calculated ... mentorStars=3 rookieStars=1 gain=2
focused training calculated ... mentorStars=3 rookieStars=2 gain=2
focused training calculated ... mentorStars=3 rookieStars=3 gain=3
```

- [ ] **Step 4: Build check**

Run from `mod_mentor_rookie` or use the existing project build workflow:

```powershell
modbb --game-data-dir test-results\build-corrected-attribute-gain
```

Expected: build succeeds with no Squirrel syntax errors.

---

### Task 2: Update Player Documentation

**Files:**
- Modify: `mod_mentor_rookie/README.md`

**Interfaces:**
- Consumes: corrected table in `mod_mentor_rookie/docs/corrected_attribute_gain.md`
- Produces: README section `### Attribute Gain` matching the implementation

- [ ] **Step 1: Find the Master Mentor Attribute Gain section**

Find this heading in `README.md`:

```markdown
### Attribute Gain
```

- [ ] **Step 2: Replace the gain table**

Use this exact player-facing table:

```markdown
The gain depends on mentor and rookie talent stars in the focused attribute:

- Mentor `1` star and rookie `1` star: `+1`.
- Mentor `2` stars and rookie `1` star: `+1`, with an `80%` default chance for `+1` extra.
- Mentor `3` stars and rookie `1` star: `+1`, with a `95%` default chance for `+1` extra.
- Mentor `3` stars and rookie `2` stars: `+2`.
- Mentor `3` stars and rookie `3` stars: `+3`.
```

- [ ] **Step 3: Keep the max-gain explanation unchanged**

Keep this meaning in the README:

```markdown
The default maximum permanent gain for one focused attribute in one relationship is `20`. This cap can be changed in MSU settings up to `200`.
```

- [ ] **Step 4: Add balance note for players**

Add this after the max-gain explanation:

```markdown
Because relationships can graduate before reaching the cap, the `20` maximum is a ceiling, not a guaranteed outcome. Lower-star pairings progress slowly, while rare high-star pairings can reach stronger results before graduation.
```

---

### Task 3: Update Manual Testing Checklist

**Files:**
- Modify: `mod_mentor_rookie/docs/testing_list.md`

**Interfaces:**
- Consumes: corrected implementation from Task 1
- Produces: manual test cases for corrected focused-training rewards

- [ ] **Step 1: Find the focused training test area**

Find the section that describes testing Master Mentor, Focused Training, attribute gain, or post-battle reward behavior.

- [ ] **Step 2: Add corrected reward cases**

Add this checklist:

```markdown
## Corrected Focused Training Attribute Gain

- [ ] Test `1` star mentor + `1` star rookie on the selected focus attribute.
  Expected: reward is `+1`.

- [ ] Test `2` star mentor + `1` star rookie on the selected focus attribute.
  Expected: reward is either `+1` or `+2`, depending on the configured `2-Star Mentor Bonus Chance` roll.

- [ ] Test `3` star mentor + `1` star rookie on the selected focus attribute.
  Expected: reward is either `+1` or `+2`, depending on the configured `3-Star Mentor Bonus Chance` roll.

- [ ] Test `3` star mentor + `2` star rookie on the selected focus attribute.
  Expected: reward is `+2`.

- [ ] Test `3` star mentor + `3` star rookie on the selected focus attribute.
  Expected: reward is `+3`.

- [ ] Set `Max Focused Attribute Gain` to a small value such as `2` and trigger repeated training rewards.
  Expected: total permanent focused gain does not exceed the configured cap.

- [ ] Confirm graduation still removes the relationship normally.
  Expected: focused training stops after graduation and does not keep applying rewards.
```

- [ ] **Step 3: Add log lines to inspect**

Add this under the focused-training checklist:

```markdown
Useful debug log lines:

- `focused training calculated`
- `focused training applied`
- `focused training notification queued`
- `focused training notification showing`
- `graduated`
```

---

### Task 4: In-Game Verification

**Files:**
- No code files modified in this task.

**Interfaces:**
- Consumes: build from Task 1
- Consumes: README/testing docs from Tasks 2 and 3
- Produces: confidence that implementation, docs, and player behavior match

- [ ] **Step 1: Build the mod**

Run:

```powershell
modbb --game-data-dir test-results\build-corrected-attribute-gain
```

Expected: build succeeds.

- [ ] **Step 2: Create or load a test campaign**

Use a roster where one mentor has `Master Mentor` and both mentor and rookie have visible talent stars in the same focused attribute.

Expected: `Shift+M` can create a relationship and activate Focused Training.

- [ ] **Step 3: Reduce required battles for faster test**

In MSU settings, set:

```text
Focused Training Battles = 1
```

Expected: one valid battle can trigger a focused training reward.

- [ ] **Step 4: Test a low-star pair**

Use a pair where both have `1` star in the focused attribute.

Expected event text example:

```text
Melee Skill: 55 -> 56 (+1)
```

- [ ] **Step 5: Test a high-star pair**

Use a pair where mentor has `3` stars and rookie has `3` stars in the focused attribute.

Expected event text example:

```text
Melee Skill: 55 -> 58 (+3)
```

- [ ] **Step 6: Confirm cap behavior**

Set:

```text
Max Focused Attribute Gain = 2
Focused Training Battles = 1
```

Trigger rewards until the cap is reached.

Expected: total focused gain stops at `2`, even if the calculated reward would be higher.

- [ ] **Step 7: Confirm graduation behavior**

Let the rookie meet graduation rules.

Expected: relationship clears, Mentor/Rookie effects are removed, and focused training no longer progresses.

---

## Self-Review

Spec coverage:

- Corrected `+1` base gain for `1/1`, `2/1`, and `3/1` is covered in Task 1.
- Existing `+2` and `+3` high-star gains are preserved in Task 1.
- Default max gain `20` remains unchanged in Tasks 1 and 2.
- Graduation behavior remains unchanged and is tested in Tasks 3 and 4.
- Player-facing docs are updated in Task 2.
- Manual testing documentation is updated in Task 3.

Placeholder scan:

- No `TBD`, `TODO`, or open-ended placeholder steps are present.
- Every code change uses exact function names and exact replacement logic.

Type consistency:

- `calculateFocusedTrainingGain(_mentor, _rookie, _focusAttributeID)` is used consistently.
- Settings names match existing MSU setting IDs: `MasterMentorChanceTwoToOne`, `MasterMentorChanceThreeToOne`, and `MasterMentorMaxGainPerAttribute`.
- Documentation values match `docs/corrected_attribute_gain.md`.
