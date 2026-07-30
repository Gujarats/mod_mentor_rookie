if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

::MentorRookie.registerSettings <- function()
{
	local general = ::MentorRookie.Mod.ModSettings.addPage("General");
	local xp = ::MentorRookie.Mod.ModSettings.addPage("Experience");
	local graduation = ::MentorRookie.Mod.ModSettings.addPage("Graduation");
	local perk = ::MentorRookie.Mod.ModSettings.addPage("Perk");

	general.addBooleanSetting("DebugLogging", true, "Debug Logging", "Write Mentor Rookie debug lines to log.html.");
	general.addRangeSetting("MinimumMentorLevel", 6, 2, 33, 1, "Minimum Mentor Level", "A brother must be at least this level to become a mentor.");
	general.addRangeSetting("MaximumRookieLevel", 10, 1, 33, 1, "Maximum Rookie Level", "A brother above this level cannot become a rookie.");

	xp.addRangeSetting("Level1To3BonusPercent", 20, 0, 100, 1, "Level 1-3 Bonus XP (%)", "Bonus XP applied to final vanilla battle XP for rookies at levels 1 to 3.");
	xp.addRangeSetting("Level4To6BonusPercent", 15, 0, 100, 1, "Level 4-6 Bonus XP (%)", "Bonus XP applied to final vanilla battle XP for rookies at levels 4 to 6.");
	xp.addRangeSetting("Level7To10BonusPercent", 12, 0, 100, 1, "Level 7-10 Bonus XP (%)", "Bonus XP applied to final vanilla battle XP for rookies at levels 7 to 10.");

	graduation.addRangeSetting("MilestoneOne", 5, 1, 200, 1, "Milestone 1 Battles", "First relationship milestone.");
	graduation.addRangeSetting("MilestoneTwo", 15, 1, 200, 1, "Milestone 2 Battles", "Second relationship milestone.");
	graduation.addRangeSetting("MilestoneThree", 30, 1, 200, 1, "Milestone 3 Battles", "Third relationship milestone.");
	graduation.addRangeSetting("GraduationBattleCount", 50, 1, 300, 1, "Graduation Battle Count", "Graduation checks begin after this many valid battles together.");
	graduation.addRangeSetting("GraduationLevel", 10, 2, 33, 1, "Graduation Level", "After enough battles, the rookie graduates when reaching this level.");

	perk.addRangeSetting("MasterMentorPerkRow", 6, 1, 7, 1, "Master Mentor Perk Row", "Which perk row displays the Master Mentor perk shell. Requires restart.");
	perk.addBooleanSetting("MasterMentorFocusedTrainingEnabled", true, "Enable Focused Training", "Enable permanent focused attribute gains from the Master Mentor perk.");
	perk.addRangeSetting("MasterMentorRequiredBattles", 5, 1, 200, 1, "Focused Training Battles", "Battles together required before a focused training reward can trigger.");
	perk.addRangeSetting("MasterMentorMaxGainPerAttribute", 20, 1, 200, 1, "Max Focused Attribute Gain", "Maximum permanent gain a rookie can receive for one focused attribute from one mentor-rookie relation.");
	perk.addBooleanSetting("MasterMentorRequireBothAlive", true, "Require Both Alive", "Mentor and rookie must both survive the battle for focused training progress.");
	perk.addBooleanSetting("MasterMentorRequireMentorParticipated", true, "Require Mentor Participation", "Mentor must participate in the battle for focused training progress.");
	perk.addRangeSetting("MasterMentorChanceTwoToOne", 80, 0, 100, 1, "2-Star Mentor Bonus Chance", "Chance for Mentor 2 stars and Rookie 1 star to grant an additional +1.");
	perk.addRangeSetting("MasterMentorChanceThreeToOne", 95, 0, 100, 1, "3-Star Mentor Bonus Chance", "Chance for Mentor 3 stars and Rookie 1 star to grant an additional +1.");
}
