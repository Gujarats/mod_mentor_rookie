if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

::MentorRookie.Service <- {
	Relationships = [],
	LastBattleParticipants = {},
	PendingTrainingNotifications = [],
	ActiveTrainingNotification = null,
	FocusAttributes = [
		{ ID = "Hitpoints", Name = "Hitpoints", AttributeKey = "Hitpoints" },
		{ ID = "Fatigue", Name = "Fatigue", AttributeKey = "Stamina" },
		{ ID = "Resolve", Name = "Resolve", AttributeKey = "Bravery" },
		{ ID = "Initiative", Name = "Initiative", AttributeKey = "Initiative" },
		{ ID = "MeleeSkill", Name = "Melee Skill", AttributeKey = "MeleeSkill" },
		{ ID = "RangedSkill", Name = "Ranged Skill", AttributeKey = "RangedSkill" },
		{ ID = "MeleeDefense", Name = "Melee Defense", AttributeKey = "MeleeDefense" },
		{ ID = "RangedDefense", Name = "Ranged Defense", AttributeKey = "RangedDefense" }
	],

	function clearBattleParticipants()
	{
		this.LastBattleParticipants = {};
	}

	function getSetting( _id )
	{
		return ::MentorRookie.Mod.ModSettings.getSetting(_id).getValue();
	}

	function getFocusAttributeDef( _id )
	{
		foreach (def in this.FocusAttributes)
		{
			if (def.ID == _id) return def;
		}

		return null;
	}

	function getFocusAttributeConst( _focusID )
	{
		switch (_focusID)
		{
			case "Hitpoints": return ::Const.Attributes.Hitpoints;
			case "Fatigue": return ::Const.Attributes.Fatigue;
			case "Resolve": return ::Const.Attributes.Bravery;
			case "Initiative": return ::Const.Attributes.Initiative;
			case "MeleeSkill": return ::Const.Attributes.MeleeSkill;
			case "RangedSkill": return ::Const.Attributes.RangedSkill;
			case "MeleeDefense": return ::Const.Attributes.MeleeDefense;
			case "RangedDefense": return ::Const.Attributes.RangedDefense;
		}

		return null;
	}

	function hasMasterMentor( _actor )
	{
		return _actor != null && ::MentorRookie.Helpers.hasSkill(_actor, "perk.master_mentor");
	}

	function getTalentStars( _actor, _focusID )
	{
		if (_actor == null) return 0;

		local attr = this.getFocusAttributeConst(_focusID);
		if (attr == null) return 0;

		local talents = _actor.getTalents();
		if (talents == null || talents.len() <= attr) return 0;

		return talents[attr];
	}

	function getFocusAttributeOptions( _mentorID, _rookieID )
	{
		local mentor = ::MentorRookie.Helpers.getActorByID(_mentorID);
		local rookie = ::MentorRookie.Helpers.getActorByID(_rookieID);
		local ret = [];

		foreach (def in this.FocusAttributes)
		{
			local mentorStars = this.getTalentStars(mentor, def.ID);
			local rookieStars = this.getTalentStars(rookie, def.ID);
			local reason = "";

			if (!this.getSetting("MasterMentorFocusedTrainingEnabled"))
			{
				reason = "Focused training is disabled.";
			}
			else if (mentor == null || rookie == null)
			{
				reason = "Select a mentor and rookie first.";
			}
			else if (!this.hasMasterMentor(mentor))
			{
				reason = mentor.getName() + " does not have Master Mentor.";
			}
			else if (mentorStars <= 0)
			{
				reason = mentor.getName() + " has no talent star in " + def.Name + ".";
			}
			else if (rookieStars <= 0)
			{
				reason = rookie.getName() + " has no talent star in " + def.Name + ".";
			}

			ret.push({
				ID = def.ID,
				Name = def.Name,
				MentorStars = mentorStars,
				RookieStars = rookieStars,
				IsValid = reason == "",
				Reason = reason
			});
		}

		return ret;
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
				IsRookie = ::MentorRookie.Helpers.hasSkill(bro, "effects.mentor_rookie_rookie"),
				HasMasterMentor = this.hasMasterMentor(bro)
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

			local focusDef = rel.FocusAttributeID != null ? this.getFocusAttributeDef(rel.FocusAttributeID) : null;
			rows.push({
				MentorID = rel.MentorID,
				MentorName = mentor.getName(),
				MentorLevel = mentor.getLevel(),
				RookieID = rel.RookieID,
				RookieName = rookie.getName(),
				RookieLevel = rookie.getLevel(),
				BattlesTogether = rel.BattlesTogether,
				FocusAttributeID = rel.FocusAttributeID,
				FocusAttributeName = focusDef != null ? focusDef.Name : "No focus",
				FocusLocked = focusDef != null,
				FocusedTrainingBattles = rel.FocusedTrainingBattles,
				FocusedTrainingRequiredBattles = this.getSetting("MasterMentorRequiredBattles"),
				FocusedTrainingGain = rel.FocusedTrainingGain,
				FocusedTrainingMaxGain = this.getSetting("MasterMentorMaxGainPerAttribute")
			});
		}

		return rows;
	}

	function queryScreenData()
	{
		return {
			Roster = this.getRosterRows(),
			Relationships = this.getRelationships(),
			SelectedPairFocusOptions = []
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

	function validateFocusAttribute( _mentorID, _rookieID, _focusAttributeID )
	{
		if (_focusAttributeID == null) return { Valid = true, Message = "" };

		foreach (option in this.getFocusAttributeOptions(_mentorID, _rookieID))
		{
			if (option.ID == _focusAttributeID)
			{
				return { Valid = option.IsValid, Message = option.Reason };
			}
		}

		return { Valid = false, Message = "Selected focus attribute is invalid." };
	}

	function getPairHistoryKey( _mentorID, _rookieID )
	{
		return "" + _mentorID + ":" + _rookieID;
	}

	function getPairHistoryPrefix( _mentorID, _rookieID )
	{
		return "MentorRookieHistory_" + _mentorID + "_" + _rookieID + "_";
	}

	function readPairHistory( _mentor, _rookie )
	{
		local empty = {
			BattlesTogether = 0,
			FocusAttributeID = null,
			FocusedTrainingBattles = 0,
			FocusedTrainingGain = 0
		};

		if (_mentor == null || _rookie == null) return empty;

		local prefix = this.getPairHistoryPrefix(_mentor.getID(), _rookie.getID());
		local flags = _rookie.getFlags();

		if (!flags.has(prefix + "BattlesTogether"))
		{
			return empty;
		}

		return {
			BattlesTogether = flags.get(prefix + "BattlesTogether"),
			FocusAttributeID = flags.has(prefix + "FocusAttributeID") ? flags.get(prefix + "FocusAttributeID") : null,
			FocusedTrainingBattles = flags.has(prefix + "FocusedTrainingBattles") ? flags.get(prefix + "FocusedTrainingBattles") : 0,
			FocusedTrainingGain = flags.has(prefix + "FocusedTrainingGain") ? flags.get(prefix + "FocusedTrainingGain") : 0
		};
	}

	function writePairHistory( _mentor, _rookie, _battles, _focusAttributeID = null, _focusedTrainingBattles = 0, _focusedTrainingGain = 0 )
	{
		if (_mentor == null || _rookie == null) return;

		local prefix = this.getPairHistoryPrefix(_mentor.getID(), _rookie.getID());
		local mentorFlags = _mentor.getFlags();
		local rookieFlags = _rookie.getFlags();

		mentorFlags.set(prefix + "BattlesTogether", _battles);
		mentorFlags.set(prefix + "FocusedTrainingBattles", _focusedTrainingBattles);
		mentorFlags.set(prefix + "FocusedTrainingGain", _focusedTrainingGain);

		rookieFlags.set(prefix + "BattlesTogether", _battles);
		rookieFlags.set(prefix + "FocusedTrainingBattles", _focusedTrainingBattles);
		rookieFlags.set(prefix + "FocusedTrainingGain", _focusedTrainingGain);

		if (_focusAttributeID != null)
		{
			mentorFlags.set(prefix + "FocusAttributeID", _focusAttributeID);
			rookieFlags.set(prefix + "FocusAttributeID", _focusAttributeID);
		}
		else
		{
			mentorFlags.remove(prefix + "FocusAttributeID");
			rookieFlags.remove(prefix + "FocusAttributeID");
		}

		::MentorRookie.Helpers.debugLog("pair history saved key=" + this.getPairHistoryKey(_mentor.getID(), _rookie.getID()) + " battles=" + _battles + " focus=" + (_focusAttributeID == null ? "<none>" : _focusAttributeID) + " trainingBattles=" + _focusedTrainingBattles + " trainingGain=" + _focusedTrainingGain);
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

		local history = this.readPairHistory(mentor, rookie);

		this.Relationships.push({
			MentorID = mentor.getID(),
			RookieID = rookie.getID(),
			BattlesTogether = history.BattlesTogether,
			FocusAttributeID = history.FocusAttributeID,
			FocusedTrainingBattles = history.FocusedTrainingBattles,
			FocusedTrainingGain = history.FocusedTrainingGain
		});
		this.writeRelationshipFlags(mentor, rookie, history.BattlesTogether, history.FocusAttributeID, history.FocusedTrainingBattles, history.FocusedTrainingGain);
		this.writePairHistory(mentor, rookie, history.BattlesTogether, history.FocusAttributeID, history.FocusedTrainingBattles, history.FocusedTrainingGain);
		this.ensureRelationshipEffects(mentor, rookie);

		::MentorRookie.Helpers.debugLog("relationship history restored mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " battles=" + history.BattlesTogether + " focus=" + (history.FocusAttributeID == null ? "<none>" : history.FocusAttributeID) + " trainingBattles=" + history.FocusedTrainingBattles + " trainingGain=" + history.FocusedTrainingGain);
		::MentorRookie.Helpers.debugLog("created relationship mentor=" + mentor.getName() + " rookie=" + rookie.getName());
		return {
			Success = true,
			Message = mentor.getName() + " is now mentoring " + rookie.getName() + ".",
			Data = this.queryScreenData()
		};
	}

	function setRelationshipFocusAttribute( _rookieID, _focusAttributeID )
	{
		this.rebuildRelationshipsFromRoster();
		local rel = this.getRelationshipByRookieID(_rookieID);
		if (rel == null)
		{
			return { Success = false, Message = "No mentorship relationship was found.", Data = this.queryScreenData() };
		}

		if (rel.FocusAttributeID != null)
		{
			return { Success = false, Message = "Focused training is already locked for this relationship.", Data = this.queryScreenData() };
		}

		local mentor = ::MentorRookie.Helpers.getActorByID(rel.MentorID);
		local rookie = ::MentorRookie.Helpers.getActorByID(rel.RookieID);
		local focusValidation = this.validateFocusAttribute(rel.MentorID, rel.RookieID, _focusAttributeID);
		if (!focusValidation.Valid)
		{
			::MentorRookie.Helpers.debugLog("focus selection rejected mentorID=" + rel.MentorID + " rookieID=" + rel.RookieID + " focus=" + _focusAttributeID + " reason=" + focusValidation.Message);
			return { Success = false, Message = focusValidation.Message, Data = this.queryScreenData() };
		}

		rel.FocusAttributeID = _focusAttributeID;
		rel.FocusedTrainingBattles = 0;
		rel.FocusedTrainingGain = 0;
		this.writeRelationshipFlags(mentor, rookie, rel.BattlesTogether, _focusAttributeID, 0, 0);
		this.writePairHistory(mentor, rookie, rel.BattlesTogether, _focusAttributeID, 0, 0);

		local def = this.getFocusAttributeDef(_focusAttributeID);
		::MentorRookie.Helpers.debugLog("focus selected mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " focus=" + _focusAttributeID);
		return {
			Success = true,
			Message = "Focused training locked: " + (def != null ? def.Name : _focusAttributeID) + ".",
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
		this.writePairHistory(mentor, rookie, rel.BattlesTogether, rel.FocusAttributeID, rel.FocusedTrainingBattles, rel.FocusedTrainingGain);
		this.clearRelationship(mentor, rookie);
		::MentorRookie.Helpers.debugLog("removed active relationship but preserved pair history mentor=" + (mentor == null ? "<null>" : mentor.getName()) + " rookie=" + (rookie == null ? "<null>" : rookie.getName()) + " battles=" + rel.BattlesTogether + " focus=" + (rel.FocusAttributeID == null ? "<none>" : rel.FocusAttributeID) + " trainingBattles=" + rel.FocusedTrainingBattles + " trainingGain=" + rel.FocusedTrainingGain);

		return { Success = true, Message = "Mentorship relationship removed.", Data = this.queryScreenData() };
	}

	function writeRelationshipFlags( _mentor, _rookie, _battles, _focusAttributeID = null, _focusedTrainingBattles = 0, _focusedTrainingGain = 0 )
	{
		_mentor.getFlags().set("MentorRookieRole", "mentor");
		_mentor.getFlags().set("MentorRookiePartnerID", _rookie.getID());
		_mentor.getFlags().set("MentorRookieBattlesTogether", _battles);

		_rookie.getFlags().set("MentorRookieRole", "rookie");
		_rookie.getFlags().set("MentorRookiePartnerID", _mentor.getID());
		_rookie.getFlags().set("MentorRookieBattlesTogether", _battles);

		if (_focusAttributeID != null)
		{
			_mentor.getFlags().set("MentorRookieFocusAttributeID", _focusAttributeID);
			_mentor.getFlags().set("MentorRookieFocusedTrainingBattles", _focusedTrainingBattles);
			_mentor.getFlags().set("MentorRookieFocusedTrainingGain", _focusedTrainingGain);
			_rookie.getFlags().set("MentorRookieFocusAttributeID", _focusAttributeID);
			_rookie.getFlags().set("MentorRookieFocusedTrainingBattles", _focusedTrainingBattles);
			_rookie.getFlags().set("MentorRookieFocusedTrainingGain", _focusedTrainingGain);
		}
		else
		{
			_mentor.getFlags().remove("MentorRookieFocusAttributeID");
			_mentor.getFlags().remove("MentorRookieFocusedTrainingBattles");
			_mentor.getFlags().remove("MentorRookieFocusedTrainingGain");
			_rookie.getFlags().remove("MentorRookieFocusAttributeID");
			_rookie.getFlags().remove("MentorRookieFocusedTrainingBattles");
			_rookie.getFlags().remove("MentorRookieFocusedTrainingGain");
		}
	}

	function clearRelationshipFlags( _actor )
	{
		_actor.getFlags().remove("MentorRookieRole");
		_actor.getFlags().remove("MentorRookiePartnerID");
		_actor.getFlags().remove("MentorRookieBattlesTogether");
		_actor.getFlags().remove("MentorRookieFocusAttributeID");
		_actor.getFlags().remove("MentorRookieFocusedTrainingBattles");
		_actor.getFlags().remove("MentorRookieFocusedTrainingGain");
	}

	function clearRelationship( _mentor, _rookie )
	{
		if (_mentor != null)
		{
			this.clearRelationshipFlags(_mentor);
			_mentor.getSkills().removeByID("effects.mentor_rookie_mentor");
		}

		if (_rookie != null)
		{
			this.clearRelationshipFlags(_rookie);
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
			local focusAttributeID = bro.getFlags().has("MentorRookieFocusAttributeID") ? bro.getFlags().get("MentorRookieFocusAttributeID") : null;
			local focusedTrainingBattles = bro.getFlags().has("MentorRookieFocusedTrainingBattles") ? bro.getFlags().get("MentorRookieFocusedTrainingBattles") : 0;
			local focusedTrainingGain = bro.getFlags().has("MentorRookieFocusedTrainingGain") ? bro.getFlags().get("MentorRookieFocusedTrainingGain") : 0;
			local key = "" + mentor.getID() + ":" + rookie.getID();
			if (key in seen) continue;
			seen[key] <- true;

			this.Relationships.push({
				MentorID = mentor.getID(),
				RookieID = rookie.getID(),
				BattlesTogether = battles,
				FocusAttributeID = focusAttributeID,
				FocusedTrainingBattles = focusedTrainingBattles,
				FocusedTrainingGain = focusedTrainingGain
			});
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

	function calculateFocusedTrainingGain( _mentor, _rookie, _focusAttributeID )
	{
		local mentorStars = this.getTalentStars(_mentor, _focusAttributeID);
		local rookieStars = this.getTalentStars(_rookie, _focusAttributeID);
		local gain = 0;

		if (mentorStars == 1 && rookieStars == 1)
		{
			gain = 1;
		}
		else if (mentorStars == 2 && rookieStars == 1)
		{
			gain = 1;
			if (::Math.rand(1, 100) <= this.getSetting("MasterMentorChanceTwoToOne")) gain += 1;
		}
		else if (mentorStars == 3 && rookieStars == 1)
		{
			gain = 1;
			if (::Math.rand(1, 100) <= this.getSetting("MasterMentorChanceThreeToOne")) gain += 1;
		}
		else if (mentorStars == 3 && rookieStars == 2)
		{
			gain = 2;
		}
		else if (mentorStars == 3 && rookieStars == 3)
		{
			gain = 3;
		}

		::MentorRookie.Helpers.debugLog("focused training calculated mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " mentorStars=" + mentorStars + " rookieStars=" + rookieStars + " gain=" + gain);
		return gain;
	}

	function capFocusedTrainingGain( _currentGain, _proposedGain )
	{
		local maxGain = this.getSetting("MasterMentorMaxGainPerAttribute");
		return ::Math.max(0, ::Math.min(_proposedGain, maxGain - _currentGain));
	}

	function getFocusedAttributeValue( _actor, _focusAttributeID )
	{
		local def = this.getFocusAttributeDef(_focusAttributeID);
		if (_actor == null || def == null) return 0;

		local b = _actor.getBaseProperties();
		if (!(def.AttributeKey in b)) return 0;

		return b[def.AttributeKey];
	}

	function applyFocusedTrainingGain( _rookie, _focusAttributeID, _gain )
	{
		local def = this.getFocusAttributeDef(_focusAttributeID);
		if (_rookie == null || def == null || _gain <= 0) return false;

		local b = _rookie.getBaseProperties();
		if (!(def.AttributeKey in b))
		{
			::MentorRookie.Helpers.debugLog("focused training apply failed rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " reason=missing_attribute_key");
			return false;
		}

		b[def.AttributeKey] += _gain;
		if (def.AttributeKey == "Hitpoints")
		{
			_rookie.m.Hitpoints += _gain;
		}

		_rookie.getSkills().update();
		_rookie.setDirty(true);
		::MentorRookie.Helpers.debugLog("focused training applied rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " gain=" + _gain);
		return true;
	}

	function processFocusedTraining( _rel, _mentor, _rookie, _mentorAlive, _rookieAlive )
	{
		if (!this.getSetting("MasterMentorFocusedTrainingEnabled")) return;
		if (_rel.FocusAttributeID == null) return;

		if (!this.hasMasterMentor(_mentor))
		{
			::MentorRookie.Helpers.debugLog("focused training skipped mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " reason=no_master_mentor");
			return;
		}

		if (this.getSetting("MasterMentorRequireBothAlive") && (!_mentorAlive || !_rookieAlive))
		{
			::MentorRookie.Helpers.debugLog("focused training skipped mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " reason=not_both_alive");
			return;
		}

		local maxGain = this.getSetting("MasterMentorMaxGainPerAttribute");
		if (_rel.FocusedTrainingGain >= maxGain)
		{
			::MentorRookie.Helpers.debugLog("focused training skipped mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " reason=max_gain_reached");
			return;
		}

		_rel.FocusedTrainingBattles++;
		local requiredBattles = this.getSetting("MasterMentorRequiredBattles");

		if (_rel.FocusedTrainingBattles < requiredBattles)
		{
			::MentorRookie.Helpers.debugLog("focused training progress mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " focus=" + _rel.FocusAttributeID + " progress=" + _rel.FocusedTrainingBattles + "/" + requiredBattles);
			return;
		}

		_rel.FocusedTrainingBattles = 0;
		local proposedGain = this.calculateFocusedTrainingGain(_mentor, _rookie, _rel.FocusAttributeID);
		local gain = this.capFocusedTrainingGain(_rel.FocusedTrainingGain, proposedGain);
		if (gain <= 0) return;

		local oldValue = this.getFocusedAttributeValue(_rookie, _rel.FocusAttributeID);
		if (this.applyFocusedTrainingGain(_rookie, _rel.FocusAttributeID, gain))
		{
			local newValue = this.getFocusedAttributeValue(_rookie, _rel.FocusAttributeID);
			_rel.FocusedTrainingGain += gain;
			this.queueFocusedTrainingNotification(_mentor, _rookie, _rel.FocusAttributeID, oldValue, newValue, gain);
		}
	}

	function queueFocusedTrainingNotification( _mentor, _rookie, _focusAttributeID, _oldValue, _newValue, _gain )
	{
		local def = this.getFocusAttributeDef(_focusAttributeID);
		if (def == null) return;

		this.PendingTrainingNotifications.push({
			MentorID = _mentor.getID(),
			MentorName = _mentor.getName(),
			RookieID = _rookie.getID(),
			RookieName = _rookie.getName(),
			FocusAttributeID = _focusAttributeID,
			FocusAttributeName = def.Name,
			OldValue = _oldValue,
			NewValue = _newValue,
			Gain = _gain
		});

		::MentorRookie.Helpers.debugLog("focused training notification queued mentor=" + _mentor.getName() + " rookie=" + _rookie.getName() + " focus=" + _focusAttributeID + " old=" + _oldValue + " new=" + _newValue + " gain=" + _gain);
	}

	function showTrainingProgressEvent()
	{
		if (this.ActiveTrainingNotification != null) return false;
		if (this.PendingTrainingNotifications.len() == 0) return false;
		if (!("World" in getroottable()) || ::World.Events == null) return false;

		if (!::World.Events.canFireEvent(true, true))
		{
			::MentorRookie.Helpers.debugLog("focused training notification delayed reason=event_ui_busy");
			return false;
		}

		this.ActiveTrainingNotification = this.PendingTrainingNotifications.remove(0);
		::MentorRookie.Helpers.debugLog("focused training notification showing mentor=" + this.ActiveTrainingNotification.MentorName + " rookie=" + this.ActiveTrainingNotification.RookieName);

		if (!::World.Events.fire("event.mentor_rookie.master_mentor_training", false))
		{
			this.PendingTrainingNotifications.insert(0, this.ActiveTrainingNotification);
			this.ActiveTrainingNotification = null;
			return false;
		}

		return true;
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
			local baseXP = this.getCapturedBattleXP(rookie.getID());
			::MentorRookie.Helpers.debugLog("valid battle counted mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " battles=" + rel.BattlesTogether + " previousBattles=" + previousBattles + " rookieBaseXP=" + baseXP);
			local bonusXP = this.awardMentorBonusXP(rookie, baseXP);
			this.processFocusedTraining(rel, mentor, rookie, mentorAlive, rookieAlive);
			this.writeRelationshipFlags(mentor, rookie, rel.BattlesTogether, rel.FocusAttributeID, rel.FocusedTrainingBattles, rel.FocusedTrainingGain);
			this.writePairHistory(mentor, rookie, rel.BattlesTogether, rel.FocusAttributeID, rel.FocusedTrainingBattles, rel.FocusedTrainingGain);
			::MentorRookie.Helpers.debugLog("valid battle result mentor=" + mentor.getName() + " rookie=" + rookie.getName() + " battles=" + rel.BattlesTogether + " bonusXP=" + bonusXP);
			this.logMilestonesAndGraduate(mentor, rookie, rel.BattlesTogether);
		}

		this.clearBattleParticipants();
		this.showTrainingProgressEvent();
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
