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
import {NamingConfirmation} from '../components/NamingConfirmation'
import {mockConfigWithPlacements, mockRegistration} from './helpers'
import {createRegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import userEvent from '@testing-library/user-event'
import {LtiPlacements, i18nLtiPlacement} from '../../model/LtiPlacement'

describe('NamingConfirmation', () => {
  it('renders the NamingConfirmation', () => {
    const reg = mockRegistration()
    const overlayStore = createRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmation registration={reg} overlayStore={overlayStore} />)

    expect(screen.getByText('Nickname')).toBeInTheDocument()
    expect(screen.getByText('Description')).toBeInTheDocument()
  })

  it("let's users change the nickname", async () => {
    const reg = mockRegistration()
    const overlayStore = createRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().updateAdminNickname('Foo')

    render(<NamingConfirmation registration={reg} overlayStore={overlayStore} />)

    const input = screen.getByLabelText(/Administration Nickname/i)
    expect(input).toHaveValue('Foo')

    const newNickname = 'Bar'
    await userEvent.clear(input)
    await userEvent.type(input, newNickname)

    expect(input).toHaveValue(newNickname)
  })

  it("lets's users change the description", async () => {
    const reg = mockRegistration(
      {
        lti_tool_configuration: {
          description: 'Foo',
          claims: [],
          domain: 'test.com',
          messages: [],
          target_link_uri: 'test.com',
        },
      },
      {
        description: 'Foo',
      }
    )
    const overlayStore = createRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmation registration={reg} overlayStore={overlayStore} />)

    const input = screen.getByLabelText(/Choose a description/i)
    expect(input).toHaveValue('Foo')

    const newDescription = 'Bar'
    await userEvent.clear(input)
    await userEvent.type(input, newDescription)

    expect(input).toHaveValue(newDescription)
  })

  it('allows users to change the placement name of each placement in the registration', async () => {
    const placements = [
      LtiPlacements.CourseAssignmentsMenu,
      LtiPlacements.CourseNavigation,
      LtiPlacements.ModuleMenu,
    ]
    const config = mockConfigWithPlacements(placements)
    const reg = mockRegistration(
      {
        client_name: 'A Great Little Name',
      },
      config
    )
    const overlayStore = createRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmation registration={reg} overlayStore={overlayStore} />)

    for (const placement of placements) {
      const el = screen.getByLabelText(i18nLtiPlacement(placement))
      expect(el).toBeInTheDocument()
      expect(el).toHaveValue('')
      // eslint-disable-next-line no-await-in-loop
      await userEvent.clear(el)
      // eslint-disable-next-line no-await-in-loop
      await userEvent.type(el, 'New Name')

      expect(el).toHaveValue('New Name')
    }
  })
})
