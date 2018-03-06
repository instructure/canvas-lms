/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery';
import moxios from 'moxios';
import handleClickEvent from 'jsx/context_cards/StudentContextCardTrigger';

QUnit.module('StudentContextCardTrigger', {
  setup () {
    $('#fixtures').append('<button class="student_context_card_trigger">Open</button>');
    $('#fixtures').append('<div id="StudentTray__Container"></div>');
    $('#fixtures').append('<div id="application"></div>');
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
