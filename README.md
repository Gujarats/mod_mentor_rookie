# Mentor Rookie

Version `0.0.1`.

Mentor Rookie lets one experienced brother mentor one lower-level rookie. When both brothers fight and survive the same battle, the rookie gains extra XP based on the rookie's normal battle XP.

The mod is meant as an XP catch-up system. It does not copy traits, talent stars, backgrounds, or stats from the mentor.

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

## Master Mentor Perk

The `Master Mentor` perk is currently a perk shell only in version `0.0.1`. It is visible for future compatibility, but it does not currently add extra bonuses by itself.

Current behavior:

- It is not required to create a mentor-rookie relationship.
- It does not increase the rookie XP bonus.
- It does not unlock mentoring.
- It does not transfer traits.
- It does not transfer talent stars.
- It does not change graduation rules.

The actual mentoring system works through the `Shift+M` relationship screen and the visible `Mentor` / `Rookie` status effects.

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

## Compatibility Notes

This mod uses Modern Hooks and MSU settings. It does not edit vanilla files directly.
