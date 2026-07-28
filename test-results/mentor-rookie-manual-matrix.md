# Mentor Rookie Manual Test Matrix

Not run yet.

Use this after building with `modbb`.

1. Install with MSU and Modern Hooks.
2. Start or load a save on the world map.
3. Press `Shift+M`; the Mentor Rookie screen should open only when no blocking world UI is active.
4. Create a valid pair: mentor level 6+, rookie level 10 or below, mentor higher level than rookie.
5. Attempt invalid pairs: same brother, mentor too low, rookie too high, rookie same or higher level, duplicate mentor, duplicate rookie.
6. Fight a battle with both members deployed and surviving.
7. Confirm `log.html` records participant capture, battle count, and mentor XP award.
8. Fight a battle where one member is not deployed or dies; confirm relationship does not progress.
9. Confirm milestones log at 5, 15, 30, and 50 valid battles.
10. Confirm graduation removes effects when the rookie reaches/passes mentor level.
11. Confirm graduation after 50 valid battles when the rookie reaches configured graduation level.
