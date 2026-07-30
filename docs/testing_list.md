# Mentor Rookie Testing List

This list covers the in-game mechanics that should be tested for `mod_mentor_rookie`, including the planned `Master Mentor` focused training feature.

Some checks can be automated with scripted helper/debug functions, but Battle Brothers UI flows, event screens, portraits, save/reload behavior, and real battle outcomes still need manual in-game verification.

## Automation Feasibility

Can be partially automated:

- Settings existence and default values.
- Service validation rules.
- Focus attribute eligibility calculations.
- Reward calculation per star combination.
- Max gain cap logic.
- Relationship flag write/clear logic.
- Pending notification queue behavior.
- Debug log output for service methods.

Needs manual in-game testing:

- Shift+M screen layout.
- Portrait rendering.
- Click behavior.
- MSU setting UI persistence.
- Real battle participation capture.
- Post-battle event screen display.
- Vanilla event conflict behavior.
- Save/reload persistence.
- Tooltip display.

## 1. Basic Load Test

- [ ] Start Battle Brothers with `mod_mentor_rookie` enabled.
- [ ] Load or start a campaign.
- [ ] Confirm no crash on main menu.
- [ ] Confirm no crash entering world map.
- [ ] Check `C:\Users\gujar\Documents\Battle Brothers\log.html`.
- [ ] Confirm mod init/debug logs appear.

## 2. Settings Test

- [ ] Open MSU/mod settings.
- [ ] Confirm Mentor Rookie settings exist.
- [ ] Confirm minimum mentor level setting exists.
- [ ] Confirm maximum rookie level setting exists.
- [ ] Confirm XP bonus settings exist.
- [ ] Confirm graduation settings exist.
- [ ] Confirm Master Mentor perk row setting exists.
- [ ] Confirm focused training enabled setting exists.
- [ ] Confirm focused training battle requirement setting exists.
- [ ] Confirm max focused attribute gain setting exists.
- [ ] Confirm bonus chance settings exist.
- [ ] Change one setting.
- [ ] Close menu and reopen it.
- [ ] Confirm changed setting persists.

## 3. Shift+M Screen Test

- [ ] Press `Shift+M` on world map.
- [ ] Confirm Mentor/Rookie screen opens.
- [ ] Confirm mentor list renders.
- [ ] Confirm rookie list renders.
- [ ] Confirm portraits render.
- [ ] Confirm Close button works.
- [ ] Confirm screen does not open while an event screen is active.
- [ ] Confirm screen does not open during battle.

## 4. Basic Relationship Validation

- [ ] Try creating pair with no mentor selected.
- [ ] Confirm clear rejection message.
- [ ] Try creating pair with no rookie selected.
- [ ] Confirm clear rejection message.
- [ ] Try mentor equals rookie.
- [ ] Confirm clear rejection message.
- [ ] Try mentor below minimum level.
- [ ] Confirm clear rejection message.
- [ ] Try rookie above maximum level.
- [ ] Confirm clear rejection message.
- [ ] Try mentor lower or equal level than rookie.
- [ ] Confirm clear rejection message.
- [ ] Try using a brother already mentoring.
- [ ] Confirm clear rejection message.
- [ ] Try using a brother already assigned as rookie.
- [ ] Confirm clear rejection message.

## 5. Basic Relationship Creation

- [ ] Select valid mentor.
- [ ] Select valid rookie.
- [ ] Create pair.
- [ ] Confirm Active Relationships shows the pair.
- [ ] Confirm mentor gets mentor passive effect.
- [ ] Confirm rookie gets rookie passive effect.
- [ ] Confirm passive tooltip shows mentor/rookie info.
- [ ] Save and reload.
- [ ] Confirm relationship still exists after reload.

## 6. XP Bonus Test

- [ ] Create mentor-rookie pair.
- [ ] Fight battle with both participating and alive.
- [ ] Confirm rookie gets bonus XP after battle.
- [ ] Check log for base XP, percent, input bonus, and actual awarded XP.
- [ ] Test rookie level 1-3 bonus.
- [ ] Test rookie level 4-6 bonus.
- [ ] Test rookie level 7-10 bonus.
- [ ] Confirm configured percentages are respected.

## 7. Battle Participation Test

- [ ] Fight battle where mentor participates but rookie does not.
- [ ] Confirm battle count does not increase.
- [ ] Fight battle where rookie participates but mentor does not.
- [ ] Confirm battle count does not increase.
- [ ] Fight battle where one member dies.
- [ ] Confirm configured alive/participation rules are respected.
- [ ] Confirm logs explain why battle was ignored.

## 8. Graduation Test

- [ ] Set graduation battle count low for testing.
- [ ] Create valid pair.
- [ ] Fight enough battles.
- [ ] Confirm rookie graduates only when graduation rules are met.
- [ ] Test rookie reaching mentor level.
- [ ] Confirm relationship clears.
- [ ] Confirm mentor passive effect is removed.
- [ ] Confirm rookie passive effect is removed.
- [ ] Confirm logs show graduation reason.

## 9. Master Mentor Perk Test

- [ ] Confirm perk appears in configured perk row.
- [ ] Give or acquire `Master Mentor` on a mentor.
- [ ] Open `Shift+M`.
- [ ] Select mentor with perk and valid rookie.
- [ ] Confirm Focused Training section appears.
- [ ] Select mentor without perk.
- [ ] Confirm focus attributes are locked with reason.

## 10. Focus Attribute Eligibility Test

- [ ] Select mentor and rookie with matching talent stars.
- [ ] Confirm matching attributes are selectable.
- [ ] Confirm non-matching attributes are locked.
- [ ] Confirm each row shows attribute name.
- [ ] Confirm each row shows mentor stars.
- [ ] Confirm each row shows rookie stars.
- [ ] Confirm each row shows available/locked reason.
- [ ] Confirm no dropdown is used.
- [ ] Confirm selecting a valid focus highlights it.

## 11. Focus Lock Test

- [ ] Create relationship with selected focus.
- [ ] Reopen Shift+M.
- [ ] Confirm active relationship shows selected focus.
- [ ] Confirm focus is locked.
- [ ] Confirm focus cannot be changed before reaching max gain.
- [ ] Save and reload.
- [ ] Confirm locked focus persists.

## 12. Focused Training Progress Test

- [ ] Set required battles to a low number, such as `1` or `2`.
- [ ] Create focused relationship.
- [ ] Fight valid battle.
- [ ] Confirm focused training progress increments.
- [ ] Confirm passive tooltip shows progress.
- [ ] Confirm Active Relationships shows progress.
- [ ] Confirm progress resets after reward triggers.

## 13. Attribute Gain Rule Test

- [ ] Test Mentor 1 star / Rookie 1 star.
- [ ] Confirm expected gain is `+1`.
- [ ] Test Mentor 2 stars / Rookie 1 star.
- [ ] Confirm expected gain is `+1` or `+2`, depending on the configured `2-Star Mentor Bonus Chance` roll.
- [ ] Test Mentor 3 stars / Rookie 1 star.
- [ ] Confirm expected gain is `+1` or `+2`, depending on the configured `3-Star Mentor Bonus Chance` roll.
- [ ] Test Mentor 3 stars / Rookie 2 stars.
- [ ] Confirm expected gain is `+2`.
- [ ] Test Mentor 3 stars / Rookie 3 stars.
- [ ] Confirm expected gain is `+3`.
- [ ] For each case, record rookie attribute before battle.
- [ ] For each case, confirm rookie attribute after battle.
- [ ] For each case, confirm log shows mentor stars, rookie stars, roll chance, and final gain.

## 14. Max Gain Cap Test

- [ ] Set max focused attribute gain low, such as `3`.
- [ ] Trigger multiple rewards.
- [ ] Confirm gain never exceeds cap.
- [ ] Confirm once cap is reached, no further increase happens.
- [ ] Confirm UI shows gain cap, for example `3 / 3`.
- [ ] Confirm logs say max gain reached.
- [ ] Set max focused attribute gain to `2`.
- [ ] Trigger repeated rewards with a high-star pair.
- [ ] Confirm total permanent focused gain does not exceed `2`.

## 15. Notification Event Test

- [ ] Trigger focused training reward.
- [ ] Confirm full event screen appears after battle.
- [ ] Confirm mentor name appears.
- [ ] Confirm rookie name appears.
- [ ] Confirm mentor portrait appears.
- [ ] Confirm rookie portrait appears.
- [ ] Confirm attribute summary appears, for example `Melee Skill: 55 -> 57 (+2)`.
- [ ] Press Continue.
- [ ] Confirm world returns normally.

## 16. Event Queue Safety Test

- [ ] Trigger reward when another vanilla event is active or about to show.
- [ ] Confirm mentor event does not overlap.
- [ ] Confirm mentor event waits until event UI is free.
- [ ] Confirm pending notification appears later.
- [ ] Confirm log shows notification delayed, queued, and shown.

## 17. Multiple Rewards Same Battle

- [ ] Create multiple mentor-rookie pairs if the mod allows it.
- [ ] Trigger more than one focused reward after the same battle.
- [ ] Confirm notifications show one at a time.
- [ ] Confirm no notification is lost.
- [ ] Confirm each notification shows the correct mentor, rookie, and attribute.

## 18. Remove Relationship Test

- [ ] Create focused relationship.
- [ ] Remove it from Shift+M.
- [ ] Confirm active relationship disappears.
- [ ] Confirm passive effects are removed.
- [ ] Confirm focus flags are cleared.
- [ ] Fight battle afterward.
- [ ] Confirm removed relationship gives no XP.
- [ ] Confirm removed relationship gives no attribute gain.

## 19. Save/Reload Persistence Test

- [ ] Create focused relationship.
- [ ] Gain partial progress.
- [ ] Save.
- [ ] Reload.
- [ ] Confirm relationship persists.
- [ ] Confirm focus persists.
- [ ] Confirm progress persists.
- [ ] Confirm total gain persists.
- [ ] Confirm passive tooltips are still correct.
- [ ] Trigger reward after reload.

## 20. Regression Test

- [ ] Start a fresh campaign.
- [ ] Use mod without selecting Master Mentor focus.
- [ ] Confirm old mentor-rookie XP system still works.
- [ ] Confirm relationship creation without focus still works if intended.
- [ ] Confirm no crashes when no relationship exists.
- [ ] Confirm no crashes when all relationships graduate.
- [ ] Confirm no crashes when relationships are removed.

## Priority Manual Test Set

If there is not enough time to run everything, prioritize these:

- [ ] Basic relationship creation.
- [ ] XP bonus after battle.
- [ ] Graduation.
- [ ] Master Mentor focus eligibility.
- [ ] Focus lock persistence.
- [ ] Focused training reward.
- [ ] Post-battle notification event.
- [ ] Save/reload persistence.
