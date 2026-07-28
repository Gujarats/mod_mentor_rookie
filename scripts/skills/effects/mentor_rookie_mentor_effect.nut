this.mentor_rookie_mentor_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effects.mentor_rookie_mentor";
		this.m.Name = "Mentor";
		this.m.Description = "This brother is mentoring a rookie.";
		this.m.Icon = "ui/perks/perk_25.png";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsRemovedAfterBattle = false;
		this.m.IsHidden = false;
	}

	function getTooltip()
	{
		local ret = this.skill.getTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Mentoring one rookie. Fight together to help the rookie gain bonus experience."
		});
		return ret;
	}
});
