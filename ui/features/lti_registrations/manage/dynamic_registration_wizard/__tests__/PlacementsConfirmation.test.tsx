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
import {mockRegistration} from './helpers'
import {type LtiConfiguration} from '../../model/lti_tool_configuration/LtiConfiguration'
import {PlacementsConfirmation} from '../components/PlacementsConfirmation'
import React from 'react'
import {createRegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import {type LtiPlacement, LtiPlacements, i18nLtiPlacement} from '../../model/LtiPlacement'

const makeConfig = (placements: LtiPlacement[]): Partial<LtiConfiguration> => {
  return {
    extensions: [
      {
        platform: 'canvas.instructure.com',
        settings: {
          text: '',
          placements: placements.map(placement => ({
            placement,
            message_type: 'LtiResourceLinkRequest',
          })),
        },
      },
    ],
  }
}

describe('PlacementsConfirmation', () => {
  it('renders the PlacementsConfirmation', () => {
    const config = makeConfig([LtiPlacements.AccountNavigation])
    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    expect(screen.getByText(i18nLtiPlacement(LtiPlacements.AccountNavigation))).toBeInTheDocument()
  })

  it("renders a helpful message if the tool doesn't provide placements", () => {
    const config = makeConfig([])
    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    expect(
      screen.getByText(/This tool has not requested access to any placements/i)
    ).toBeInTheDocument()
  })

  it("let's users toggle placements", async () => {
    const config = makeConfig([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.TopNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    const checkbox = screen.getByLabelText(i18nLtiPlacement(LtiPlacements.CourseNavigation))
    await userEvent.click(checkbox)

    expect(checkbox).not.toBeChecked()

    await userEvent.click(checkbox)

    expect(checkbox).toBeChecked()
  })

  it('renders a default disabled checkbox only for course navigation', () => {
    const config = makeConfig([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.RichTextEditor,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)
    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    const boxes = screen.getAllByText('Default to Hidden')
    expect(boxes.length).toBe(1)
  })

  it("renders the default disabled checkbox as on when the registration has default='disabled'", () => {
    const config = makeConfig([LtiPlacements.CourseNavigation])
    config.extensions![0].settings.placements[0].default = 'disabled'

    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    const box = screen.getByLabelText('Default to Hidden')

    expect(box).toBeChecked()
  })

  it("renders the default disabled checkbox as on when the overlay has default='disabled'", () => {
    const config = makeConfig([LtiPlacements.CourseNavigation])
    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().updatePlacement(LtiPlacements.CourseNavigation)(p => ({
      ...p,
      default: 'disabled',
    }))

    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    const box = screen.getByLabelText('Default to Hidden')

    expect(box).toBeChecked()
  })

  it('renders the default disabled checkbox as off when the overlay has default="enabled" but the registration has the opposite', () => {
    const config = makeConfig([LtiPlacements.CourseNavigation])
    config.extensions![0].settings.placements[0].default = 'disabled'

    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().updatePlacement(LtiPlacements.CourseNavigation)(p => ({
      ...p,
      default: 'enabled',
    }))

    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    const box = screen.getByLabelText('Default to Hidden')

    expect(box).not.toBeChecked()
  })

  it("doesn't render a default disabled checkbox when course navigation is disabled", () => {
    const config = makeConfig([LtiPlacements.CourseNavigation])
    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().toggleDisabledPlacement(LtiPlacements.CourseNavigation)
    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    const boxes = screen.queryAllByText('Default to Hidden')
    expect(boxes.length).toBe(0)
  })

  it('renders a checkbox for each placement in the configuration', () => {
    const placements = [
      LtiPlacements.CourseNavigation,
      LtiPlacements.AssignmentSelection,
      LtiPlacements.ContentArea,
    ]
    const config = makeConfig(placements)
    const reg = mockRegistration({}, config)
    const overlayStore = createRegistrationOverlayStore('Foo', reg)
    render(<PlacementsConfirmation registration={reg} overlayStore={overlayStore} />)

    // Assert that checkboxes for each placement are rendered
    for (const placement of placements) {
      expect(screen.getByText(i18nLtiPlacement(placement))).toBeInTheDocument()
    }
  })
})
