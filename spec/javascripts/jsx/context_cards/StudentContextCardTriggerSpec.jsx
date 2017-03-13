import $ from 'jquery';
import moxios from 'moxios';
import handleClickEvent from 'jsx/context_cards/StudentContextCardTrigger';

QUnit.module('StudentContextCardTrigger', {
  setup () {
    $('#fixtures').append('<button class="student_context_card_trigger">Open</button>');
    $('#fixtures').append('<div id="StudentContextTray__Container"></div>');
    window.ENV.STUDENT_CONTEXT_CARDS_ENABLED = true
    moxios.install();
  },

  teardown () {
    $('#fixtures').empty();
    moxios.uninstall();
    delete window.ENV.STUDENT_CONTEXT_CARDS_ENABLED
  }
});

test('it works with really large student and course ids', (assert) => {
  const done = assert.async();
  const bigStringId = '109007199254740991';
  $('.student_context_card_trigger').attr('data-student_id', bigStringId);
  $('.student_context_card_trigger').attr('data-course_id', bigStringId);
  const fakeEvent = {
    target: $('.student_context_card_trigger'),
    preventDefault () {}
  };

  handleClickEvent(fakeEvent);

  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    const regexp = new RegExp(bigStringId);
    ok(regexp.test(request.url));
    done();
  })
});
