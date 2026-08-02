if (!("Compatibility" in ::MentorRookie))
{
	::MentorRookie.Compatibility <- {};
}

if (!("Legends" in ::MentorRookie.Compatibility))
{
	::MentorRookie.Compatibility.Legends <- null;
}

::MentorRookie.Compatibility.Legends = {
	MasterMentorPerkDef = null,

	function getConfiguredRow()
	{
		local row = ::MentorRookie.Mod.ModSettings.getSetting("MasterMentorPerkRow").getValue() - 1;
		return row < 0 ? 0 : row;
	}

	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_legends")
			&& ("Legends" in getroottable())
			&& ("Perk" in ::Legends)
			&& ("PerkDefObjects" in ::Const.Perks)
			&& ("addPerkDefObjects" in ::Const.Perks);
	}

	function setMasterMentorPerkDef( _perkDef )
	{
		if (!("MasterMentor" in ::Legends.Perk))
		{
			::Legends.Perk.MasterMentor <- _perkDef;
		}
		else
		{
			::Legends.Perk.MasterMentor = _perkDef;
		}

		if (!("MasterMentor" in ::Const.Perks.PerkDefs))
		{
			::Const.Perks.PerkDefs.MasterMentor <- _perkDef;
		}
		else
		{
			::Const.Perks.PerkDefs.MasterMentor = _perkDef;
		}
	}

	function registerPerkDef()
	{
		if (!this.hasRuntime())
		{
			this.MasterMentorPerkDef = null;
			::MentorRookie.Helpers.debugLog("[Legends] Master Mentor registration skipped: required Legends perk APIs are unavailable");
			return null;
		}

		foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
		{
			if (perkDef != null && "ID" in perkDef && perkDef.ID == "perk.master_mentor")
			{
				this.setMasterMentorPerkDef(i);
				this.MasterMentorPerkDef = i;
				::MentorRookie.Helpers.debugLog("[Legends] Master Mentor perk definition found index=" + i);
				return i;
			}
		}

		::Const.Perks.addPerkDefObjects([
			{
				ID = "perk.master_mentor",
				Script = "scripts/skills/perks/master_mentor_perk",
				Name = "Master Mentor",
				Tooltip = "This brother is especially effective at guiding rookies.",
				Icon = "ui/perks/mentor_rookie_perk.png",
				IconDisabled = "ui/perks/mentor_rookie_perk_sw.png",
				Const = "MasterMentor"
			}
		]);

		this.MasterMentorPerkDef = ::Legends.Perk.MasterMentor;
		::MentorRookie.Helpers.debugLog("[Legends] Master Mentor perk definition registered index=" + this.MasterMentorPerkDef);
		return this.MasterMentorPerkDef;
	}

	function getMasterMentorPerkDefNumber()
	{
		if (this.MasterMentorPerkDef != null)
		{
			return this.MasterMentorPerkDef;
		}

		if (!this.hasRuntime() || ::Const.Perks.PerkDefObjects == null)
		{
			return null;
		}

		foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
		{
			if (perkDef != null && "ID" in perkDef && perkDef.ID == "perk.master_mentor")
			{
				this.setMasterMentorPerkDef(i);
				this.MasterMentorPerkDef = i;
				return i;
			}
		}

		return null;
	}

	function addMasterMentorToBackground( _background )
	{
		if (_background == null || _background.m.PerkTreeMap == null)
		{
			::MentorRookie.Helpers.debugLog("[Legends] Master Mentor insertion skipped: perk tree is unavailable");
			return false;
		}

		local perkDefIndex = this.getMasterMentorPerkDefNumber();
		if (perkDefIndex == null)
		{
			::MentorRookie.Helpers.debugLog("[Legends] Master Mentor insertion skipped: perk definition is unavailable");
			return false;
		}

		local backgroundID = _background.getID();
		if (_background.getPerk("perk.master_mentor") != null)
		{
			::MentorRookie.Helpers.debugLog("[Legends] Master Mentor insertion skipped background=" + backgroundID + " reason=already_present");
			return false;
		}

		local preferredRow = this.getConfiguredRow();
		if (!_background.addPerk(perkDefIndex, preferredRow, true))
		{
			::MentorRookie.Helpers.debugLog("[Legends] Master Mentor insertion failed background=" + backgroundID + " preferredRow=" + preferredRow);
			return false;
		}

		local insertedPerk = _background.getPerk("perk.master_mentor");
		local actualRow = insertedPerk != null ? insertedPerk.Row : preferredRow;
		::MentorRookie.Helpers.debugLog("[Legends] Master Mentor inserted background=" + backgroundID + " preferredRow=" + preferredRow + " actualRow=" + actualRow);
		return true;
	}

	function registerHooks( _mod )
	{
		this.registerPerkDef();

		if (!::Hooks.hasMod("mod_legends"))
		{
			return;
		}

		local module = ::MentorRookie.Compatibility.Legends;
		_mod.hook("scripts/skills/backgrounds/character_background", function(q)
		{
			q.buildPerkTree = @(__original) function()
			{
				local attributes = __original();
				module.addMasterMentorToBackground(this);
				return attributes;
			}
		});
	}
};
