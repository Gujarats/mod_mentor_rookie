param(
	[string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Assert-Contains([string]$RelativePath, [string]$Token)
{
	$Path = Join-Path $Root $RelativePath
	if (!(Test-Path -LiteralPath $Path))
	{
		throw "Missing required file: $RelativePath"
	}

	if ((Get-Content -Raw -LiteralPath $Path).IndexOf($Token) -lt 0)
	{
		throw "Expected '$RelativePath' to contain '$Token'"
	}
}

Assert-Contains "scripts/mods/compatibility/legends_master_mentor_patch.nut" "perk.master_mentor"
Assert-Contains "scripts/mods/compatibility/legends_master_mentor_patch.nut" "addPerkDefObjects"
Assert-Contains "scripts/mods/compatibility/legends_master_mentor_patch.nut" "addMasterMentorToBackground"
Assert-Contains "scripts/mods/compatibility/legends_master_mentor_patch.nut" "_background.addPerk"
Assert-Contains "scripts/mods/compatibility/legends_master_mentor_patch.nut" "buildPerkTree"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "legends_master_mentor_patch"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" "::MentorRookie.Compatibility.Legends.registerHooks(mod);"
Assert-Contains "scripts/!mods_preload/mod_mentor_rookie.nut" 'if (::Hooks.hasMod("mod_legends"))'

Write-Output "Mentor Rookie Legends compatibility contract passed."
