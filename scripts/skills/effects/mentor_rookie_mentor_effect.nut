this.mentor_rookie_mentor_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effects.mentor_rookie_mentor";
		this.m.Name = "Mentor";
		this.m.Description = "This brother is mentoring a rookie.";
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
		local ret = this.skill.getTooltip();
		local rookie = null;

		if (actor != null && actor.getFlags().has("MentorRookiePartnerID"))
		{
			rookie = ::MentorRookie.Helpers.getActorByID(actor.getFlags().get("MentorRookiePartnerID"));
		}

		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Rookie: [color=" + this.Const.UI.Color.PositiveValue + "]" + (rookie != null ? rookie.getName() : "Unknown") + "[/color]"
		});
		ret.push({
			id = 11,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Mentoring one rookie. Fight together to help the rookie gain bonus experience."
		});

		if (actor != null && "MentorRookie" in getroottable() && "Service" in ::MentorRookie && actor.getFlags().has("MentorRookieFocusAttributeID"))
		{
			local focusID = actor.getFlags().get("MentorRookieFocusAttributeID");
			local def = ::MentorRookie.Service.getFocusAttributeDef(focusID);

			if (def != null)
			{
				local progress = actor.getFlags().has("MentorRookieFocusedTrainingBattles") ? actor.getFlags().get("MentorRookieFocusedTrainingBattles") : 0;
				local gain = actor.getFlags().has("MentorRookieFocusedTrainingGain") ? actor.getFlags().get("MentorRookieFocusedTrainingGain") : 0;
				local required = ::MentorRookie.Service.getSetting("MasterMentorRequiredBattles");
				local maxGain = ::MentorRookie.Service.getSetting("MasterMentorMaxGainPerAttribute");

				ret.push({
					id = 20,
					type = "text",
					icon = "ui/icons/special.png",
					text = "Focused training: [color=" + this.Const.UI.Color.PositiveValue + "]" + def.Name + "[/color]"
				});
				ret.push({
					id = 22,
					type = "text",
					icon = "ui/icons/days_wounded.png",
					text = "Training progress: [color=" + this.Const.UI.Color.PositiveValue + "]" + progress + " / " + required + "[/color] battles, gain [color=" + this.Const.UI.Color.PositiveValue + "]" + gain + " / " + maxGain + "[/color]"
				});
			}
		}

		return ret;
	}
});
