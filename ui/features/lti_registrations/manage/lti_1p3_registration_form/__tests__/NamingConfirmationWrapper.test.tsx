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
import {NamingConfirmationWrapper} from '../components/NamingConfirmationWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import type {LtiPlacement} from '../../model/LtiPlacement'

describe('NamingConfirmationWrapper', () => {
  it('renders the NamingConfirmation', () => {
    const config = mockInternalConfiguration()
    const overlayStore = createLti1p3RegistrationOverlayStore(config, '')

    render(<NamingConfirmationWrapper internalConfig={config} overlayStore={overlayStore} />)

    expect(screen.getByText('Nickname')).toBeInTheDocument()
    expect(screen.getByText('Description')).toBeInTheDocument()
  })

  it('lets users change the nickname', async () => {
    const config = mockInternalConfiguration()
    const overlayStore = createLti1p3RegistrationOverlayStore(config, '')
    overlayStore.getState().setAdminNickname('Foo')

    render(<NamingConfirmationWrapper internalConfig={config} overlayStore={overlayStore} />)

    const input = screen.getByLabelText(/Administration Nickname/i)
    expect(input).toHaveValue('Foo')

    const newNickname = 'Bar'
    await userEvent.clear(input)
    await userEvent.type(input, newNickname)

    expect(input).toHaveValue(newNickname)
  })

  it('lets users change the description', async () => {
    const config = mockInternalConfiguration({description: 'Foo'})
    const overlayStore = createLti1p3RegistrationOverlayStore(config, '')

    overlayStore.getState().setDescription('Foo')

    render(<NamingConfirmationWrapper internalConfig={config} overlayStore={overlayStore} />)

    const input = screen.getByLabelText(/Choose a description/i)
    expect(input).toHaveValue('Foo')

    const newDescription = 'Bar'
    await userEvent.clear(input)
    await userEvent.type(input, newDescription)

    expect(input).toHaveValue(newDescription)
  })

  it('allows users to change the placement name of each placement in the registration', async () => {
    const placements = ['course_navigation', 'global_navigation'] as LtiPlacement[]
    const config = mockInternalConfiguration({
      placements: [{placement: 'course_navigation'}, {placement: 'global_navigation'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(config, '')

    render(<NamingConfirmationWrapper internalConfig={config} overlayStore={overlayStore} />)

    for (const placement of placements) {
      const el = screen.getByLabelText(new RegExp(i18nLtiPlacement(placement)))
      expect(el).toBeInTheDocument()
      // Defaults to the configuration's launch setting's text
      expect(el).toHaveAttribute('placeholder', 'Default Title')

      await userEvent.clear(el)

      await userEvent.type(el, 'New Name')
      expect(el).toHaveValue('New Name')
    }
  })

  it('adds a new input when a new placement is added to the overlay', () => {
    const config = mockInternalConfiguration({
      placements: [{placement: 'course_navigation'}, {placement: 'global_navigation'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(config, '')

    render(<NamingConfirmationWrapper internalConfig={config} overlayStore={overlayStore} />)

    expect(screen.queryByLabelText(i18nLtiPlacement('top_navigation'))).not.toBeInTheDocument()

    overlayStore.getState().togglePlacement('top_navigation')

    expect(screen.getByLabelText(i18nLtiPlacement('top_navigation'))).toBeInTheDocument()
  })
})
