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

Debug Logging defaults to enabled. Inspect `C:\Users\gujar\Documents\Battle Brothers\log.html` for `[MentorRookie] [Legends]` entries covering registration, insertion, duplicate skips, and unavailable APIs.

## Manual Testing

1. Load a campaign without Legends and verify the existing Master Mentor UI injection remains available.
2. Load a campaign with Legends and verify every player background contains exactly one selectable Master Mentor perk.
3. Set the preferred row to a row containing at least 13 perks and verify Legends places Master Mentor in another row.
4. Save and reload after purchasing Master Mentor; verify it persists and Focused Training recognizes it.
