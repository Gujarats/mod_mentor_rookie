var MentorRookieScreen = function()
{
	this.mSQHandle = null;
	this.mContainer = null;
	this.mMentorList = null;
	this.mRookieList = null;
	this.mRelationships = null;
	this.mMessage = null;
	this.mData = null;
	this.mSelectedMentorID = null;
	this.mSelectedRookieID = null;
};

MentorRookieScreen.prototype.isConnected = function()
{
	return this.mSQHandle !== null;
};

MentorRookieScreen.prototype.onConnection = function(_handle)
{
	this.mSQHandle = _handle;
	this.createDIV();
	SQ.call(this.mSQHandle, 'onScreenConnected');
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
	var header = $('<div class="mentor-rookie-header"/>');
	var body = $('<div class="mentor-rookie-body"/>');
	var columns = $('<div class="mentor-rookie-columns"/>');
	var actions = $('<div class="mentor-rookie-actions"/>');

	header.append($('<div class="title title-font-big font-color-title">Mentor Rookie</div>'));

	this.mMentorList = $('<div class="mentor-rookie-list"/>');
	this.mRookieList = $('<div class="mentor-rookie-list"/>');
	this.mRelationships = $('<div class="mentor-rookie-relationships"/>');
	this.mMessage = $('<div class="mentor-rookie-message description-font-medium font-color-description">Select one mentor and one rookie.</div>');

	var mentorColumn = $('<div class="mentor-rookie-column is-left"/>');
	mentorColumn.append($('<div class="mentor-rookie-section-title title-font-normal font-color-title">Mentors</div>'));
	mentorColumn.append(this.mMentorList);

	var rookieColumn = $('<div class="mentor-rookie-column is-right"/>');
	rookieColumn.append($('<div class="mentor-rookie-section-title title-font-normal font-color-title">Rookies</div>'));
	rookieColumn.append(this.mRookieList);

	var createButton = $('<button class="mentor-rookie-button text-font-normal">Create Pair</button>');
	var closeButton = $('<button class="mentor-rookie-button text-font-normal">Close</button>');

	createButton.click(function()
	{
		self.createRelationship();
	});

	closeButton.click(function()
	{
		self.notifyBackendCloseButtonPressed();
	});

	columns.append(mentorColumn);
	columns.append(rookieColumn);
	actions.append(createButton);
	actions.append(closeButton);

	body.append(columns);
	body.append($('<div class="mentor-rookie-section-title mentor-rookie-relationships-title title-font-normal font-color-title">Active Relationships</div>'));
	body.append(this.mRelationships);
	body.append(this.mMessage);
	body.append(actions);

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
		duration: Constants.SCREEN_FADE_IN_OUT_DELAY,
		easing: 'swing',
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
		duration: Constants.SCREEN_FADE_IN_OUT_DELAY,
		easing: 'swing',
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
	this.mData = _data || { Roster: [], Relationships: [] };
	this.render();
};

MentorRookieScreen.prototype.render = function()
{
	var self = this;
	var data = this.mData || { Roster: [], Relationships: [] };
	this.mMentorList.empty();
	this.mRookieList.empty();
	this.mRelationships.empty();

	for (var i = 0; i < data.Roster.length; i++)
	{
		var bro = data.Roster[i];
		this.mMentorList.append(this.createBrotherRow(bro, 'mentor'));
		this.mRookieList.append(this.createBrotherRow(bro, 'rookie'));
	}

	if (data.Relationships.length === 0)
	{
		this.mRelationships.append($('<div class="mentor-rookie-empty description-font-medium font-color-description">No active mentorship relationship.</div>'));
	}

	for (var r = 0; r < data.Relationships.length; r++)
	{
		var rel = data.Relationships[r];
		var relRow = $('<div class="mentor-rookie-relationship-row"/>');
		relRow.append($('<div class="mentor-rookie-relationship-text title-font-normal font-color-title"/>').text(rel.MentorName + ' -> ' + rel.RookieName + ' (' + rel.BattlesTogether + ' battles)'));

		var removeButton = $('<button class="mentor-rookie-small-button text-font-normal">Remove</button>');
		removeButton.data('rookie-id', rel.RookieID);
		removeButton.click(function(_event)
		{
			self.removeRelationship(_event);
		});

		relRow.append(removeButton);
		this.mRelationships.append(relRow);
	}
};

MentorRookieScreen.prototype.createBrotherRow = function(_bro, _role)
{
	var self = this;
	var isSelected = _role === 'mentor' ? this.mSelectedMentorID === _bro.ID : this.mSelectedRookieID === _bro.ID;
	var isLocked = _role === 'mentor' ? _bro.IsMentor || _bro.IsRookie : _bro.IsRookie || _bro.IsMentor;
	var row = $('<div class="mentor-rookie-bro-row"/>');
	var portrait = $('<div class="mentor-rookie-portrait"/>');
	var content = $('<div class="mentor-rookie-bro-content"/>');
	var name = $('<div class="mentor-rookie-bro-name title-font-normal font-color-title"/>').text(_bro.Name);
	var details = $('<div class="mentor-rookie-bro-details text-font-normal"/>').text('Level ' + _bro.Level);
	var status = $('<div class="mentor-rookie-bro-status description-font-medium"/>');

	if (_bro.ImagePath)
	{
		var imageOffsetX = ('ImageOffsetX' in _bro ? _bro.ImageOffsetX : 0);
		var imageOffsetY = ('ImageOffsetY' in _bro ? _bro.ImageOffsetY : 0);
		(function(_portrait, _imagePath, _imageOffsetX, _imageOffsetY)
		{
			_portrait.createImage(Path.PROCEDURAL + _imagePath, function(_image)
			{
				_image.centerImageWithinParent(_imageOffsetX, _imageOffsetY, 0.64);
				_image.removeClass('opacity-none');
			}, null, 'opacity-none');
		})(portrait, _bro.ImagePath, imageOffsetX, imageOffsetY);
	}

	if (_bro.IsMentor)
	{
		status.addClass('is-warning').text('Already mentoring');
	}
	else if (_bro.IsRookie)
	{
		status.addClass('is-warning').text('Already rookie');
	}
	else
	{
		status.addClass('is-available').text('Available');
	}

	if (isSelected)
	{
		row.addClass('is-selected');
	}

	if (isLocked)
	{
		row.addClass('is-locked');
	}

	row.data('bro-id', _bro.ID);
	row.click(function()
	{
		if (_role === 'mentor')
		{
			self.mSelectedMentorID = _bro.ID;
		}
		else
		{
			self.mSelectedRookieID = _bro.ID;
		}

		self.render();
	});

	content.append(name);
	content.append(details);
	content.append(status);
	row.append(portrait);
	row.append(content);
	return row;
};

MentorRookieScreen.prototype.createRelationship = function()
{
	var self = this;

	if (this.mSelectedMentorID === null || this.mSelectedRookieID === null)
	{
		this.mMessage.text('Select one mentor and one rookie.');
		return;
	}

	SQ.call(this.mSQHandle, 'onCreateRelationship', [this.mSelectedMentorID, this.mSelectedRookieID], function(_result)
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
			this.mSelectedMentorID = null;
			this.mSelectedRookieID = null;
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
