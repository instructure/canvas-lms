define([
  'jquery',
  'compiled/views/ToggleableSubscriptionIconView',
  'compiled/models/DiscussionTopic'
], ($, ToggleableSubscriptionIconView, DiscussionTopic) => {
  QUnit.module('ToggleableSubscriptionIconView', {
    setup () {
      this.model = new DiscussionTopic();
      this.view = new ToggleableSubscriptionIconView({model: this.model});
    },
    teardown () {
      this.view.remove();
    }
  });

  test('shows proper SR text when the model is subscribed', function () {
    this.model.set('subscribed', true);
    this.view.setScreenreaderText()
    const actual = this.view.$el.attr('aria-label');
    const expected = 'You are subscribed to this topic. Click to unsubscribe.';
    equal(actual, expected);
  });

  test('shows proper SR text when the model is not subscribed', function () {
    this.model.set('subscribed', false);
    this.view.setScreenreaderText()
    const actual = this.view.$el.attr('aria-label');
    const expected = 'You are not subscribed to this topic. Click to subscribe.';
    equal(actual, expected);
  });
});
