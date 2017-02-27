define([
  'compiled/views/conferences/EditConferenceView',
  'compiled/models/Conference',
  'timezone',
  'timezone/fr_FR',
  'helpers/I18nStubber',
  'helpers/fakeENV'
], (EditConferenceView, Conference, tz, french, I18nStubber, fakeENV) => {
  QUnit.module('EditConferenceView', {
    setup () {
      this.view = new EditConferenceView();
      this.snapshot = tz.snapshot();
      this.datepickerSetting = {field: 'datepickerSetting', type: 'date_picker'};
      fakeENV.setup({conference_type_details: [{settings: [this.datepickerSetting]}]})
    },
    teardown () {
      fakeENV.teardown();
      tz.restore(this.snapshot);
    }
  });

  test('updateConferenceUserSettingDetailsForConference localizes values for datepicker settings', function () {
    tz.changeLocale(french, 'fr_FR', 'fr');
    I18nStubber.pushFrame();
    I18nStubber.setLocale('fr_FR');
    I18nStubber.stub('fr_FR', {'date.formats.full_with_weekday': '%a %-d %b, %Y %-k:%M'});

    const conferenceData = {user_settings: {datepickerSetting: '2015-08-07T17:00:00Z'}};
    this.view.updateConferenceUserSettingDetailsForConference(conferenceData);
    equal(this.datepickerSetting.value, 'ven. 7 août, 2015 17:00');
    I18nStubber.popFrame();
  });

  test('#show sets the proper title for new conferences', function () {
    const expectedTitle = 'New Conference';
    const attributes = {
      recordings: [],
      user_settings: {
        scheduled_date: new Date()
      },
      permissions: {
        update: true
      }
    };

    const conference = new Conference(attributes)
    this.view.show(conference);
    const title = this.view.$el.dialog('option', 'title');
    equal(title, expectedTitle);
  });

  test('#show sets the proper title for editing conferences', function () {
    const expectedTitle = 'Edit &quot;InstructureCon&quot;';
    const attributes = {
      title: 'InstructureCon',
      recordings: [],
      user_settings: {
        scheduled_date: new Date()
      },
      permissions: {
        update: true
      }
    };

    const conference = new Conference(attributes)
    this.view.show(conference, {isEditing: true});
    const title = this.view.$el.dialog('option', 'title');
    equal(title, expectedTitle);
  });

  test('#show sets localized durataion when editing conference', function () {
    const expectedDuration = '1,234.5';
    const attributes = {
      title: 'InstructureCon',
      recordings: [],
      user_settings: {
        scheduled_date: new Date()
      },
      permissions: {
        update: true
      },
      duration: 1234.5
    };

    const conference = new Conference(attributes);
    this.view.show(conference, {isEditing: true});
    const duration = this.view.$('#web_conference_duration')[0].value;
    equal(duration, expectedDuration);
  });
});
