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
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import DiscussionTopicToolbarView from '../DiscussionTopicToolbarView'

const ok = x => expect(x).toBeTruthy()
const strictEqual = (x, y) => expect(x).toStrictEqual(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const fixture = `\
<div id="discussion-topic-toolbar">
  <div id="keyboard-shortcut-modal-info" tabindex="0">
    <span class="accessibility-warning" style="display: none;"></span>
  </div>
</div>\
`

let view
let info

describe('DiscussionTopicToolbarView', () => {
  beforeEach(() => {
    $('#fixtures').html(fixture)
    view = new DiscussionTopicToolbarView({el: '#discussion-topic-toolbar'})
    info = view.$('#keyboard-shortcut-modal-info .accessibility-warning')
  })

  afterEach(() => {
    $('#fixtures').empty()
  })

  test('it should be accessible', function (done) {
    isAccessible(view, done, {a11yReport: true})
  })

  test('keyboard shortcut modal info shows when it has focus', function () {
    ok(info.css('display') === 'none')
    view.$('#keyboard-shortcut-modal-info').focus()
    ok(info.css('display') !== 'none')
  })

  test('keyboard shortcut modal info hides when it loses focus', function () {
    view.$('#keyboard-shortcut-modal-info').focus()
    ok(info.css('display') !== 'none')
    view.$('#keyboard-shortcut-modal-info').blur()
    ok(info.css('display') === 'none')
  })

  test('keyboard shortcut modal stays hidden when setting disabled', function () {
    // Stubbing Feature Flag
    try {
      window.ENV.disable_keyboard_shortcuts = true
      view.$('#keyboard-shortcut-modal-info').focus()
      strictEqual(info.css('display'), 'none')
    } finally {
      window.ENV.DISABLE_KEYBOARD_SHORTCUTS = undefined
    }
  })
})
