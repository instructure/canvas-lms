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

import DiscussionTopicKeyboardShortcutModal from 'ui/features/discussion_topic/react/DiscussionTopicKeyboardShortcutModal'
import React from 'react'
import {render} from '@testing-library/react'

const SHORTCUTS = [
  {
    keycode: 'j',
    description: 'Next Message',
  },
  {
    keycode: 'k',
    description: 'Previous Message',
  },
  {
    keycode: 'e',
    description: 'Edit Current Message',
  },
  {
    keycode: 'd',
    description: 'Delete Current Message',
  },
  {
    keycode: 'r',
    description: 'Reply to Current Message',
  },
  {
    keycode: 'n',
    description: 'Reply to Topic',
  },
]

QUnit.module('DiscussionTopicKeyboardShortcutModal#render')

test('renders shortcuts', async function () {
  const wrapper = render(<DiscussionTopicKeyboardShortcutModal />)

  // open the modal by pressing "ALT + f8"
  const e = new Event('keydown')
  e.which = 119
  e.altKey = true
  document.dispatchEvent(e)

  // have to wait for instUI modal css transitions
  await new Promise(res => setTimeout(res, 1))

  const list = $('.navigation_list li')
  equal(SHORTCUTS.length, list.length)
  ok(
    SHORTCUTS.every(sc =>
      list.toArray().some(li => {
        const keycode = $(li).find('.keycode').text()
        const description = $(li).find('.description').text()
        return sc.keycode === keycode && sc.description === description
      })
    )
  )
  wrapper.unmount()
})
