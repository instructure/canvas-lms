define([
  'jquery',
  'compiled/views/conversations/MessageView',
  'compiled/models/Message'
], ($, MessageView, Message) => {

  module('MessageView', {
    setup () {
      this.model = new Message({
        subject: 'Hey There!',
        participants: [],
        last_message_at: Date.now(),
        last_authored_message_at: Date.now()
      });
      this.view = new MessageView({model: this.model});
      this.view.render()
    },
    teardown () {
      this.view.remove();
    }
  });

  test('it sets proper SR text when starred with a subject', function () {
    this.model.set('starred', true);
    this.view.setStarBtnCheckedScreenReaderMessage();
    const actual = this.view.$el.find('.StarButton-LabelContainer').text();
    const expected = 'Starred "Hey There!", Click to unstar.';
    equal(actual, expected);
  });

  test('it sets proper SR text when starred without a subject', function () {
    this.model.set('starred', true);
    this.model.set('subject', null);
    this.view.setStarBtnCheckedScreenReaderMessage();
    const actual = this.view.$el.find('.StarButton-LabelContainer').text();
    const expected = 'Starred "(No Subject)", Click to unstar.';
    equal(actual, expected);
  });

  test('it sets proper SR text when unstarred without a subject', function () {
    this.model.set('starred', false);
    this.view.setStarBtnCheckedScreenReaderMessage();
    const actual = this.view.$el.find('.StarButton-LabelContainer').text();
    const expected = 'Not starred "Hey There!", Click to star.';
    equal(actual, expected);
  });

  test('it sets proper SR text when unstarred without a subject', function () {
    this.model.set('starred', false);
    this.model.set('subject', null);
    this.view.setStarBtnCheckedScreenReaderMessage();
    const actual = this.view.$el.find('.StarButton-LabelContainer').text();
    const expected = 'Not starred "(No Subject)", Click to star.';
    equal(actual, expected);
  });


});
