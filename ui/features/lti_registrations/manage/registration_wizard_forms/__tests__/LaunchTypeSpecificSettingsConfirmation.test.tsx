/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {LaunchTypeSpecificSettingsConfirmation} from '../LaunchTypeSpecificSettingsConfirmation'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {mockConfiguration} from '../../pages/tool_details/configuration/__tests__/helpers'

const mockInternalConfig = mockConfiguration({
  launch_settings: {
    message_settings: [
      {
        type: 'LtiEulaRequest',
        enabled: true,
        target_link_uri: 'https://example.com/eula',
        custom_fields: {
          eula_field1: 'value1',
          eula_field2: 'value2',
        },
      },
    ],
  },
})

const mockStore = createLti1p3RegistrationOverlayStore(
  mockInternalConfig,
  'Test Admin Nickname',
  undefined,
)

describe('LaunchTypeSpecificSettingsConfirmation', () => {
  it('should render EULA settings title and enable checkbox', () => {
    const {getByText, getByLabelText} = render(
      <LaunchTypeSpecificSettingsConfirmation
        overlayStore={mockStore}
        internalConfig={mockInternalConfig}
        settingType="LtiEulaRequest"
      />,
    )

    expect(getByText('EULA Settings')).toBeInTheDocument()
    expect(getByLabelText('Enable EULA Request')).toBeInTheDocument()
  })

  it('should render with default disabled state when no existing settings', () => {
    const emptyStore = createLti1p3RegistrationOverlayStore(
      mockConfiguration({}),
      'Test Admin Nickname',
      undefined,
    )

    const {getByLabelText, queryByLabelText} = render(
      <LaunchTypeSpecificSettingsConfirmation
        overlayStore={emptyStore}
        internalConfig={mockConfiguration({})}
        settingType="LtiEulaRequest"
      />,
    )

    const checkbox = getByLabelText('Enable EULA Request') as HTMLInputElement
    expect(checkbox.checked).toBe(false)
    expect(queryByLabelText('EULA Target Link URI')).not.toBeInTheDocument()
    expect(queryByLabelText('EULA Custom Fields')).not.toBeInTheDocument()
  })

  it('should toggle target link URI and custom fields when checkbox is clicked', async () => {
    const user = userEvent.setup()
    const emptyStore = createLti1p3RegistrationOverlayStore(
      mockConfiguration({}),
      'Test Admin Nickname',
      undefined,
    )

    const {getByLabelText, queryByLabelText, queryByText} = render(
      <LaunchTypeSpecificSettingsConfirmation
        overlayStore={emptyStore}
        internalConfig={mockConfiguration({})}
        settingType="LtiEulaRequest"
      />,
    )

    const checkbox = getByLabelText('Enable EULA Request')

    // Initially fields should be hidden
    expect(queryByLabelText('EULA Target Link URI')).not.toBeInTheDocument()
    expect(queryByLabelText('EULA Custom Fields')).not.toBeInTheDocument()

    // Click to enable
    await user.click(checkbox)

    // Now fields should be visible
    expect(getByLabelText('EULA Target Link URI')).toBeInTheDocument()
    expect(getByLabelText('EULA Custom Fields')).toBeInTheDocument()
    expect(queryByText('Format: key=value, one per line')).toBeInTheDocument()
  })

  it('should allow updating target link URI when enabled', async () => {
    const user = userEvent.setup()
    const emptyStore = createLti1p3RegistrationOverlayStore(
      mockConfiguration({}),
      'Test Admin Nickname',
      undefined,
    )

    const {getByLabelText} = render(
      <LaunchTypeSpecificSettingsConfirmation
        overlayStore={emptyStore}
        internalConfig={mockConfiguration({})}
        settingType="LtiEulaRequest"
      />,
    )

    // Enable first
    const checkbox = getByLabelText('Enable EULA Request')
    await user.click(checkbox)

    // Then update the input
    const input = getByLabelText('EULA Target Link URI') as HTMLInputElement
    await user.type(input, 'https://example.com/new-eula')

    expect(input.value).toBe('https://example.com/new-eula')
  })
})
