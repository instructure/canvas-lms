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
import {NamingConfirmationWrapper} from '../components/NamingConfirmationWrapper'
import {
  mockConfigWithPlacements,
  mockRegistration,
  mockToolConfiguration,
  mockOverlay,
} from './helpers'
import {createDynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import userEvent from '@testing-library/user-event'
import {LtiPlacements} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'

describe('NamingConfirmation', () => {
  it('renders the NamingConfirmation', () => {
    const reg = mockRegistration()
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    expect(screen.getByText('Nickname')).toBeInTheDocument()
    expect(screen.getByText('Description')).toBeInTheDocument()
  })

  it("let's users change the nickname", async () => {
    const reg = mockRegistration()
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().updateAdminNickname('Foo')

    render(<NamingConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const input = screen.getByLabelText(/Administration Nickname/i)
    expect(input).toHaveValue('Foo')

    const newNickname = 'Bar'
    await userEvent.clear(input)
    await userEvent.type(input, newNickname)

    expect(input).toHaveValue(newNickname)
  })

  it("lets's users change the description", async () => {
    const reg = mockRegistration({
      configuration: mockToolConfiguration({description: 'Foo'}),
    })
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const input = screen.getByLabelText(/Choose a description/i)
    expect(input).toHaveValue('Foo')

    const newDescription = 'Bar'
    await userEvent.clear(input)
    await userEvent.type(input, newDescription)

    expect(input).toHaveValue(newDescription)
  })

  it('renders the nickname from the registration if it exists', () => {
    const reg = mockRegistration({
      admin_nickname: 'Foo',
    })
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    expect(screen.getByLabelText(/Administration Nickname/i)).toHaveValue('Foo')
  })

  it('renders the description from the overlay if it exists', () => {
    const reg = mockRegistration({
      overlay: mockOverlay({
        data: {
          description: 'Bar',
        },
      }),
    })
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    expect(screen.getByLabelText(/Choose a description/i)).toHaveValue('Bar')
  })

  it('excludes disabled placements', () => {
    const placements = [
      LtiPlacements.CourseAssignmentsMenu,
      LtiPlacements.CourseNavigation,
      LtiPlacements.ModuleMenu,
    ]

    const config = mockConfigWithPlacements(placements)
    const reg = mockRegistration(
      {
        name: 'A Great Little Name',
      },
      config,
    )

    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    overlayStore.getState().toggleDisabledPlacement(LtiPlacements.CourseAssignmentsMenu)

    render(<NamingConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    expect(
      screen.queryByLabelText(i18nLtiPlacement(LtiPlacements.CourseAssignmentsMenu)),
    ).not.toBeInTheDocument()
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
        name: 'A Great Little Name',
      },
      config,
    )
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<NamingConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    for (const placement of placements) {
      const el = screen.getByLabelText(i18nLtiPlacement(placement))
      expect(el).toBeInTheDocument()
      expect(el).toHaveValue('')

      await userEvent.clear(el)

      await userEvent.type(el, 'New Name')

      expect(el).toHaveValue('New Name')
    }
  })
})
