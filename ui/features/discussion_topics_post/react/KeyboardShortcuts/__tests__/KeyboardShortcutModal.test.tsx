/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

test('should open modal on key press', async () => {
  render(
    <KeyboardShortcutModal
      shortcuts={[
        {
          keycode: 'l',
          description: 'this is a test keyboard shortcut',
        },
      ]}
    />,
  )

  expect(document.querySelector('.keyboard_navigation')).not.toBeInTheDocument()
  const user = userEvent.setup()
  await user.keyboard('{Shift>}{?}{/Shift}')
  expect(document.querySelector('.keyboard_navigation')).toBeInTheDocument()
  expect(screen.getByText('l')).toBeInTheDocument()
  expect(screen.getByText('this is a test keyboard shortcut')).toBeInTheDocument()
})
