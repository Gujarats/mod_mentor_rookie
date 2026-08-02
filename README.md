# Mentor Rookie

Mentor Rookie lets one experienced brother mentor one lower-level rookie. Gives the rookie proper mentor to grow stonger.

## Requirements

- Battle Brothers with Blazing Deserts support recommended for arena testing.
- Modern Hooks.
- MSU.

## How To Use

1. Start or load a campaign on the world map.
2. Press `Shift+M` to open the Mentor Rookie screen.
3. Select a mentor on the left.
4. Select a rookie on the right.
5. Create the relationship.
6. Put both brothers into battles together.

The keybind only works from the world map when no blocking UI is open. It will not open during combat, events, town screens, the character screen, or other modal screens.

## Mentor Rules

- A mentor must be higher level than the rookie.
- By default, a mentor must be at least level `6`.
- A mentor can only mentor one rookie at a time.
- A brother who is already a rookie cannot also be selected as a mentor.

## Rookie Rules

- A rookie must be lower level than the selected mentor.
- By default, a rookie must be level `10` or below.
- A rookie can only have one mentor at a time.
- A brother who is already a mentor cannot also be selected as a rookie.

## Battle Progress

A battle counts only when:

- the mentor participates in the battle,
- the rookie participates in the battle,
- both survive the battle.

If either brother is in reserve, not selected for an arena fight, missing from combat, or dead at the end, that battle does not progress the relationship.

Arena fights work normally. Because the arena only uses collared fighters, a mentor and rookie can be separated there. If only one side enters the arena, the relationship does not progress.

## XP Bonus

After a valid battle, the rookie receives bonus XP based on the rookie's final vanilla battle XP.

Default bonus:

- Level `1-3`: `+20%`
- Level `4-6`: `+15%`
- Level `7-10`: `+12%`

The mentor does not lose XP.

Training Hall, Drill Sergeant, and other normal XP modifiers apply first. Mentor Rookie then calculates its bonus from the rookie's final battle XP and logs the actual amount awarded.

## Status Effects

Active relationships show visible passive effects in the character menu:

- `Mentor` on the mentor.
- `Rookie` on the rookie.

The rookie tooltip shows the mentor name, current XP bonus, battles fought together, and graduation requirements.

These effects are removed automatically when the relationship ends or graduates.

## Graduation

A relationship graduates and is removed when either condition is met:

- the rookie reaches or passes the mentor's level,
- or the rookie reaches the configured graduation level after the configured number of valid battles.

Default graduation settings:

- Graduation battle count: `50`
- Graduation level: `10`

Graduation removes the active Mentor/Rookie status effects.

## Relationship History

Removing a mentor-rookie relationship from the `Shift+M` screen removes the active relationship and passive effects, but the pair's history is preserved.

If the same mentor and same rookie are coupled again later, the mod restores that pair's previous battle count, focused attribute, focused-training progress, and focused-training gain.

History is pair-specific. For example, Mentor A with Rookie B has separate history from Mentor C with Rookie B. This prevents progress from one mentor being transferred freely to another mentor.

## Settings

Settings are available through MSU:

- `Debug Logging`: writes Mentor Rookie details to `log.html`.
- `Minimum Mentor Level`: default `6`.
- `Maximum Rookie Level`: default `10`.
- `Level 1-3 Bonus XP (%)`: default `20`.
- `Level 4-6 Bonus XP (%)`: default `15`.
- `Level 7-10 Bonus XP (%)`: default `12`.
- `Milestone 1 Battles`: default `5`.
- `Milestone 2 Battles`: default `15`.
- `Milestone 3 Battles`: default `30`.
- `Graduation Battle Count`: default `50`.
- `Graduation Level`: default `10`.
- `Master Mentor Perk Row`: default `6`, requires restart.
- `Enable Focused Training`: default `true`.
- `Focused Training Battles`: default `5`.
- `Max Focused Attribute Gain`: default `20`.
- `Require Both Alive`: default `true`.
- `Require Mentor Participation`: default `true`.
- `2-Star Mentor Bonus Chance`: default `80`.
- `3-Star Mentor Bonus Chance`: default `95`.

## Master Mentor Perk

The `Master Mentor` perk unlocks Focused Training for an existing mentor-rookie relationship.

Focused Training is separate from the normal rookie XP bonus. The normal mentor-rookie XP system still works without this perk.

### How Focused Training Works

1. Create a mentor-rookie relationship from the `Shift+M` screen.
2. The mentor must have the `Master Mentor` perk.
3. Select the active relationship in the Mentor Rookie screen.
4. Press `Activate Focused Training`.
5. Choose one eligible attribute for the rookie to focus on.
6. Fight valid battles together until the focused training requirement is reached.

When the requirement is reached, the rookie receives a permanent gain to the selected attribute. A training event is shown afterward with the mentor name, rookie name, portrait images, and the attribute result.

### Eligible Attributes

Focused Training can use these attributes:

- Hitpoints
- Fatigue
- Resolve
- Initiative
- Melee Skill
- Ranged Skill
- Melee Defense
- Ranged Defense

An attribute is only eligible if both the mentor and the rookie have at least one talent star in that attribute, and the mentor has at least as many talent stars as the rookie.

### Locked Focus Choice

The focused attribute is locked after it is selected for that relationship.

This means you should choose carefully. The relationship is meant to make mentor and rookie hiring more selective from the start, not to freely swap training targets after every battle.

### Focused Training Progress

By default, Focused Training rewards trigger every `5` valid battles together.

A focused training battle usually requires:

- the mentor participates,
- the rookie participates,
- both survive the battle.

These requirements can be changed in MSU settings.

### Attribute Gain

The gain depends on mentor and rookie talent stars in the focused attribute:

- Mentor `1` star and rookie `1` star: `+1`.
- Mentor `2` stars and rookie `1` star: `+1`, with an `80%` default chance for `+1` extra.
- Mentor `2` stars and rookie `2` stars: `+2`.
- Mentor `3` stars and rookie `1` star: `+1`, with a `95%` default chance for `+1` extra.
- Mentor `3` stars and rookie `2` stars: `+2`.
- Mentor `3` stars and rookie `3` stars: `+3`.

The default maximum permanent gain for one focused attribute in one relationship is `20`. This cap can be changed in MSU settings up to `200`.

Because relationships can graduate before reaching the cap, the `20` maximum is a ceiling, not a guaranteed outcome. Lower-star pairings progress slowly, while rare high-star pairings can reach stronger results before graduation.

Focused Training does not transfer traits, backgrounds, or talent stars. It only adds permanent attribute points to the chosen attribute.

## Legends Compatibility

When Legends is installed, `Master Mentor` is added to every Legends player background. The configured Master Mentor perk row is treated as a preference: Legends can place the perk in another row when that row is full so the perk remains visible and selectable.

## Debugging

If debug logging is enabled, check:

`C:\Users\<your user>\Documents\Battle Brothers\log.html`

Useful log lines include:

- `created relationship`
- `captured battle participants`
- `battle relationship checked`
- `valid battle counted`
- `battle ignored`
- `awarded mentor XP`
- `milestone reached`
- `graduated`

## Known Issues

- The Mentor Rookie screen may not show every character at once while browsing the mentor and rookie lists. Scroll up or down in the list to find the character you want.
- Stale relationship cleanup has only been verified for a partner that no longer exists in the current player roster. It has not yet been tested in game for manual dismissal, tactical death, or devour/eaten removal paths.
