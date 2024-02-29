/* eslint-disable qunit/resolve-async */
/* eslint-disable qunit/no-ok-equality */
/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import assertions from 'helpers/assertions'
import DiscussionTopicToolbarView from 'ui/features/discussion_topic/backbone/views/DiscussionTopicToolbarView'

const fixture = `\
<div id="discussion-topic-toolbar">
  <div id="keyboard-shortcut-modal-info" tabindex="0">
    <span class="accessibility-warning" style="display: none;"></span>
  </div>
</div>\
`

QUnit.module('DiscussionTopicToolbarView', {
  setup() {
    $('#fixtures').html(fixture)
    this.view = new DiscussionTopicToolbarView({el: '#discussion-topic-toolbar'})
    this.info = this.view.$('#keyboard-shortcut-modal-info .accessibility-warning')
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('it should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.view, done, {a11yReport: true})
})

test('keyboard shortcut modal info shows when it has focus', function () {
  ok(this.info.css('display') === 'none')
  this.view.$('#keyboard-shortcut-modal-info').focus()
  ok(this.info.css('display') !== 'none')
})

test('keyboard shortcut modal info hides when it loses focus', function () {
  this.view.$('#keyboard-shortcut-modal-info').focus()
  ok(this.info.css('display') !== 'none')
  this.view.$('#keyboard-shortcut-modal-info').blur()
  ok(this.info.css('display') === 'none')
})

test('keyboard shortcut modal stays hidden when setting disabled', function () {
  // Stubbing Feature Flag
  try {
    window.ENV.disable_keyboard_shortcuts = true
    this.view.$('#keyboard-shortcut-modal-info').focus()
    strictEqual(this.info.css('display'), 'none')
  } finally {
    window.ENV.DISABLE_KEYBOARD_SHORTCUTS = undefined
  }
})
