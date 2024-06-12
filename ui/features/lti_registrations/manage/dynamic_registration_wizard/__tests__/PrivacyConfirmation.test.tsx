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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import {PrivacyConfirmation, type PrivacyConfirmationProps} from '../components/PrivacyConfirmation'
import {createRegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import {mockRegistration} from './helpers'
import React from 'react'
import {
  type LtiPrivacyLevel,
  i18nLtiPrivacyLevel,
  i18nLtiPrivacyLevelDescription,
} from '../../model/LtiPrivacyLevel'

const mockProps = ({
  toolName = 'Tool Name',
  privacyLevel,
}: {
  toolName?: string
  privacyLevel?: LtiPrivacyLevel
}): PrivacyConfirmationProps => ({
  toolName,
  overlayStore: createRegistrationOverlayStore(
    toolName,
    mockRegistration(
      {},
      {
        extensions: [
          {
            platform: 'canvas.instructure.com',
            settings: {
              placements: [],
              text: '',
            },
            privacy_level: privacyLevel,
          },
        ],
      }
    )
  ),
})

describe('PrivacyConfirmation', () => {
  it('renders the privacy confirmation', () => {
    render(<PrivacyConfirmation {...mockProps({})} />)
    expect(screen.getByText('Data Sharing')).toBeInTheDocument()
  })

  it("let's the user select a privacy level", async () => {
    const props = mockProps({privacyLevel: 'public'})
    render(<PrivacyConfirmation {...props} />)
    expect(screen.getByLabelText(/User Data Shared With This App/i)).toHaveValue(
      i18nLtiPrivacyLevel('public')
    )

    await userEvent.click(screen.getByLabelText(/User Data Shared With This App/i))
    await userEvent.click(screen.getByText(i18nLtiPrivacyLevel('anonymous')))

    expect(screen.getByLabelText(/User Data Shared With This App/i)).toHaveValue(
      i18nLtiPrivacyLevel('anonymous')
    )
  })

  it('renders a description of what information is included', () => {
    render(<PrivacyConfirmation {...mockProps({privacyLevel: 'public'})} />)

    expect(screen.getByText(i18nLtiPrivacyLevelDescription('public'))).toBeInTheDocument()
  })
})
