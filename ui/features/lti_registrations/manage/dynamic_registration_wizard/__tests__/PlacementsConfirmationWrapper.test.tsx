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
import {mockConfigWithPlacements, mockRegistration} from './helpers'
import {PlacementsConfirmationWrapper} from '../components/PlacementsConfirmationWrapper'
import {UNDOCUMENTED_PLACEMENTS} from '../../registration_wizard_forms/PlacementsConfirmation'
import {createDynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import {LtiPlacements} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'

describe('PlacementsConfirmation', () => {
  it('renders the PlacementsConfirmation', () => {
    const config = mockConfigWithPlacements([LtiPlacements.AccountNavigation])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    expect(screen.getByText(i18nLtiPlacement(LtiPlacements.AccountNavigation))).toBeInTheDocument()
  })

  it("renders a helpful message if the tool doesn't provide placements", () => {
    const config = mockConfigWithPlacements([])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    expect(
      screen.getByText(/This tool has not requested access to any placements/i),
    ).toBeInTheDocument()
  })

  it("doesn't render a tooltip for the undocumented placements", () => {
    const placements = mockConfigWithPlacements([
      ...UNDOCUMENTED_PLACEMENTS,
      LtiPlacements.CourseNavigation,
    ])

    const reg = mockRegistration({}, placements)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    UNDOCUMENTED_PLACEMENTS.forEach(placement => {
      expect(screen.queryByTestId(`placement-img-${placement}`)).not.toBeInTheDocument()
    })

    expect(
      screen.getByTestId(`placement-img-${LtiPlacements.CourseNavigation}`),
    ).toBeInTheDocument()
  })

  it('renders a tooltip for the placements', () => {
    const placements = [LtiPlacements.CourseNavigation, LtiPlacements.AccountNavigation]
    const config = mockConfigWithPlacements(placements)

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    placements.forEach(placement => {
      expect(screen.getByTestId(`placement-img-${placement}`)).toBeInTheDocument()
    })
  })

  it("doesn't show the analytics hub placement if the tool has not requested it", () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const checkbox = screen.queryByLabelText(i18nLtiPlacement(LtiPlacements.AnalyticsHub))
    expect(checkbox).toBeNull()
  })

  it('shows the analytics hub placement if the tool has requested it', () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AnalyticsHub,
      LtiPlacements.AccountNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const checkbox = screen.queryByLabelText(i18nLtiPlacement(LtiPlacements.AnalyticsHub))
    expect(checkbox).toBeTruthy()
    expect(screen.getByTestId(`placement-img-analytics_hub`)).toBeInTheDocument()
  })

  it("let's users toggle placements", async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.TopNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const checkbox = screen.getByLabelText(i18nLtiPlacement(LtiPlacements.CourseNavigation))
    await userEvent.click(checkbox)

    expect(checkbox).not.toBeChecked()

    await userEvent.click(checkbox)

    expect(checkbox).toBeChecked()
  })

  it('renders a default disabled checkbox only for course navigation', () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.AccountNavigation,
      LtiPlacements.EditorButton,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const boxes = screen.getAllByText('Default to Hidden')
    expect(boxes).toHaveLength(1)
  })

  it("renders the default disabled checkbox as on when the registration has default='disabled'", () => {
    const config = mockConfigWithPlacements([LtiPlacements.CourseNavigation])
    config.placements![0].default = 'disabled'

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const box = screen.getByLabelText('Default to Hidden')

    expect(box).toBeChecked()
  })

  it("renders the default disabled checkbox as on when the overlay has default='disabled'", () => {
    const config = mockConfigWithPlacements([LtiPlacements.CourseNavigation])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().updatePlacement(LtiPlacements.CourseNavigation)(p => ({
      ...p,
      default: 'disabled',
    }))

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const box = screen.getByLabelText('Default to Hidden')

    expect(box).toBeChecked()
  })

  it('renders the default disabled checkbox as off when the overlay has default="enabled" but the registration has the opposite', () => {
    const config = mockConfigWithPlacements([LtiPlacements.CourseNavigation])
    config.placements![0].default = 'disabled'

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().updatePlacement(LtiPlacements.CourseNavigation)(p => ({
      ...p,
      default: 'enabled',
    }))

    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const box = screen.getByLabelText('Default to Hidden')

    expect(box).not.toBeChecked()
  })

  it("doesn't render a default disabled checkbox when course navigation is disabled", () => {
    const config = mockConfigWithPlacements([LtiPlacements.CourseNavigation])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    overlayStore.getState().toggleDisabledPlacement(LtiPlacements.CourseNavigation)
    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    const boxes = screen.queryAllByText('Default to Hidden')
    expect(boxes).toHaveLength(0)
  })

  it('renders a checkbox for each placement in the configuration', () => {
    const placements = [
      LtiPlacements.CourseNavigation,
      LtiPlacements.AssignmentSelection,
      LtiPlacements.LinkSelection,
    ]
    const config = mockConfigWithPlacements(placements)
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

    // Assert that checkboxes for each placement are rendered
    for (const placement of placements) {
      expect(screen.getByText(i18nLtiPlacement(placement))).toBeInTheDocument()
    }
  })
})
