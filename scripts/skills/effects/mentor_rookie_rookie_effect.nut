this.mentor_rookie_rookie_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effects.mentor_rookie_rookie";
		this.m.Name = "Rookie";
		this.m.Description = "This brother is learning from a mentor.";
		this.m.Icon = "ui/perks/perk_25.png";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsRemovedAfterBattle = false;
		this.m.IsHidden = false;
	}

	function getTooltip()
	{
		local actor = this.getContainer().getActor();
		local battles = actor != null && actor.getFlags().has("MentorRookieBattlesTogether") ? actor.getFlags().get("MentorRookieBattlesTogether") : 0;
		local ret = this.skill.getTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/xp_received.png",
			text = "Battles fought with mentor: [color=" + this.Const.UI.Color.PositiveValue + "]" + battles + "[/color]"
		});
		return ret;
	}
});
