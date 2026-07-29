# Mentor Rookie Manual Test Matrix

In progress.

Use this after building with `modbb`.

Latest verification source: `C:\Users\gujar\Documents\Battle Brothers\log.html`, last checked 2026-07-29 13:03.

Evidence:

- 11:40:24 normal battle captured 12 participants and counted all three active relationships:
  - Lienhard the Bear -> Sayid: 1 -> 2 battles, 22 mentor XP awarded.
  - Wilderich the Wolf -> Wasi: 2 -> 3 battles, 18 mentor XP awarded.
  - Ziggurat The Slayer -> Ayman: 1 -> 2 battles, 18 mentor XP awarded.
- 11:51:10 normal battle counted all three active relationships again:
  - Lienhard the Bear -> Sayid: 2 -> 3 battles, 21 mentor XP awarded.
  - Wilderich the Wolf -> Wasi: 3 -> 4 battles, 18 mentor XP awarded.
  - Ziggurat The Slayer -> Ayman: 2 -> 3 battles, 18 mentor XP awarded.
- 11:54:45 arena battle captured 3 participants. All three mentors were captured, all three rookies were absent, and every relationship was ignored with `reason=missing_or_dead_participant`. No relationship progressed.
- 12:40:12 accelerated milestone settings logged `milestone reached` for Wilderich the Wolf -> Wasi at 6 valid battles.
- 13:01:51 accelerated graduation settings logged:
  - Wilderich the Wolf -> Wasi: 6 -> 7 battles, rookie level 10, required battles 6, `shouldGraduate=true`.
  - `graduated mentor=Wilderich the Wolf rookie=Wasi reason=battle_and_level_requirement_met`.
  - Ziggurat The Slayer -> Ayman: 5 -> 6 battles and logged `milestone reached`.
- Character menu visual check: user confirmed after graduation/dismissal checks that stale Mentor Rookie status effects are not shown.

1. Install with MSU and Modern Hooks. Done
2. Start or load a save on the world map. Done
3. Press `Shift+M`; the Mentor Rookie screen should open only when no blocking world UI is active. Done
4. Create a valid pair: mentor level 6+, rookie level 10 or below, mentor higher level than rookie. Done
5. Attempt invalid pairs: same brother, mentor too low, rookie too high, rookie same or higher level, duplicate mentor, duplicate rookie. Done
6. Fight a battle with both members deployed and surviving. Done
7. Confirm `log.html` records participant capture, battle count, and mentor XP award. Done
8. Fight a battle where one member is not deployed or dies; confirm relationship does not progress. Done
9. Confirm milestones log at configured milestone thresholds. Done with accelerated threshold at 6 battles; default 5, 15, 30, and 50 thresholds were not individually replayed.
10. Confirm graduation removes effects from the character menu. Done by user visual check after graduation; the separate immediate graduation trigger for rookie reaching/passing mentor level was not separately log-verified.
11. Confirm graduation after configured battle count when the rookie reaches configured graduation level. Done with accelerated settings: required battles 6, required rookie level 10.
12. Dismiss either the mentor or the rookie; confirm the relationship is removed and the remaining brother does not keep stale Mentor Rookie flags/effects. Done
