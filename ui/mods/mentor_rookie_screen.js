var MentorRookieScreen = function()
{
	this.mSQHandle = null;
	this.mContainer = null;
	this.mRoster = null;
	this.mRelationships = null;
	this.mMentorSelect = null;
	this.mRookieSelect = null;
	this.mMessage = null;
};

MentorRookieScreen.prototype.isConnected = function()
{
	return this.mSQHandle !== null;
};

MentorRookieScreen.prototype.onConnection = function(_handle)
{
	this.mSQHandle = _handle;
	this.createDIV();
	this.mSQHandle.asyncCall('onScreenConnected', null);
};

MentorRookieScreen.prototype.onDisconnection = function()
{
	this.destroyDIV();
	this.mSQHandle = null;
};

MentorRookieScreen.prototype.createDIV = function()
{
	var self = this;
	this.mContainer = $('<div class="mentor-rookie-screen display-none opacity-none"/>');
	var panel = $('<div class="mentor-rookie-panel"/>');
	var header = $('<div class="mentor-rookie-header title-font-big font-color-title">Mentor Rookie</div>');
	var body = $('<div class="mentor-rookie-body"/>');
	var controls = $('<div class="mentor-rookie-controls"/>');

	this.mMentorSelect = $('<select class="mentor-rookie-select text-font-normal"/>');
	this.mRookieSelect = $('<select class="mentor-rookie-select text-font-normal"/>');
	var createButton = $('<button class="mentor-rookie-button text-font-normal">Create Pair</button>');
	var closeButton = $('<button class="mentor-rookie-button text-font-normal">Close</button>');
	this.mMessage = $('<div class="mentor-rookie-message description-font-medium font-color-description"/>');
	this.mRoster = $('<div class="mentor-rookie-list"/>');
	this.mRelationships = $('<div class="mentor-rookie-list"/>');

	createButton.click(function()
	{
		self.createRelationship();
	});
	closeButton.click(function()
	{
		self.notifyBackendCloseButtonPressed();
	});

	controls.append($('<div class="mentor-rookie-label text-font-normal">Mentor</div>'));
	controls.append(this.mMentorSelect);
	controls.append($('<div class="mentor-rookie-label text-font-normal">Rookie</div>'));
	controls.append(this.mRookieSelect);
	controls.append(createButton);
	controls.append(closeButton);
	body.append(controls);
	body.append(this.mMessage);
	body.append($('<div class="mentor-rookie-section-title title-font-normal font-color-title">Active Relationships</div>'));
	body.append(this.mRelationships);
	body.append($('<div class="mentor-rookie-section-title title-font-normal font-color-title">Roster</div>'));
	body.append(this.mRoster);
	panel.append(header);
	panel.append(body);
	this.mContainer.append(panel);
	$('body').append(this.mContainer);
};

MentorRookieScreen.prototype.destroyDIV = function()
{
	if (this.mContainer !== null)
	{
		this.mContainer.remove();
		this.mContainer = null;
	}
};

MentorRookieScreen.prototype.show = function(_data)
{
	this.updateData(_data);
	this.mContainer.removeClass('display-none').addClass('display-block');
	var self = this;
	this.mContainer.velocity('finish', true).velocity({ opacity: 1 }, {
		duration: 150,
		begin: function()
		{
			self.mContainer.removeClass('opacity-none');
			self.notifyBackendOnAnimating();
		},
		complete: function()
		{
			self.notifyBackendOnShown();
		}
	});
};

MentorRookieScreen.prototype.hide = function()
{
	var self = this;
	this.mContainer.velocity('finish', true).velocity({ opacity: 0 }, {
		duration: 150,
		begin: function()
		{
			self.notifyBackendOnAnimating();
		},
		complete: function()
		{
			self.mContainer.removeClass('display-block').addClass('display-none opacity-none');
			self.notifyBackendOnHidden();
		}
	});
};

MentorRookieScreen.prototype.updateData = function(_data)
{
	var data = _data || { Roster: [], Relationships: [] };
	this.mMentorSelect.empty();
	this.mRookieSelect.empty();
	this.mRoster.empty();
	this.mRelationships.empty();

	for (var i = 0; i < data.Roster.length; i++)
	{
		var bro = data.Roster[i];
		var label = bro.Name + ' (Level ' + bro.Level + ')';
		this.mMentorSelect.append($('<option/>').attr('value', bro.ID).text(label));
		this.mRookieSelect.append($('<option/>').attr('value', bro.ID).text(label));

		var row = $('<div class="mentor-rookie-row text-font-normal"/>');
		row.append($('<div/>').text(label));
		row.append($('<div/>').text(bro.IsMentor ? 'Mentor' : (bro.IsRookie ? 'Rookie' : 'Available')));
		this.mRoster.append(row);
	}

	if (data.Relationships.length === 0)
	{
		this.mRelationships.append($('<div class="mentor-rookie-empty description-font-medium font-color-description">No active mentorship relationship.</div>'));
	}

	for (var r = 0; r < data.Relationships.length; r++)
	{
		var rel = data.Relationships[r];
		var relRow = $('<div class="mentor-rookie-row text-font-normal"/>');
		relRow.append($('<div/>').text(rel.MentorName + ' -> ' + rel.RookieName + ' (' + rel.BattlesTogether + ' battles)'));
		var removeButton = $('<button class="mentor-rookie-small-button text-font-normal">Remove</button>');
		removeButton.data('rookie-id', rel.RookieID);
		removeButton.click(this.removeRelationship.bind(this));
		relRow.append(removeButton);
		this.mRelationships.append(relRow);
	}
};

MentorRookieScreen.prototype.createRelationship = function()
{
	var self = this;
	var mentorID = parseInt(this.mMentorSelect.val(), 10);
	var rookieID = parseInt(this.mRookieSelect.val(), 10);
	SQ.call(this.mSQHandle, 'onCreateRelationship', [mentorID, rookieID], function(_result)
	{
		self.handleResult(_result);
	});
};

MentorRookieScreen.prototype.removeRelationship = function(_event)
{
	var self = this;
	var rookieID = parseInt($(_event.currentTarget).data('rookie-id'), 10);
	SQ.call(this.mSQHandle, 'onRemoveRelationship', [rookieID], function(_result)
	{
		self.handleResult(_result);
	});
};

MentorRookieScreen.prototype.handleResult = function(_result)
{
	if (_result !== undefined && _result !== null)
	{
		this.mMessage.text(_result.Message || '');
		if (_result.Data !== undefined && _result.Data !== null)
		{
			this.updateData(_result.Data);
		}
	}
};

MentorRookieScreen.prototype.notifyBackendCloseButtonPressed = function()
{
	SQ.call(this.mSQHandle, 'onCloseButtonPressed');
};

MentorRookieScreen.prototype.notifyBackendOnShown = function()
{
	SQ.call(this.mSQHandle, 'onScreenShown');
};

MentorRookieScreen.prototype.notifyBackendOnHidden = function()
{
	SQ.call(this.mSQHandle, 'onScreenHidden');
};

MentorRookieScreen.prototype.notifyBackendOnAnimating = function()
{
	SQ.call(this.mSQHandle, 'onScreenAnimating');
};

registerScreen('MentorRookieScreen', new MentorRookieScreen());
