# Master Mentor Perk High-Level Plan

## Purpose

The `Master Mentor` perk should make veteran hiring and rookie development a meaningful long-term decision. A strong mentor is not only valuable in battle, but can also shape a rookie's future growth when the player intentionally pairs them and chooses a training focus.

This design intentionally allows strong long-term scaling. Balance should be handled through configuration so each player can tune the system to their preferred power level.

## Core Idea

When a mentor has the `Master Mentor` perk, the mentor-rookie menu allows the player to choose one focused attribute for that mentor-rookie pair.

The selected focus represents what the mentor is actively training the rookie in.

Once the focus attribute is selected, it is locked for that mentor-rookie relation. The focus should not be changed later unless a future configuration option explicitly enables changing focus.

Example focus attributes:

- Melee Skill
- Ranged Skill
- Melee Defense
- Ranged Defense
- Hitpoints
- Fatigue
- Resolve
- Initiative

The focused attribute should only be valid when the mentor and rookie have at least one matching talent star in that attribute.

## Training Trigger

After the mentor and rookie fight together for a configured number of battles, the rookie can receive a permanent attribute gain in the selected focus attribute.

Default trigger idea:

- Required battles together: `5`
- Mentor and rookie must both survive the battle
- The mentor-rookie relation must still be active
- The selected focus attribute must still be valid

The reward should be checked after battle. If a reward is applied, the player should be notified with a world event-style menu.

## Attribute Gain Rules

The reward is based on the mentor's talent stars and the rookie's talent stars in the selected focus attribute.

Suggested default rules:

- Mentor 1 star and rookie 1 star: rookie gains `+1` permanent attribute point.
- Mentor 1 star and rookie 1 star with matching selected focus: rookie gains `+2` permanent attribute points.
- Mentor 2 stars and rookie 1 star: same as the 1-star mentor result, with an additional `80%` chance to gain `+1` extra permanent attribute point.
- Mentor 3 stars and rookie 1 star: same as the 1-star mentor result, with an additional `95%` chance to gain `+1` extra permanent attribute point.
- Mentor 3 stars and rookie 2 stars: rookie gains `+2` permanent attribute points.
- Mentor 3 stars and rookie 3 stars: rookie gains `+3` permanent attribute points.

The wording in UI and logs should call this a permanent attribute gain, not a talent star increase. The perk improves the rookie's actual attribute, while the talent stars are used to decide how effective the training is.

The default maximum permanent gain for a focused attribute is `20`, configurable. Once the maximum is reached, that mentor-rookie relation cannot increase that focused attribute any further.

If the rookie graduates from the mentor-rookie relation, that relation cannot produce more attribute gains.

The mentor does not lose attributes, experience, talent stars, or any other resource. This is purely beneficial training.

## Configuration

The system should be configurable because this feature is intentionally powerful and personal-preference driven.

Recommended options:

- Enable or disable `Master Mentor` focused training.
- Required battles before training reward.
- Allowed focus attributes.
- Minimum mentor level.
- Whether mentor and rookie must both survive.
- Whether mentor must participate in the battle.
- Maximum permanent attribute gains per mentor-rookie pair.
- Maximum permanent attribute gains per rookie total.
- Attribute gain amount for each star combination.
- Chance values for additional gains.
- Whether training progress resets after reward or continues accumulating.
- Maximum permanent gain per focused attribute. Default: `20`.
- Whether focus attribute changes are allowed after initial selection. Default: disabled.

If focus changes are disabled, no progress reset behavior is needed. If a future option enables focus changes, the safest default is to reset current training progress when the focus changes.

## UI Expectations

The mentor-rookie menu should clearly show:

- Which mentor-rookie pairs are active.
- Whether the mentor has `Master Mentor`.
- Which focused attribute is selected.
- How many battles remain before the next training reward.
- Why an attribute cannot be selected, if it is invalid.
- Whether the selected focus is locked.
- Total permanent gain already received for the focused attribute.
- Maximum permanent gain allowed for the focused attribute.

The character passive skill tooltip should explain the current mentor, focused attribute, and training progress.

## Training Notification Event

When training successfully increases a rookie attribute, show a world event-style notification after battle.

The notification should include:

- Mentor name.
- Rookie name.
- Mentor portrait.
- Rookie portrait.
- Focused attribute name.
- Previous attribute value.
- New attribute value.
- Total gain applied.

Example display:

```text
Melee Skill: 55 -> 57 (+2)
```

This should use the full vanilla `WorldEventScreen` style instead of the smaller event popup. The full event screen already supports left and right character portraits, which fits the mentor-rookie relationship better.

The event should feel like a relationship moment, not just a mechanical log entry. The text should make it clear that the mentor's training helped the rookie improve.

Example event text:

```text
{mentor} has guided {rookie} through enough battles for the lesson to become instinct.

{rookie} improved:
Melee Skill: 55 -> 57 (+2)
```

## Event Queue Safety

The mentor training notification should not be added to the normal random event pool.

Instead, training rewards should create pending notification payloads. Each payload should store the mentor, rookie, focused attribute, previous value, new value, and gain amount.

When the world event system is free, the mod can show one pending mentor-rookie notification.

Before showing the notification, the mod should check that event UI is available. Conceptually:

```nut
if (::World.Events.canFireEvent(true, true))
{
    // show the pending mentor-rookie training event
}
else
{
    // keep it pending and retry later
}
```

This avoids competing with vanilla random events or showing two event screens at the same time.

If multiple mentor-rookie rewards happen after one battle, show them one at a time.

## Logging

Debug logs should be added for important state changes:

- Focus attribute selected.
- Battle progress incremented.
- Training reward triggered.
- Chance roll passed or failed.
- Attribute gain applied.
- Training skipped because requirements were not met.
- Training notification queued.
- Training notification shown.
- Training notification delayed because world event UI is busy.

Logging should be configurable and default to enabled for initial development.

## Current Decisions

- Attribute gain is checked after battle.
- Successful gains show a world event-style notification.
- The notification should show both mentor and rookie names.
- The notification should show both mentor and rookie portraits.
- The notification should summarize the attribute change, for example `Melee Skill: 55 -> 57 (+2)`.
- Focus attribute is locked after selection.
- Default maximum gain for the focused attribute is `20`, configurable.
- Mentor does not lose anything from training.
- Rookie graduation ends further gains from that mentor-rookie relation.
