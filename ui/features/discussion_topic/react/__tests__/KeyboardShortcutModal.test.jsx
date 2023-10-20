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

import KeyboardShortcutModal from '../KeyboardShortcutModal'
import {mount} from 'enzyme'
import React from 'react'

const waitForInstUIModalCssTransitions = () => new Promise(resolve => setTimeout(resolve, 1))

describe('KeyboardShortcutModal', () => {
  let component

  beforeEach(() => {
    component = mount(
      <KeyboardShortcutModal
        shortcuts={[
          {
            keycode: 'j',
            description: 'this is a test keyboard shortcut',
          },
        ]}
      />
    )
  })

  afterEach(() => {
    component.unmount()
  })

  test('appears when ALT + F8 is pressed', async () => {
    expect(document.querySelector('.keyboard_navigation')).toBeNull()
    const e = new Event('keydown')
    e.which = 119
    e.altKey = true
    document.dispatchEvent(e)

    await waitForInstUIModalCssTransitions()

    expect(document.querySelector('.keyboard_navigation')).toBeTruthy()
  })

  describe('shortcuts', () => {
    beforeEach(() => {
      const e = new Event('keydown')
      e.which = 119
      e.altKey = true
      document.dispatchEvent(e)
      return waitForInstUIModalCssTransitions()
    })

    test('renders shortcuts prop', () => {
      expect(document.querySelectorAll('.keyboard_navigation')).toHaveLength(1)
      expect(document.querySelector('.keycode').innerHTML).toBe('j')
      expect(document.querySelector('.description').innerHTML).toBe(
        'this is a test keyboard shortcut'
      )
    })
  })
})
