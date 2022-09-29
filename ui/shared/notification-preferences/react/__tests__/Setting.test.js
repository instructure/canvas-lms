/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import NotificationPreferencesSetting from '../Setting'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'

function defaultProps(overrides) {
  return {
    preferenceOptions: ['immediately', 'daily', 'weekly', 'never'],
    selectedPreference: 'immediately',
    updatePreference: jest.fn(),
    ...overrides,
  }
}

describe('Notification Preferences Setting', () => {
  it('calls the updatePreference callback on change', () => {
    const updatePreference = jest.fn()
    const props = defaultProps({updatePreference})

    const {getByRole, getByText} = render(<NotificationPreferencesSetting {...props} />)
    const button = getByRole('button')

    expect(updatePreference).not.toHaveBeenCalled()
    fireEvent.click(button)
    fireEvent.click(getByText('Daily summary'))
    expect(updatePreference).toHaveBeenCalledWith('daily')
  })

  it('updates the menu button on change', () => {
    const props = defaultProps()

    const {getByRole, getByText} = render(<NotificationPreferencesSetting {...props} />)
    const button = getByRole('button')

    expect(button).toHaveTextContent('Notify immediately')
    fireEvent.click(button)
    fireEvent.click(getByText('Daily summary'))
    expect(button).toHaveTextContent('Daily summary')
  })
})
