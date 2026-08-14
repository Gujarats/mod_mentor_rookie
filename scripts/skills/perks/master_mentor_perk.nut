this.master_mentor_perk <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "perk.master_mentor";
		this.m.Name = "Master Mentor";
		this.m.Description = "This perk allows you to mentor a rookie player, granting them additional experience and attribute points based on your talent stars";
		this.m.Icon = "ui/perks/mentor_rookie_perk.png";
		this.m.IconDisabled = "ui/perks/mentor_rookie_perk_sw.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
	}
});
