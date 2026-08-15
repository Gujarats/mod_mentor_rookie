if (!("MentorRookie" in getroottable()))
{
	::MentorRookie <- {};
}

::MentorRookie.ID <- "mod_mentor_rookie";
::MentorRookie.Name <- "Mentor Rookie";
::MentorRookie.Version <- "0.2.0";

::MentorRookie.HookMod <- ::Hooks.register(::MentorRookie.ID, ::MentorRookie.Version, ::MentorRookie.Name);
::MentorRookie.HookMod.require("mod_msu >= 1.9.0");

::include("scripts/mods/mentor_rookie_service");
::include("scripts/mods/compatibility/legends_master_mentor_patch");
::include("scripts/mods/compatibility/reforged_master_mentor_patch");

::MentorRookie.openScreen <- function()
{
	if (!("World" in getroottable()) || ::World.State == null)
	{
		::MentorRookie.Helpers.debugLog("open screen rejected: world state unavailable");
		return;
	}

	if (::World.State.getMenuStack().hasBacksteps()
		|| ::World.State.m.CharacterScreen.isVisible()
		|| ::World.State.m.WorldTownScreen.isVisible()
		|| ::World.State.m.EventScreen.isVisible()
		|| ::World.State.m.EventScreen.isAnimating()
		|| (::LoadingScreen != null && (::LoadingScreen.isVisible() || ::LoadingScreen.isAnimating())))
	{
		::MentorRookie.Helpers.debugLog("open screen rejected: blocking UI active");
		return;
	}

	if (!("MentorRookieScreen" in ::World.State.m) || ::World.State.m.MentorRookieScreen == null)
	{
		::MentorRookie.Helpers.debugLog("open screen rejected: screen unavailable");
		return;
	}

	if (::World.State.m.MentorRookieScreen.isVisible())
	{
		::MentorRookie.Helpers.debugLog("closing screen from keybind");
		::World.State.m.MenuStack.pop();
		return;
	}

	if (::World.State.m.MentorRookieScreen.isAnimating())
	{
		::MentorRookie.Helpers.debugLog("open screen rejected: screen animating");
		return;
	}

	::MentorRookie.Helpers.debugLog("opening screen from keybind");
	::World.State.m.CustomZoom = ::World.getCamera().Zoom;
	::World.getCamera().zoomTo(1.0, 4.0);
	::World.State.setAutoPause(true);
	::World.State.m.MentorRookieScreen.show();
	::World.State.m.WorldScreen.hide();
	::Cursor.setCursor(::Const.UI.Cursor.Hand);
	::World.State.m.MenuStack.push(function()
	{
		::World.getCamera().zoomTo(this.m.CustomZoom, 4.0);
		this.m.MentorRookieScreen.hide();
		this.m.WorldScreen.show();
		this.setAutoPause(false);
		this.Cursor.setCursor(this.Const.UI.Cursor.Hand);
	}, function()
	{
		return !this.m.MentorRookieScreen.isAnimating();
	});
}

::MentorRookie.registerKeybinds <- function()
{
	::MentorRookie.Mod.Keybinds.addSQKeybind(
		"open_mentor_rookie_screen",
		"shift+m",
		::MSU.Key.State.World,
		function()
		{
			::MentorRookie.openScreen();
		},
		"Open Mentor Rookie Screen",
		null,
		"Open the Mentor Rookie relationship screen"
	);
}

::MentorRookie.HookMod.queue(">mod_msu", ">mod_druid", ">mod_aura_routing", ">mod_bandages_enhanced", ">mod_from_the_grave", ">mod_legends", ">mod_necro", ">mod_reforged", function()
{
	::MentorRookie.Mod <- ::MSU.Class.Mod(::MentorRookie.ID, ::MentorRookie.Version, ::MentorRookie.Name);
	::MentorRookie.registerSettings();
	::MentorRookie.configureDebugLogging();
	::MentorRookie.registerKeybinds();
	::MentorRookie.Helpers.debugLog("settings initialized");

	local mod = ::MentorRookie.HookMod;
	::MentorRookie.Compatibility.Legends.registerHooks(mod);

	::Hooks.registerJS("ui/mods/mentor_rookie.js");
	::Hooks.registerCSS("ui/mods/mentor_rookie.css");
	::Hooks.registerJS("ui/mods/mentor_rookie_screen.js");
	::Hooks.registerCSS("ui/mods/mentor_rookie_screen.css");

	mod.hook("scripts/states/world_state", function(q)
	{
		q.onInitUI = @(__original) function()
		{
			__original();
			this.m.MentorRookieScreen <- this.new("scripts/ui/screens/world/mentor_rookie_screen");
			this.m.MentorRookieScreen.setOnClosePressedListener(function()
			{
				if (this.m.MentorRookieScreen.isVisible())
				{
					this.m.MenuStack.pop();
				}
			}.bindenv(this));
			this.m.MentorRookieScreen.create();
			::MentorRookie.Helpers.debugLog("world screen initialized");
		}

		q.onDestroyUI = @(__original) function()
		{
			if ("MentorRookieScreen" in this.m && this.m.MentorRookieScreen != null)
			{
				this.m.MentorRookieScreen.destroy();
				this.m.MentorRookieScreen = null;
				::MentorRookie.Helpers.debugLog("world screen destroyed");
			}

			__original();
		}

		q.onCombatFinished = @(__original) function()
		{
			::MentorRookie.Service.captureCombatParticipants();
			local ret = __original();
			::MentorRookie.Service.handleAfterCombat();
			return ret;
		}

		q.onUpdate = @(__original) function()
		{
			__original();

			if ("MentorRookie" in ::getroottable() && "Service" in ::MentorRookie)
			{
				::MentorRookie.Compatibility.Reforged.tryMigrateExistingPlayerTrees();
				::MentorRookie.Service.showTrainingProgressEvent();
			}
		}
	});

	mod.hook("scripts/ui/global/data_helper", function(q)
	{
		q.convertEntityToUIData = @(__original) function( _entity, _activeEntity )
		{
			local result = __original(_entity, _activeEntity);
			if (::Hooks.hasMod("mod_legends") || ::Hooks.hasMod("mod_reforged"))
			{
				if (_entity != null)
				{
					if (::Hooks.hasMod("mod_reforged"))
					{
						::MentorRookie.Helpers.debugLog("[Reforged] skipped UI-only Master Mentor injection for " + _entity.getName());
					}
					else
					{
						::MentorRookie.Helpers.debugLog("[Legends] skipped UI-only Master Mentor injection for " + _entity.getName());
					}
				}

				return result;
			}

			if (_entity != null)
			{
				local row = ::MentorRookie.Mod.ModSettings.getSetting("MasterMentorPerkRow").getValue();
				local injected = false;

				foreach (key, value in result)
				{
					if (typeof key == "string"
						&& key.find("_perkTree") != null
						&& key != "mentor_rookie_perkTree"
						&& typeof value == "array")
					{
						result[key] = ::MentorRookie.Helpers.appendMentorRookiePerks(value, row);
						injected = true;
						::MentorRookie.Helpers.debugLog("merged Master Mentor perk into " + key + " for " + _entity.getName());
					}
				}

				if (!injected)
				{
					result.mentor_rookie_perkTree <- ::MentorRookie.Helpers.appendMentorRookiePerks(::Const.Perks.Perks, row);
					::MentorRookie.Helpers.debugLog("injecting fallback Master Mentor perk tree for " + _entity.getName());
				}
			}

			return result;
		}
	});
});

// Seperate hook to ensure that the Reforged compatibility is registered after all other mods have been initialized
// does not included with vanilla and legends due to mod reforged registering their perks using AfterHooks
// This should work only for new campaign and does not work for existing saves
::MentorRookie.HookMod.queue(">mod_reforged", function()
{
	::MentorRookie.Compatibility.Reforged.register();
}, ::Hooks.QueueBucket.AfterHooks);
