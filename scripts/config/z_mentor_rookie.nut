if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

::MentorRookie.Flags <- {
	Role = "MentorRookieRole",
	PartnerID = "MentorRookiePartnerID",
	BattlesTogether = "MentorRookieBattlesTogether",
	FocusAttributeID = "MentorRookieFocusAttributeID",
	FocusedTrainingBattles = "MentorRookieFocusedTrainingBattles",
	FocusedTrainingGain = "MentorRookieFocusedTrainingGain",
	HistoryPrefix = "MentorRookieHistory_",
	ActiveRelationship = []
};

::MentorRookie.Flags.ActiveRelationship = [
	::MentorRookie.Flags.Role,
	::MentorRookie.Flags.PartnerID,
	::MentorRookie.Flags.BattlesTogether,
	::MentorRookie.Flags.FocusAttributeID,
	::MentorRookie.Flags.FocusedTrainingBattles,
	::MentorRookie.Flags.FocusedTrainingGain
];

::Const.Perks.MentorRookie <- [];

local function addPerk( perk )
{
	perk.Unlocks <- perk.Row;
	perk.verifyPrerequisites <- function( _player, _tooltip )
	{
		return true;
	}

	::Const.Perks.MentorRookie.push(perk);
	::Const.Perks.LookupMap[perk.ID] <- perk;
}

addPerk({
	ID = "perk.master_mentor",
	Script = "scripts/skills/perks/master_mentor_perk",
	Name = "Master Mentor",
	Tooltip = "This brother is especially effective at guiding rookies. In version 0.0.1 this perk is a compatibility shell and does not change hiring balance.",
	Icon = "ui/perks/mentor_rookie_perk.png",
	IconDisabled = "ui/perks/mentor_rookie_perk_sw.png",
	Row = 6
});

::MentorRookie.configureDebugLogging <- function()
{
	if (::MentorRookie.Mod.ModSettings.getSetting("DebugLogging").getValue())
	{
		::MentorRookie.Mod.Debug.enable();
	}
	else
	{
		::MentorRookie.Mod.Debug.disable();
	}
}

::MentorRookie.Helpers <- {
	function debugLog( _message )
	{
		if ("Mod" in ::MentorRookie && ::MentorRookie.Mod.ModSettings.getSetting("DebugLogging").getValue())
		{
			::MentorRookie.Mod.Debug.printLog("[MentorRookie] " + _message);
		}
	}

	function getActorByID( _actorID )
	{
		if (!("World" in getroottable()) || ::World.getPlayerRoster() == null) return null;

		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.getID() == _actorID) return bro;
		}

		return null;
	}

	function hasSkill( _actor, _skillID )
	{
		return _actor != null && _actor.getSkills() != null && _actor.getSkills().hasSkill(_skillID);
	}

	function clonePerkTree( _perkTree )
	{
		local perks = [];
		foreach (row in _perkTree)
		{
			perks.push(clone row);
		}
		return perks;
	}

	function hasPerkInTree( _perkTree, _perkID )
	{
		foreach (row in _perkTree)
		{
			foreach (perk in row)
			{
				if ("ID" in perk && perk.ID == _perkID) return true;
			}
		}
		return false;
	}

	function appendMentorRookiePerks( _perkTree, _row )
	{
		local perks = this.clonePerkTree(_perkTree);
		local row = ::Math.max(1, ::Math.min(_row, 7)) - 1;

		while (perks.len() <= row)
		{
			perks.push([]);
		}

		foreach (perk in ::Const.Perks.MentorRookie)
		{
			if (this.hasPerkInTree(perks, perk.ID)) continue;

			local p = clone perk;
			if ("verifyPrerequisites" in p) delete p.verifyPrerequisites;
			perks[row].push(p);
		}

		return perks;
	}
};
