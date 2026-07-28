this.master_mentor_perk <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "perk.master_mentor";
		this.m.Name = "Master Mentor";
		this.m.Description = "This brother has a reputation for teaching rookies. Version 0.0.1 keeps this as a perk shell only.";
		this.m.Icon = "ui/perks/perk_25.png";
		this.m.IconDisabled = "ui/perks/perk_25_sw.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
	}
});
