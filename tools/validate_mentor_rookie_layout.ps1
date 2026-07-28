$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$required = @(
	"scripts\!mods_preload\mod_mentor_rookie.nut",
	"scripts\!mods_preload\mod_mentor_rookie_settings.nut",
	"scripts\config\z_mentor_rookie.nut",
	"scripts\mods\mentor_rookie_service.nut",
	"scripts\skills\effects\mentor_rookie_mentor_effect.nut",
	"scripts\skills\effects\mentor_rookie_rookie_effect.nut",
	"scripts\skills\perks\master_mentor_perk.nut",
	"scripts\ui\screens\world\mentor_rookie_screen.nut",
	"ui\mods\mentor_rookie.js",
	"ui\mods\mentor_rookie.css",
	"ui\mods\mentor_rookie_screen.js",
	"ui\mods\mentor_rookie_screen.css"
)

foreach ($file in $required) {
	$path = Join-Path $root $file
	if (!(Test-Path $path)) {
		throw "Missing required file: $file"
	}
}

$preload = Get-Content (Join-Path $root "scripts\!mods_preload\mod_mentor_rookie.nut") -Raw
@(
	'Version <- "0.0.1"',
	'addSQKeybind',
	'"shift+m"',
	'onCombatFinished',
	'captureCombatParticipants',
	'handleAfterCombat'
) | ForEach-Object {
	if ($preload -notlike "*$_*") {
		throw "Missing expected preload token: $_"
	}
}

$service = Get-Content (Join-Path $root "scripts\mods\mentor_rookie_service.nut") -Raw
@(
	'Level1To3BonusPercent',
	'Level4To6BonusPercent',
	'Level7To10BonusPercent',
	'GraduationBattleCount',
	'_rookie.addXP(inputBonus, false)',
	'XPGainMult'
) | ForEach-Object {
	if ($service -notlike "*$_*") {
		throw "Missing expected service token: $_"
	}
}

Write-Host "Mentor Rookie layout validation passed."
