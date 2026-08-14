if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

if (!("Compatibility" in ::MentorRookie))
{
	::MentorRookie.Compatibility <- {};
}

::MentorRookie.Compatibility.Reforged <- {
	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_reforged")
			&& ("DynamicPerks" in getroottable())
			&& ("Perks" in ::DynamicPerks)
			&& ("PerkGroups" in ::DynamicPerks)
			&& ("addPerks" in ::DynamicPerks.Perks)
			&& ("findById" in ::DynamicPerks.PerkGroups);
	}

	function registerPerkDefinition()
	{
		if (::Const.Perks.findById("perk.master_mentor") != null)
		{
			::MentorRookie.Helpers.debugLog("[Reforged] Master Mentor perk definition already registered");
			return true;
		}

		::DynamicPerks.Perks.addPerks([
			{
				ID = "perk.master_mentor",
				Script = "scripts/skills/perks/master_mentor_perk",
				Name = "Master Mentor",
				Tooltip = "This brother is especially effective at guiding rookies.",
				Icon = "ui/perks/mentor_rookie_perk.png",
				IconDisabled = "ui/perks/mentor_rookie_perk_sw.png"
			}
		]);

		::MentorRookie.Helpers.debugLog("[Reforged] Master Mentor perk definition registered");
		return true;
	}

	function getConfiguredRow()
	{
		local row = ::MentorRookie.Mod.ModSettings.getSetting("MasterMentorPerkRow").getValue();
		return ::Math.max(1, ::Math.min(row, 7));
	}

	function addMasterMentorToUniversalGroup()
	{
		local group = ::DynamicPerks.PerkGroups.findById("pg.rf_always_1");
		if (group == null)
		{
			::MentorRookie.Helpers.debugLog("[Reforged] Master Mentor insertion skipped: universal perk group is unavailable");
			return false;
		}

		local tree = group.getTree();
		foreach (i, perks in tree)
		{
			foreach (perkID in perks)
			{
				if (perkID == "perk.master_mentor")
				{
					::MentorRookie.Helpers.debugLog("[Reforged] Master Mentor already present in universal perk group row=" + (i + 1));
					return true;
				}
			}
		}

		local row = this.getConfiguredRow();
		local index = row - 1;
		while (tree.len() <= index)
		{
			tree.push([]);
		}

		tree[index].push("perk.master_mentor");
		::MentorRookie.Helpers.debugLog("[Reforged] Master Mentor inserted into universal perk group row=" + row);
		return true;
	}

	function register()
	{
		if (!this.hasRuntime())
		{
			::MentorRookie.Helpers.debugLog("[Reforged] Master Mentor registration skipped: required Dynamic Perks APIs are unavailable");
			return false;
		}

		if (!this.registerPerkDefinition()) return false;
		return this.addMasterMentorToUniversalGroup();
	}
};
