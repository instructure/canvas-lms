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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {mockConfigWithPlacements, mockRegistration} from './helpers'
import {PlacementsConfirmationWrapper} from '../components/PlacementsConfirmationWrapper'
import {UNDOCUMENTED_PLACEMENTS} from '../../registration_wizard_forms/PlacementsConfirmation'
import {createDynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import {LtiPlacements} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('PlacementsConfirmation', () => {
  afterEach(() => {
    cleanup()
  })

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

  describe('top navigation fullscreen functionality', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          top_navigation_placement: true,
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it("renders the allow fullscreen checkbox as on when the registration has allow_fullscreen='true'", () => {
      const config = mockConfigWithPlacements([LtiPlacements.TopNavigation])
      config.placements![0].allow_fullscreen = true

      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const box = screen.getByLabelText('Allow Fullscreen')
      expect(box).toBeChecked()
    })

    it("renders the allow fullscreen checkbox as on when the overlay has allow_fullscreen='true'", () => {
      const config = mockConfigWithPlacements([LtiPlacements.TopNavigation])
      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
      overlayStore.getState().updatePlacement(LtiPlacements.TopNavigation)(p => ({
        ...p,
        allow_fullscreen: true,
      }))
      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const box = screen.getByLabelText('Allow Fullscreen')
      expect(box).toBeChecked()
    })

    it('renders the allow fullscreen checkbox as off when the overlay has allow_fullscreen="false" but the registration has the opposite', () => {
      const config = mockConfigWithPlacements([LtiPlacements.TopNavigation])
      config.placements![0].allow_fullscreen = true

      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
      overlayStore.getState().updatePlacement(LtiPlacements.TopNavigation)(p => ({
        ...p,
        allow_fullscreen: false,
      }))

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const box = screen.getByLabelText('Allow Fullscreen')
      expect(box).not.toBeChecked()
    })

    it('renders the allow fullscreen checkbox as off when the registration has allow_fullscreen=false', () => {
      const config = mockConfigWithPlacements([LtiPlacements.TopNavigation])
      config.placements![0].allow_fullscreen = false

      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const box = screen.getByLabelText('Allow Fullscreen')
      expect(box).not.toBeChecked()
    })

    it('renders the allow fullscreen checkbox as off when no allow_fullscreen is set', () => {
      const config = mockConfigWithPlacements([LtiPlacements.TopNavigation])
      // Don't set allow_fullscreen - test the default/undefined case

      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const box = screen.getByLabelText('Allow Fullscreen')
      expect(box).not.toBeChecked()
    })

    it('allows users to toggle the allow fullscreen checkbox', async () => {
      const config = mockConfigWithPlacements([LtiPlacements.TopNavigation])
      config.placements![0].allow_fullscreen = true

      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const checkbox = screen.getByLabelText('Allow Fullscreen')
      expect(checkbox).toBeChecked()

      await userEvent.click(checkbox)
      expect(checkbox).not.toBeChecked()

      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })

    it("doesn't render allow fullscreen checkbox when top navigation is disabled", () => {
      const config = mockConfigWithPlacements([LtiPlacements.TopNavigation])
      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      overlayStore.getState().toggleDisabledPlacement(LtiPlacements.TopNavigation)

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const allowFullscreenCheckbox = screen.queryByLabelText('Allow Fullscreen')
      expect(allowFullscreenCheckbox).not.toBeInTheDocument()
    })

    it('renders allow fullscreen checkbox only for top navigation when multiple placements exist', () => {
      const config = mockConfigWithPlacements([
        LtiPlacements.TopNavigation,
        LtiPlacements.CourseNavigation,
        LtiPlacements.AccountNavigation,
        LtiPlacements.AssignmentSelection,
      ])

      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      const allowFullscreenCheckboxes = screen.getAllByLabelText('Allow Fullscreen')
      expect(allowFullscreenCheckboxes).toHaveLength(1)

      const defaultHiddenCheckboxes = screen.getAllByLabelText('Default to Hidden')
      expect(defaultHiddenCheckboxes).toHaveLength(1)

      expect(screen.getByText('Top Navigation')).toBeInTheDocument()
      expect(screen.getByText('Course Navigation')).toBeInTheDocument()
      expect(screen.getByText('Account Navigation')).toBeInTheDocument()
      expect(screen.getByText('Assignment Selection')).toBeInTheDocument()
    })
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

  describe('when top_navigation_placement feature flag is disabled', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          top_navigation_placement: false,
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('does not show top_navigation placement even if tool requested it', () => {
      const config = mockConfigWithPlacements([
        LtiPlacements.TopNavigation,
        LtiPlacements.CourseNavigation,
      ])
      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      // Top Navigation should not appear but Course Navigation should still appear
      expect(
        screen.queryByLabelText(i18nLtiPlacement(LtiPlacements.TopNavigation)),
      ).not.toBeInTheDocument()
      expect(
        screen.getByLabelText(i18nLtiPlacement(LtiPlacements.CourseNavigation)),
      ).toBeInTheDocument()
    })
  })

  describe('when top_navigation_placement feature flag is enabled', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          top_navigation_placement: true,
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('shows top_navigation placement when tool requests it', () => {
      const config = mockConfigWithPlacements([
        LtiPlacements.TopNavigation,
        LtiPlacements.CourseNavigation,
      ])
      const reg = mockRegistration({}, config)
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(<PlacementsConfirmationWrapper registration={reg} overlayStore={overlayStore} />)

      // Both placements should appear
      expect(
        screen.getByLabelText(i18nLtiPlacement(LtiPlacements.TopNavigation)),
      ).toBeInTheDocument()
      expect(
        screen.getByLabelText(i18nLtiPlacement(LtiPlacements.CourseNavigation)),
      ).toBeInTheDocument()
    })
  })
})
