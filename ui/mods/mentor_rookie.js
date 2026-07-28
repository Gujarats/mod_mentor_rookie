var MentorRookie = {};

MentorRookie.CharacterScreenPerksModule_loadPerkTreesWithBrotherData
	= CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData;
CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData = function(_brother)
{
	if (_brother.mentor_rookie_perkTree)
	{
		for (var key in _brother)
		{
			if (key !== 'mentor_rookie_perkTree' && key.indexOf('_perkTree') !== -1)
			{
				MentorRookie.CharacterScreenPerksModule_loadPerkTreesWithBrotherData.call(this, _brother);
				return;
			}
		}

		this.onPerkTreeLoaded(null, _brother.mentor_rookie_perkTree);
		return;
	}

	MentorRookie.CharacterScreenPerksModule_loadPerkTreesWithBrotherData.call(this, _brother);
};
