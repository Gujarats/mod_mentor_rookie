if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

::MentorRookie.Service <- {
	Relationships = [],
	LastBattleParticipants = {},

	function clearBattleParticipants()
	{
		this.LastBattleParticipants = {};
	}

	function getSetting( _id )
	{
		return ::MentorRookie.Mod.ModSettings.getSetting(_id).getValue();
	}

	function getRosterRows()
	{
		local rows = [];
		if (!("World" in getroottable()) || ::World.getPlayerRoster() == null) return rows;

		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			rows.push({
				ID = bro.getID(),
				Name = bro.getName(),
				Level = bro.getLevel(),
				ImagePath = bro.getImagePath(),
				ImageOffsetX = bro.getImageOffsetX(),
				ImageOffsetY = bro.getImageOffsetY(),
				BackgroundImagePath = bro.getBackground() != null ? bro.getBackground().getIconColored() : "",
				IsMentor = ::MentorRookie.Helpers.hasSkill(bro, "effects.mentor_rookie_mentor"),
				IsRookie = ::MentorRookie.Helpers.hasSkill(bro, "effects.mentor_rookie_rookie")
			});
		}

		return rows;
	}

	function getRelationships()
	{
		this.rebuildRelationshipsFromRoster();
		local rows = [];

		foreach (rel in this.Relationships)
		{
			local mentor = ::MentorRookie.Helpers.getActorByID(rel.MentorID);
			local rookie = ::MentorRookie.Helpers.getActorByID(rel.RookieID);
			if (mentor == null || rookie == null) continue;

			rows.push({
				MentorID = rel.MentorID,
				MentorName = mentor.getName(),
				MentorLevel = mentor.getLevel(),
				RookieID = rel.RookieID,
				RookieName = rookie.getName(),
				RookieLevel = rookie.getLevel(),
				BattlesTogether = rel.BattlesTogether
			});
		}

		return rows;
	}

	function queryScreenData()
	{
		return {
			Roster = this.getRosterRows(),
			Relationships = this.getRelationships()
		};
	}

	function getRelationshipByMentorID( _mentorID )
	{
		foreach (rel in this.Relationships)
		{
			if (rel.MentorID == _mentorID) return rel;
		}
		return null;
	}

	function getRelationshipByRookieID( _rookieID )
	{
		foreach (rel in this.Relationships)
		{
			if (rel.RookieID == _rookieID) return rel;
		}
		return null;
	}

	function validatePair( _mentor, _rookie )
	{
		if (_mentor == null || _rookie == null)
		{
			return { Valid = false, Message = "Select both a mentor and a rookie." };
		}

		if (_mentor.getID() == _rookie.getID())
		{
			return { Valid = false, Message = "A brother cannot mentor himself." };
		}

		if (_mentor.getLevel() < this.getSetting("MinimumMentorLevel"))
		{
			return { Valid = false, Message = _mentor.getName() + " is not high enough level to be a mentor." };
		}

		if (_rookie.getLevel() > this.getSetting("MaximumRookieLevel"))
		{
			return { Valid = false, Message = _rookie.getName() + " is above the rookie level limit." };
		}

		if (_mentor.getLevel() <= _rookie.getLevel())
		{
			return { Valid = false, Message = "The mentor must be higher level than the rookie." };
		}

		if (this.getRelationshipByMentorID(_mentor.getID()) != null)
		{
			return { Valid = false, Message = _mentor.getName() + " is already mentoring someone." };
		}

		if (this.getRelationshipByRookieID(_rookie.getID()) != null)
		{
			return { Valid = false, Message = _rookie.getName() + " already has a mentor." };
		}

		return { Valid = true, Message = "Pair can be created." };
	}

	function createRelationship( _mentorID, _rookieID )
	{
		this.rebuildRelationshipsFromRoster();
		local mentor = ::MentorRookie.Helpers.getActorByID(_mentorID);
		local rookie = ::MentorRookie.Helpers.getActorByID(_rookieID);
		local validation = this.validatePair(mentor, rookie);

		if (!validation.Valid)
		{
			::MentorRookie.Helpers.debugLog("create relationship rejected: " + validation.Message);
			return { Success = false, Message = validation.Message, Data = this.queryScreenData() };
		}

		this.Relationships.push({
			MentorID = mentor.getID(),
			RookieID = rookie.getID(),
			BattlesTogether = 0
		});
		this.writeRelationshipFlags(mentor, rookie, 0);
		this.ensureRelationshipEffects(mentor, rookie);

		::MentorRookie.Helpers.debugLog("created relationship mentor=" + mentor.getName() + " rookie=" + rookie.getName());
		return {
			Success = true,
			Message = mentor.getName() + " is now mentoring " + rookie.getName() + ".",
			Data = this.queryScreenData()
		};
	}

	function removeRelationshipByRookieID( _rookieID )
	{
		this.rebuildRelationshipsFromRoster();
		local rel = this.getRelationshipByRookieID(_rookieID);
		if (rel == null)
		{
			return { Success = false, Message = "No mentorship relationship was found.", Data = this.queryScreenData() };
		}

		local mentor = ::MentorRookie.Helpers.getActorByID(rel.MentorID);
		local rookie = ::MentorRookie.Helpers.getActorByID(rel.RookieID);
		this.clearRelationship(mentor, rookie);
		::MentorRookie.Helpers.debugLog("removed relationship rookieID=" + _rookieID);

		return { Success = true, Message = "Mentorship relationship removed.", Data = this.queryScreenData() };
	}

	function writeRelationshipFlags( _mentor, _rookie, _battles )
	{
		_mentor.getFlags().set("MentorRookieRole", "mentor");
		_mentor.getFlags().set("MentorRookiePartnerID", _rookie.getID());
		_mentor.getFlags().set("MentorRookieBattlesTogether", _battles);
		_rookie.getFlags().set("MentorRookieRole", "rookie");
		_rookie.getFlags().set("MentorRookiePartnerID", _mentor.getID());
		_rookie.getFlags().set("MentorRookieBattlesTogether", _battles);
	}

	function clearRelationship( _mentor, _rookie )
	{
		if (_mentor != null)
		{
			_mentor.getFlags().remove("MentorRookieRole");
			_mentor.getFlags().remove("MentorRookiePartnerID");
			_mentor.getFlags().remove("MentorRookieBattlesTogether");
			_mentor.getSkills().removeByID("effects.mentor_rookie_mentor");
		}

		if (_rookie != null)
		{
			_rookie.getFlags().remove("MentorRookieRole");
			_rookie.getFlags().remove("MentorRookiePartnerID");
			_rookie.getFlags().remove("MentorRookieBattlesTogether");
			_rookie.getSkills().removeByID("effects.mentor_rookie_rookie");
		}

		this.rebuildRelationshipsFromRoster();
	}

	function ensureRelationshipEffects( _mentor, _rookie )
	{
		if (!::MentorRookie.Helpers.hasSkill(_mentor, "effects.mentor_rookie_mentor"))
		{
			_mentor.getSkills().add(::new("scripts/skills/effects/mentor_rookie_mentor_effect"));
		}

		if (!::MentorRookie.Helpers.hasSkill(_rookie, "effects.mentor_rookie_rookie"))
		{
			_rookie.getSkills().add(::new("scripts/skills/effects/mentor_rookie_rookie_effect"));
		}
	}

	function rebuildRelationshipsFromRoster()
	{
		this.Relationships = [];
		if (!("World" in getroottable()) || ::World.getPlayerRoster() == null) return;

		local seen = {};
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (!bro.getFlags().has("MentorRookieRole")) continue;
			if (bro.getFlags().get("MentorRookieRole") != "mentor") continue;
			if (!bro.getFlags().has("MentorRookiePartnerID")) continue;

			local mentor = bro;
			local rookie = ::MentorRookie.Helpers.getActorByID(bro.getFlags().get("MentorRookiePartnerID"));
			if (rookie == null) continue;
			if (!rookie.getFlags().has("MentorRookieRole") || rookie.getFlags().get("MentorRookieRole") != "rookie") continue;

			local battles = bro.getFlags().has("MentorRookieBattlesTogether") ? bro.getFlags().get("MentorRookieBattlesTogether") : 0;
			local key = "" + mentor.getID() + ":" + rookie.getID();
			if (key in seen) continue;
			seen[key] <- true;

			this.Relationships.push({ MentorID = mentor.getID(), RookieID = rookie.getID(), BattlesTogether = battles });
			this.ensureRelationshipEffects(mentor, rookie);
		}
	}

	function captureCombatParticipants()
	{
		this.clearBattleParticipants();
		if (!("Tactical" in getroottable()) || !("Entities" in ::Tactical)) return;

		local brothers = ::Tactical.Entities.getInstancesOfFaction(::Const.Faction.Player);
		foreach (bro in brothers)
		{
			this.LastBattleParticipants["" + bro.getID()] <- {
				Alive = bro.isAlive(),
				XPGained = bro.m.CombatStats.XPGained
			};
		}

		::MentorRookie.Helpers.debugLog("captured battle participants=" + brothers.len());
	}

	function wasBattleParticipant( _actorID )
	{
		local key = "" + _actorID;
		return key in this.LastBattleParticipants && this.LastBattleParticipants[key].Alive;
	}

	function getCapturedBattleXP( _actorID )
	{
		local key = "" + _actorID;
		if (!(key in this.LastBattleParticipants)) return 0;
		return this.LastBattleParticipants[key].XPGained;
	}

	function getBonusPercentForLevel( _level )
	{
		if (_level >= 1 && _level <= 3) return this.getSetting("Level1To3BonusPercent");
		if (_level >= 4 && _level <= 6) return this.getSetting("Level4To6BonusPercent");
		if (_level >= 7 && _level <= 10) return this.getSetting("Level7To10BonusPercent");
		return 0;
	}

	function awardMentorBonusXP( _rookie, _baseXP )
	{
		local percent = this.getBonusPercentForLevel(_rookie.getLevel());
		local desiredBonus = ::Math.floor(_baseXP * percent / 100.0);
		if (desiredBonus <= 0)
		{
			::MentorRookie.Helpers.debugLog("mentor XP skipped rookie=" + _rookie.getName() + " baseXP=" + _baseXP + " percent=" + percent + " reason=no_desired_bonus");
			return 0;
		}

		local mult = _rookie.m.CurrentProperties.XPGainMult;
		if (mult <= 0.0) mult = 1.0;

		local inputBonus = ::Math.floor(desiredBonus / mult);
		if (inputBonus <= 0) inputBonus = 1;

		local before = _rookie.m.XP;
		_rookie.addXP(inputBonus, false);
		local awarded = _rookie.m.XP - before;

		::MentorRookie.Helpers.debugLog("awarded mentor XP rookie=" + _rookie.getName() + " baseXP=" + _baseXP + " percent=" + percent + " desired=" + desiredBonus + " input=" + inputBonus + " actual=" + awarded);
		return awarded;
	}

	function handleAfterCombat()
	{
		this.rebuildRelationshipsFromRoster();
		local relationships = clone this.Relationships;
		::MentorRookie.Helpers.debugLog("after combat processing relationships=" + relationships.len() + " participants=" + this.LastBattleParticipants.len());

		foreach (rel in relationships)
		{
			local mentor = ::MentorRookie.Helpers.getActorByID(rel.MentorID);
			local rookie = ::MentorRookie.Helpers.getActorByID(rel.RookieID);
			if (mentor == null || rookie == null)
			{
				::MentorRookie.Helpers.debugLog("battle ignored mentorID=" + rel.MentorID + " rookieID=" + rel.RookieID + " reason=missing_actor mentorFound=" + (mentor != null ? "true" : "false") + " rookieFound=" + (rookie != null ? "true" : "false"));
				continue;
			}

			local mentorParticipated = this.wasBattleParticipant(mentor.getID());
			local rookieParticipated = this.wasBattleParticipant(rookie.getID());
			local mentorKey = "" + mentor.getID();
			local rookieKey = "" + rookie.getID();
			local mentorCaptured = mentorKey in this.LastBattleParticipants;
			local rookieCaptured = rookieKey in this.LastBattleParticipants;
			local mentorAlive = mentorCaptured ? this.LastBattleParticipants[mentorKey].Alive : false;
			local rookieAlive = rookieCaptured ? this.LastBattleParticipants[rookieKey].Alive : false;
			local previousBattles = rel.BattlesTogether;

			::MentorRookie.Helpers.debugLog("battle relationship checked mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " previousBattles=" + previousBattles + " mentorCaptured=" + (mentorCaptured ? "true" : "false") + " mentorAlive=" + (mentorAlive ? "true" : "false") + " rookieCaptured=" + (rookieCaptured ? "true" : "false") + " rookieAlive=" + (rookieAlive ? "true" : "false"));

			if (!mentorParticipated || !rookieParticipated)
			{
				::MentorRookie.Helpers.debugLog("battle ignored mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " reason=missing_or_dead_participant mentorParticipated=" + (mentorParticipated ? "true" : "false") + " rookieParticipated=" + (rookieParticipated ? "true" : "false"));
				continue;
			}

			rel.BattlesTogether++;
			this.writeRelationshipFlags(mentor, rookie, rel.BattlesTogether);
			local baseXP = this.getCapturedBattleXP(rookie.getID());
			::MentorRookie.Helpers.debugLog("valid battle counted mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " battles=" + rel.BattlesTogether + " previousBattles=" + previousBattles + " rookieBaseXP=" + baseXP);
			local bonusXP = this.awardMentorBonusXP(rookie, baseXP);
			::MentorRookie.Helpers.debugLog("valid battle result mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " battles=" + rel.BattlesTogether + " bonusXP=" + bonusXP);
			this.logMilestonesAndGraduate(mentor, rookie, rel.BattlesTogether);
		}

		this.clearBattleParticipants();
	}

	function logMilestonesAndGraduate( _mentor, _rookie, _battles )
	{
		if (_battles == this.getSetting("MilestoneOne") || _battles == this.getSetting("MilestoneTwo") || _battles == this.getSetting("MilestoneThree") || _battles == this.getSetting("GraduationBattleCount"))
		{
			::MentorRookie.Helpers.debugLog("milestone reached mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " battles=" + _battles);
		}

		local shouldGraduate = false;
		local reason = "";

		if (_rookie.getLevel() >= _mentor.getLevel())
		{
			shouldGraduate = true;
			reason = "rookie_reached_mentor_level";
		}
		else if (_battles >= this.getSetting("GraduationBattleCount") && _rookie.getLevel() >= this.getSetting("GraduationLevel"))
		{
			shouldGraduate = true;
			reason = "battle_and_level_requirement_met";
		}

		::MentorRookie.Helpers.debugLog("graduation checked mentor=" + _mentor.getName() + " mentorLevel=" + _mentor.getLevel() + " rookie=" + _rookie.getName() + " rookieLevel=" + _rookie.getLevel() + " battles=" + _battles + " requiredBattles=" + this.getSetting("GraduationBattleCount") + " requiredLevel=" + this.getSetting("GraduationLevel") + " shouldGraduate=" + (shouldGraduate ? "true" : "false"));

		if (shouldGraduate)
		{
			::MentorRookie.Helpers.debugLog("graduated mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " reason=" + reason);
			this.clearRelationship(_mentor, _rookie);
		}
	}
};
