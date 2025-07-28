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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {PrivacyConfirmationWrapper} from '../components/PrivacyConfirmationWrapper'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {mockInternalConfiguration} from './helpers'
import {LtiPrivacyLevels} from '../../model/LtiPrivacyLevel'
import {i18nLtiPrivacyLevel} from '../../model/i18nLtiPrivacyLevel'

describe('PrivacyConfirmationWrapper', () => {
  it('renders the PrivacyConfirmation component with the correct props', () => {
    const internalConfig = mockInternalConfiguration({title: 'Test App'})
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PrivacyConfirmationWrapper overlayStore={overlayStore} internalConfig={internalConfig} />,
    )

    expect(screen.getByText(/Data Sharing/i)).toBeInTheDocument()
    expect(screen.getByText(/Test App/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/User Data Shared With This App/i)).toBeInTheDocument()
  })

  it('displays the correct initial privacy level', () => {
    const internalConfig = mockInternalConfiguration()
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PrivacyConfirmationWrapper overlayStore={overlayStore} internalConfig={internalConfig} />,
    )

    const select = screen.getByLabelText(/User Data Shared With This App/i)
    expect(select).toHaveValue(i18nLtiPrivacyLevel(LtiPrivacyLevels.Anonymous))
  })

  it('updates the privacy level when a new option is selected', async () => {
    const internalConfig = mockInternalConfiguration()
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PrivacyConfirmationWrapper overlayStore={overlayStore} internalConfig={internalConfig} />,
    )

    const select = screen.getByLabelText(/User Data Shared With This App/i)
    await userEvent.click(select)
    await userEvent.click(screen.getByText(i18nLtiPrivacyLevel(LtiPrivacyLevels.NameOnly)))

    expect(overlayStore.getState().state.data_sharing.privacy_level).toBe(LtiPrivacyLevels.NameOnly)
    expect(select).toHaveValue(i18nLtiPrivacyLevel(LtiPrivacyLevels.NameOnly))
  })
})
