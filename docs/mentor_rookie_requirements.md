# Mentor Rookie Requirements

## Goal

Create a mentoring system where one experienced brother can mentor one lower-level brother. The system should help rookies catch up through experience sharing while keeping hiring, talents, traits, and long-term character identity balanced.

## Core Rules

- A mentor must be higher level than the rookie.
- A mentor must meet the minimum mentor level.
- Default minimum mentor level is `6`.
- Minimum mentor level must be configurable through options.
- A rookie can be any lower-level brother below the selected mentor's level.
- A rookie can only have one mentor.
- A mentor can only have one rookie.
- The relationship is always one-to-one.
- If the rookie reaches or passes the mentor's level, the mentor relationship is automatically removed.
- Reaching or passing the mentor's level counts as immediate graduation, even before the normal graduation battle-count check.
- The mentor relationship should also be removed if either brother dies, leaves the roster, or otherwise becomes invalid.

## Assignment UI

- Add a world-screen keybind to open the mentor assignment menu.
- The menu should show eligible mentors in the first column.
- Eligible mentors are brothers at or above the configured minimum mentor level.
- After selecting a mentor, the second column should show eligible rookies.
- Eligible rookies are brothers with a lower level than the selected mentor.
- After selecting both mentor and rookie, the relationship is created.
- The rookie receives a visible passive effect in the character screen.
- The mentor receives a visible passive effect in the character screen.
- Passive effects should explain the active mentoring relationship.
- Passive effects should be removable only through the mentor system, not as a normal temporary injury or combat status.

## Battle Participation Requirement

- Mentoring progress is based on battles spent together, not days.
- A battle counts only if both mentor and rookie participate in the same battle.
- A battle counts only if both mentor and rookie survive the battle.
- If either brother is in reserve and does not participate, the battle does not count.
- If the battle is lost, fled, or otherwise does not award normal battle XP, the battle should not count unless explicitly supported later.

## Experience Sharing

- After a valid battle together, the rookie gains bonus experience from the mentor.
- The mentor does not lose experience.
- The rookie bonus is based on rookie level.
- Default experience bonus by rookie level:
  - Level `1-3`: `20%`
  - Level `4-6`: `15%`
  - Level `7-10`: `12%`
  - Level `11+`: cannot be mentored by default
- All experience percentages must be configurable through options.
- Maximum rookie level for mentoring must be configurable through options.
- Default maximum rookie level is `10`.
- The bonus should be calculated from the mentor's battle XP contribution or from the rookie's earned battle XP, depending on which approach is safer after implementation research.
- The chosen calculation method must be documented before implementation.

## Master Mentor Perk

- Add a mentor perk named `Master Mentor`.
- Default perk row is `6`.
- Perk row must be configurable through options.
- The perk improves the mentor relationship but should not change hiring balance by default.
- The default first release should not transfer talent stars.
- The default first release should not transfer traits.
- Star transfer and trait transfer may be implemented later as optional advanced systems, but they must be disabled by default if added.

## Battle Milestones

- Track the number of valid battles the mentor and rookie have spent together.
- Milestones should be based on battle count, not calendar days.
- Suggested default milestones:
- `5` battles together: relationship is established and the rookie mentoring effect upgrades its description to show progress.
- `15` battles together: rookie receives a small configurable XP bonus increase.
- `30` battles together: advanced mentor bond milestone is reached.
- `50` battles together: graduation check begins.
- Graduation should not happen before `50` valid battles together by default unless the rookie reaches or passes the mentor's level.
- After graduation check begins, the relationship graduates when the rookie reaches the configured graduation level.
- The relationship also graduates immediately if the rookie reaches or passes the mentor's level.
- Default graduation level is `10`.
- Graduation level must be configurable.
- Graduation should remove the active mentor relationship once its configured condition is met.
- Graduation may leave a harmless permanent history flag for future UI/logging.
- Milestone battle counts must be configurable through options.

## Balance Constraints

- The first release should focus on XP catch-up only.
- The first release should not copy good traits from mentor to rookie.
- The first release should not copy talent stars from mentor to rookie.
- The system should not make hiring strong rookies irrelevant.
- The system should not make veteran brothers an infinite source of permanent upgrades.
- The system should reward using mentor and rookie together in real battles.
- Waiting on the world map should not advance mentoring progress.

## Settings

- `MinimumMentorLevel`
- `MaximumRookieLevel`
- `Level1To3XPBonusPercent`
- `Level4To6XPBonusPercent`
- `Level7To10XPBonusPercent`
- `MasterMentorPerkRow`
- `EnableMasterMentorPerk`
- `BattlesForFirstMilestone`
- `BattlesForSecondMilestone`
- `BattlesForAdvancedMilestone`
- `BattlesBeforeGraduationCheck`
- `GraduationRookieLevel`
- `DebugLogging`

## Debugging

- Add debug logging behind a configurable option.
- Debug logs should record:
  - mentor relationship created,
  - mentor relationship removed,
  - reason relationship was removed,
  - valid battle counted,
  - invalid battle ignored,
  - XP bonus awarded,
  - milestone reached,
  - graduation reached.

## Compatibility

- Use MSU settings.
- Use modern hooks.
- Do not modify vanilla files directly.
- Do not modify community mods directly.
- Keep all behavior isolated inside `mod_mentor_rookie`.
- If compatibility with another mod is needed later, create a separate patch plan before implementation.
