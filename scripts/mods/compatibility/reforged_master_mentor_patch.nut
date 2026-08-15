if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

if (!("Compatibility" in ::MentorRookie))
{
	::MentorRookie.Compatibility <- {};
}

::MentorRookie.Compatibility.Reforged <- {
	ExistingPlayersMigrated = false,

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

		local perk = ::MentorRookie.getMasterMentorPerkDefinition();
		delete perk.Row;
		::DynamicPerks.Perks.addPerks([perk]);

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

	function addMasterMentorToExistingPlayerTrees()
	{
		if (!this.hasRuntime()
			|| !("World" in getroottable())
			|| ::World.getPlayerRoster() == null)
		{
			::MentorRookie.Helpers.debugLog("[Reforged] existing-player Master Mentor migration skipped: player roster is unavailable");
			return false;
		}

		local added = 0;
		local alreadyPresent = 0;
		local unavailable = 0;
		foreach (actor in ::World.getPlayerRoster().getAll())
		{
			if (actor == null)
			{
				unavailable++;
				continue;
			}

			local perkTree = actor.getPerkTree();
			if (perkTree == null)
			{
				unavailable++;
				::MentorRookie.Helpers.debugLog("[Reforged] existing-player Master Mentor migration skipped for " + actor.getName() + ": perk tree is unavailable");
				continue;
			}

			if ("perk.master_mentor" in perkTree.getPerks())
			{
				alreadyPresent++;
				continue;
			}

			perkTree.addPerk("perk.master_mentor", this.getConfiguredRow());
			added++;
			::MentorRookie.Helpers.debugLog("[Reforged] Master Mentor added to existing player perk tree for " + actor.getName() + " row=" + this.getConfiguredRow());
		}

		::MentorRookie.Helpers.debugLog("[Reforged] existing-player Master Mentor migration complete added=" + added + " already_present=" + alreadyPresent + " unavailable=" + unavailable);
		return true;
	}

	function tryMigrateExistingPlayerTrees()
	{
		if (this.ExistingPlayersMigrated) return true;
		if (!this.hasRuntime()
			|| !("World" in getroottable())
			|| ::World.getPlayerRoster() == null)
		{
			return false;
		}

		if (::World.getPlayerRoster().getAll().len() == 0)
		{
			return false;
		}

		this.addMasterMentorToExistingPlayerTrees();
		this.ExistingPlayersMigrated = true;
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
