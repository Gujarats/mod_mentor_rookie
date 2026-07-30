this.mentor_rookie_master_mentor_training_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.mentor_rookie.master_mentor_training";
		this.m.Title = "Master Mentor";
		this.m.IsSpecial = true;
		this.m.Screens.push({
			ID = "A",
			Text = "",
			Image = "",
			Characters = [],
			Options = [
				{
					Text = "Continue",
					function getResult( _event )
					{
						::MentorRookie.Service.ActiveTrainingNotification = null;
						return 0;
					}
				}
			],
			function start( _event )
			{
				local data = ::MentorRookie.Service.ActiveTrainingNotification;
				if (data == null)
				{
					this.Text = "The training lesson has passed.";
					return;
				}

				local mentor = ::MentorRookie.Helpers.getActorByID(data.MentorID);
				local rookie = ::MentorRookie.Helpers.getActorByID(data.RookieID);

				if (mentor != null)
				{
					this.Characters.push(mentor.getImagePath());
				}

				if (rookie != null)
				{
					this.Characters.push(rookie.getImagePath());
				}

				this.Text = "[img]gfx/ui/events/event_05.png[/img]" + data.MentorName + " has guided " + data.RookieName + " through enough battles for the lesson to become instinct.\n\n" + data.RookieName + " improved:\n\n" + data.FocusAttributeName + ": " + data.OldValue + " -> " + data.NewValue + " (+" + data.Gain + ")";
			}
		});
	}
});
