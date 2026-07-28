this.mentor_rookie_screen <- {
	m = {
		JSHandle = null,
		Visible = false,
		Animating = false,
		OnClosePressedListener = null
	},

	function isVisible()
	{
		return this.m.Visible != null && this.m.Visible == true;
	}

	function isAnimating()
	{
		return this.m.Animating != null && this.m.Animating == true;
	}

	function setOnClosePressedListener( _listener )
	{
		this.m.OnClosePressedListener = _listener;
	}

	function create()
	{
		this.m.Visible = false;
		this.m.Animating = false;
		this.m.JSHandle = this.UI.connect("MentorRookieScreen", this);
		::MentorRookie.Helpers.debugLog("screen created");
	}

	function destroy()
	{
		this.m.OnClosePressedListener = null;
		this.m.JSHandle = this.UI.disconnect(this.m.JSHandle);
		::MentorRookie.Helpers.debugLog("screen destroyed");
	}

	function show()
	{
		if (this.m.JSHandle != null)
		{
			this.Tooltip.hide();
			this.m.JSHandle.asyncCall("show", ::MentorRookie.Service.queryScreenData());
			::MentorRookie.Helpers.debugLog("screen show");
		}
	}

	function hide( _withSlideAnimation = false )
	{
		if (this.m.JSHandle != null)
		{
			this.Tooltip.hide();
			this.m.JSHandle.asyncCall("hide", _withSlideAnimation);
			::MentorRookie.Helpers.debugLog("screen hide");
		}
	}

	function onCreateRelationship( _data )
	{
		local mentorID = _data[0];
		local rookieID = _data[1];
		return ::MentorRookie.Service.createRelationship(mentorID, rookieID);
	}

	function onRemoveRelationship( _data )
	{
		local rookieID = typeof _data == "array" ? _data[0] : _data;
		return ::MentorRookie.Service.removeRelationshipByRookieID(rookieID);
	}

	function onCloseButtonPressed()
	{
		::MentorRookie.Helpers.debugLog("screen close requested");
		if (this.m.OnClosePressedListener != null)
		{
			this.m.OnClosePressedListener();
		}
	}

	function onScreenConnected()
	{
	}

	function onScreenDisconnected()
	{
	}

	function onScreenShown()
	{
		this.m.Visible = true;
		this.m.Animating = false;
	}

	function onScreenHidden()
	{
		this.m.Visible = false;
		this.m.Animating = false;
	}

	function onScreenAnimating()
	{
		this.m.Animating = true;
	}
};
