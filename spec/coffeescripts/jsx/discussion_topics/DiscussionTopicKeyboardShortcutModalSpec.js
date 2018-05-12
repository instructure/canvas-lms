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
import DiscussionTopicKeyboardShortcutModal from 'jsx/discussion_topics/DiscussionTopicKeyboardShortcutModal'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import I18n from 'i18n!KeyboardShortcutModal'


const SHORTCUTS = [
  {
    keycode: 'j',
    description: I18n.t('Next Message')
  },
  {
    keycode: 'k',
    description: I18n.t('Previous Message')
  },
  {
    keycode: 'e',
    description: I18n.t('Edit Current Message')
  },
  {
    keycode: 'd',
    description: I18n.t('Delete Current Message')
  },
  {
    keycode: 'r',
    description: I18n.t('Reply to Current Message')
  },
  {
    keycode: 'n',
    description: I18n.t('Reply to Topic')
  }
]

QUnit.module('DiscussionTopicKeyboardShortcutModal#render', {
  setup() {
    return $('#fixtures').append('<div id="application" />')
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.component.getDOMNode().parentNode)
    $('#fixtures').empty()
  }
})

test('renders shortcuts', function() {
  const DiscussionTopicKeyboardShortcutModalElement = (
    <DiscussionTopicKeyboardShortcutModal isOpen />
  )
  this.component = TestUtils.renderIntoDocument(DiscussionTopicKeyboardShortcutModalElement)
  const list = $('.ReactModalPortal').find('.navigation_list li')
  equal(SHORTCUTS.length, list.length)
  ok(
    SHORTCUTS.every(sc =>
      list.toArray().some(li => {
        const keycode = $(li)
          .find('.keycode')
          .text()
        const description = $(li)
          .find('.description')
          .text()
        return sc.keycode === keycode && sc.description === description
      })
    )
  )
})
