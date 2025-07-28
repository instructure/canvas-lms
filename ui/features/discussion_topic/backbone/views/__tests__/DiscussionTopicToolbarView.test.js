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
import fakeENV from '@canvas/test-utils/fakeENV'

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
    // Setup with default ENV values
    fakeENV.setup({
      disable_keyboard_shortcuts: false,
    })

    // Reset the DOM fixture
    $('#fixtures').html(fixture)

    // Initialize the view
    view = new DiscussionTopicToolbarView({el: '#discussion-topic-toolbar'})
    info = view.$('#keyboard-shortcut-modal-info .accessibility-warning')
  })

  afterEach(() => {
    // Clean up the view
    view.remove()

    // Clean up the DOM
    $('#fixtures').empty()

    // Reset the ENV
    fakeENV.teardown()
  })

  test('it should be accessible', function (done) {
    isAccessible(view, done, {a11yReport: true})
  })

  test('keyboard shortcut modal info shows when it has focus', function () {
    // Initial state check
    expect(info.css('display')).toBe('none')

    // Trigger focus event
    view.$('#keyboard-shortcut-modal-info').focus()

    // Check that the warning is now visible
    expect(info.css('display')).not.toBe('none')
  })

  test('keyboard shortcut modal info hides when it loses focus', function () {
    // First focus to make it visible
    view.$('#keyboard-shortcut-modal-info').focus()
    expect(info.css('display')).not.toBe('none')

    // Then blur to hide it
    view.$('#keyboard-shortcut-modal-info').blur()
    expect(info.css('display')).toBe('none')
  })

  test('keyboard shortcut modal stays hidden when setting disabled', function () {
    // Teardown the previous ENV setup
    fakeENV.teardown()

    // Setup with the feature flag disabled
    fakeENV.setup({
      disable_keyboard_shortcuts: true,
    })

    // Reset the DOM fixture to ensure a clean state
    $('#fixtures').empty().html(fixture)

    // Re-initialize the view to pick up the new ENV setting
    view = new DiscussionTopicToolbarView({el: '#discussion-topic-toolbar'})
    info = view.$('#keyboard-shortcut-modal-info .accessibility-warning')

    // Try to make it visible by focusing
    view.$('#keyboard-shortcut-modal-info').focus()

    // It should remain hidden
    expect(info.css('display')).toBe('none')
  })
})
