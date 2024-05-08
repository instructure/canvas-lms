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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'

const waitForInstUIModalCssTransitions = () => new Promise(resolve => setTimeout(resolve, 1))

describe('KeyboardShortcutModal', () => {
  beforeEach(() => {
    userEvent.setup()
  })
  test('appears when ALT + F8 is pressed', async () => {
    render(
      <KeyboardShortcutModal
        shortcuts={[
          {
            keycode: 'j',
            description: 'this is a test keyboard shortcut',
          },
        ]}
      />
    )

    expect(document.querySelector('.keyboard_navigation')).not.toBeInTheDocument()
    const e = new Event('keydown')
    e.which = 119
    e.altKey = true
    document.dispatchEvent(e)

    await waitForInstUIModalCssTransitions()

    expect(document.querySelectorAll('.keyboard_navigation')).toHaveLength(1)
    expect(screen.getByText('j')).toBeInTheDocument()
    expect(screen.getByText('this is a test keyboard shortcut')).toBeInTheDocument()
  })
})
