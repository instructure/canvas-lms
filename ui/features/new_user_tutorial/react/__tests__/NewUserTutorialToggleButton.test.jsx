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

import React from 'react'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import NewUserTutorialToggleButton from '../NewUserTutorialToggleButton'
import createTutorialStore from '../util/createTutorialStore'

describe('NewUserTutorialToggleButton Spec', () => {
  test('Defaults to expanded', () => {
    const store = createTutorialStore()
    const {getByRole} = render(<NewUserTutorialToggleButton store={store} />)
    // Test button has correct screen reader label for expanded state
    expect(getByRole('button', {name: /collapse tutorial tray/i})).toBeInTheDocument()
  })

  test('Toggles isCollapsed when clicked', async () => {
    const user = userEvent.setup()
    const store = createTutorialStore()
    const {getByRole} = render(<NewUserTutorialToggleButton store={store} />)

    const button = getByRole('button', {name: /collapse tutorial tray/i})
    await user.click(button)

    // After clicking, should show expand label (collapsed state)
    expect(getByRole('button', {name: /expand tutorial tray/i})).toBeInTheDocument()
  })

  test('shows correct label when isCollapsed is true', () => {
    const store = createTutorialStore({isCollapsed: true})
    const {getByRole} = render(<NewUserTutorialToggleButton store={store} />)
    expect(getByRole('button', {name: /expand tutorial tray/i})).toBeInTheDocument()
  })

  test('shows correct label when isCollapsed is false', () => {
    const store = createTutorialStore({isCollapsed: false})
    const {getByRole} = render(<NewUserTutorialToggleButton store={store} />)
    expect(getByRole('button', {name: /collapse tutorial tray/i})).toBeInTheDocument()
  })
})
