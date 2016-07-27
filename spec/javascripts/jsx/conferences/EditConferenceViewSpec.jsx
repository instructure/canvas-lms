define([
  'compiled/views/conferences/EditConferenceView',
  'compiled/models/Conference',
  'helpers/fakeENV'
], (EditConferenceView, Conference, fakeENV) => {
  module('EditConferenceView', {
    setup () {
      this.view = new EditConferenceView();
      fakeENV.setup({conference_type_details: []});
    },
    teardown () {
      fakeENV.teardown();
    }
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
});
