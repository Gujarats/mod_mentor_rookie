this.mentor_rookie_rookie_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effects.mentor_rookie_rookie";
		this.m.Name = "Rookie";
		this.m.Description = "This brother is learning from a mentor.";
		this.m.Icon = "ui/perks/mentor_rookie_perk.png";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsRemovedAfterBattle = false;
		this.m.IsHidden = false;
	}

	function getTooltip()
	{
		local actor = this.getContainer().getActor();
		local hasMentorRookieFlags = "MentorRookie" in getroottable() && "Flags" in ::MentorRookie;
		local battles = actor != null && hasMentorRookieFlags && actor.getFlags().has(::MentorRookie.Flags.BattlesTogether) ? actor.getFlags().get(::MentorRookie.Flags.BattlesTogether) : 0;
		local mentor = null;
		local bonusPercent = 0;
		local graduationBattles = 50;
		local graduationLevel = 10;

		if (actor != null && hasMentorRookieFlags && "Service" in ::MentorRookie)
		{
			bonusPercent = ::MentorRookie.Service.getBonusPercentForLevel(actor.getLevel());
			graduationBattles = ::MentorRookie.Service.getSetting("GraduationBattleCount");
			graduationLevel = ::MentorRookie.Service.getSetting("GraduationLevel");

			if (actor.getFlags().has(::MentorRookie.Flags.PartnerID))
			{
				mentor = ::MentorRookie.Helpers.getActorByID(actor.getFlags().get(::MentorRookie.Flags.PartnerID));
			}
		}

		local ret = this.skill.getTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Mentor: [color=" + this.Const.UI.Color.PositiveValue + "]" + (mentor != null ? mentor.getName() : "Unknown") + "[/color]"
		});
		ret.push({
			id = 11,
			type = "text",
			icon = "ui/icons/xp_received.png",
			text = "Current mentor XP bonus: [color=" + this.Const.UI.Color.PositiveValue + "]+" + bonusPercent + "%[/color]"
		});
		ret.push({
			id = 12,
			type = "text",
			icon = "ui/icons/xp_received.png",
			text = "Battles fought with mentor: [color=" + this.Const.UI.Color.PositiveValue + "]" + battles + "[/color]"
		});
		ret.push({
			id = 13,
			type = "text",
			icon = "ui/icons/asset_brothers.png",
			text = "Graduation check: [color=" + this.Const.UI.Color.PositiveValue + "]" + graduationBattles + "[/color] battles and level [color=" + this.Const.UI.Color.PositiveValue + "]" + graduationLevel + "[/color], or earlier if this rookie reaches the mentor's level"
		});

		if (actor != null && hasMentorRookieFlags && "Service" in ::MentorRookie && actor.getFlags().has(::MentorRookie.Flags.FocusAttributeID))
		{
			local focusID = actor.getFlags().get(::MentorRookie.Flags.FocusAttributeID);
			local def = ::MentorRookie.Service.getFocusAttributeDef(focusID);

			if (def != null)
			{
				local progress = actor.getFlags().has(::MentorRookie.Flags.FocusedTrainingBattles) ? actor.getFlags().get(::MentorRookie.Flags.FocusedTrainingBattles) : 0;
				local gain = actor.getFlags().has(::MentorRookie.Flags.FocusedTrainingGain) ? actor.getFlags().get(::MentorRookie.Flags.FocusedTrainingGain) : 0;
				local required = ::MentorRookie.Service.getSetting("MasterMentorRequiredBattles");
				local maxGain = ::MentorRookie.Service.getSetting("MasterMentorMaxGainPerAttribute");

				ret.push({
					id = 20,
					type = "text",
					icon = "ui/icons/special.png",
					text = "Focused training: [color=" + this.Const.UI.Color.PositiveValue + "]" + def.Name + "[/color]"
				});
				ret.push({
					id = 21,
					type = "text",
					icon = "ui/icons/days_wounded.png",
					text = "Training progress: [color=" + this.Const.UI.Color.PositiveValue + "]" + progress + " / " + required + "[/color] battles, gain [color=" + this.Const.UI.Color.PositiveValue + "]" + gain + " / " + maxGain + "[/color]"
				});
			}
		}

		return ret;
	}
});
