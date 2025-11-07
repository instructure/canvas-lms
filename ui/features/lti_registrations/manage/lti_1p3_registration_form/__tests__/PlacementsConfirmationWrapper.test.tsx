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
import {PlacementsConfirmationWrapper} from '../components/PlacementsConfirmationWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {AllLtiPlacements, InternalOnlyLtiPlacements} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('PlacementsConfirmationWrapper', () => {
  describe('when lti_asset_processor and lti_asset_processor_discussions are enabled', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          lti_asset_processor: true,
          lti_asset_processor_discussions: true,
          top_navigation_placement: true,
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('renders a checkbox for every available placement, minus internal-only placements', () => {
      const internalConfig = mockInternalConfiguration({placements: []})
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      expect(screen.queryByLabelText(/default to hidden/i)).not.toBeInTheDocument()
      expect(screen.getAllByRole('checkbox')).toHaveLength(
        AllLtiPlacements.length - InternalOnlyLtiPlacements.length,
      )
    })
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

    it('does not show top_navigation placement in available placements', () => {
      const internalConfig = mockInternalConfiguration({placements: []})
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      expect(screen.queryByLabelText(i18nLtiPlacement('top_navigation'))).not.toBeInTheDocument()
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

    it('shows top_navigation placement in available placements', () => {
      const internalConfig = mockInternalConfiguration({placements: []})
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      expect(screen.getByLabelText(i18nLtiPlacement('top_navigation'))).toBeInTheDocument()
    })
  })

  it('marks placements as enabled according to the internal configuration', () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: 'course_navigation'}, {placement: 'global_navigation'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PlacementsConfirmationWrapper internalConfig={internalConfig} overlayStore={overlayStore} />,
    )

    expect(screen.getByLabelText(i18nLtiPlacement('course_navigation'))).toBeChecked()
    expect(screen.getByLabelText(i18nLtiPlacement('global_navigation'))).toBeChecked()
    expect(screen.getByLabelText(i18nLtiPlacement('account_navigation'))).not.toBeChecked()
  })

  it('allows users to toggle placements on and off', async () => {
    const user = userEvent.setup()
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: 'course_navigation'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PlacementsConfirmationWrapper internalConfig={internalConfig} overlayStore={overlayStore} />,
    )

    const courseNavCheckbox = screen.getByLabelText(i18nLtiPlacement('course_navigation'))
    expect(courseNavCheckbox).toBeChecked()

    await user.click(courseNavCheckbox)
    expect(courseNavCheckbox).not.toBeChecked()
  })

  it("renders a 'Default to Hidden' sub-checkbox for the Course Navigation placement when it's enabled", () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: 'course_navigation'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PlacementsConfirmationWrapper internalConfig={internalConfig} overlayStore={overlayStore} />,
    )

    const defaultHiddenCheckbox = screen.getByLabelText(/default to hidden/i)
    expect(defaultHiddenCheckbox).toBeInTheDocument()
  })

  it("doesn't render a 'Default to Hidden' checkbox if the Course Nav placement is disabled", () => {
    const internalConfig = mockInternalConfiguration({
      placements: [],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PlacementsConfirmationWrapper internalConfig={internalConfig} overlayStore={overlayStore} />,
    )

    expect(screen.queryByLabelText(/default to hidden/i)).not.toBeInTheDocument()
  })

  it("maintains the state of the 'Default to Hidden' checkbox through enabling/disabling", async () => {
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: 'course_navigation'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PlacementsConfirmationWrapper internalConfig={internalConfig} overlayStore={overlayStore} />,
    )

    const courseNavCheckbox = screen.getByLabelText(i18nLtiPlacement('course_navigation'))
    const defaultHiddenCheckbox = screen.getByLabelText(/default to hidden/i)

    expect(defaultHiddenCheckbox).not.toBeChecked()

    await userEvent.click(defaultHiddenCheckbox)
    expect(defaultHiddenCheckbox).toBeChecked()

    await userEvent.click(courseNavCheckbox)
    expect(courseNavCheckbox).not.toBeChecked()
    expect(screen.queryByLabelText(/default to hidden/i)).not.toBeInTheDocument()

    await userEvent.click(courseNavCheckbox)
    expect(courseNavCheckbox).toBeChecked()

    expect(screen.getByLabelText(/default to hidden/i)).toBeChecked()
  })

  it('allows users to toggle the "Default to Hidden" checkbox for the Course Navigation placement', async () => {
    const user = userEvent.setup()
    const internalConfig = mockInternalConfiguration({
      placements: [{placement: 'course_navigation'}],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <PlacementsConfirmationWrapper internalConfig={internalConfig} overlayStore={overlayStore} />,
    )

    const defaultHiddenCheckbox = screen.getByLabelText(/default to hidden/i)
    expect(defaultHiddenCheckbox).not.toBeChecked()

    await user.click(defaultHiddenCheckbox)
    expect(defaultHiddenCheckbox).toBeChecked()
  })

  describe('when the increased_top_nav_pane_size FF is enabled', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          increased_top_nav_pane_size: true,
          top_navigation_placement: true,
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it("doesn't render allow fullscreen checkbox when no top navigation placement is present", () => {
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: 'course_navigation'}, {placement: 'account_navigation'}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      // Should not find Allow Fullscreen checkbox since no top_navigation placement
      const allowFullscreenCheckbox = screen.queryByLabelText('Allow Fullscreen')
      expect(allowFullscreenCheckbox).not.toBeInTheDocument()

      // But should find the other placements
      expect(screen.getByLabelText(i18nLtiPlacement('course_navigation'))).toBeInTheDocument()
      expect(screen.getByLabelText(i18nLtiPlacement('account_navigation'))).toBeInTheDocument()
    })

    it("renders an 'Allow Fullscreen' sub-checkbox for the Top Navigation placement when it's enabled", () => {
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: 'top_navigation'}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      const allowFullscreenCheckbox = screen.getByLabelText('Allow Fullscreen')
      expect(allowFullscreenCheckbox).toBeInTheDocument()
      expect(allowFullscreenCheckbox).not.toBeChecked()
    })

    it('allows users to toggle the "Allow Fullscreen" checkbox for the Top Navigation placement', async () => {
      const user = userEvent.setup()
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: 'top_navigation'}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      const allowFullscreenCheckbox = screen.getByLabelText('Allow Fullscreen')
      expect(allowFullscreenCheckbox).not.toBeChecked()

      await user.click(allowFullscreenCheckbox)
      expect(allowFullscreenCheckbox).toBeChecked()

      await user.click(allowFullscreenCheckbox)
      expect(allowFullscreenCheckbox).not.toBeChecked()
    })

    it("doesn't render an 'Allow Fullscreen' checkbox if the Top Navigation placement is disabled", async () => {
      const user = userEvent.setup()
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: 'top_navigation'}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      // Initially should have the Allow Fullscreen checkbox
      expect(screen.getByLabelText('Allow Fullscreen')).toBeInTheDocument()

      // Disable top navigation placement
      const topNavCheckbox = screen.getByLabelText(i18nLtiPlacement('top_navigation'))
      await user.click(topNavCheckbox)

      // Allow Fullscreen checkbox should disappear
      expect(screen.queryByLabelText('Allow Fullscreen')).not.toBeInTheDocument()
    })

    it("maintains the state of the 'Allow Fullscreen' checkbox through enabling/disabling", async () => {
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: 'top_navigation'}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      const topNavCheckbox = screen.getByLabelText(i18nLtiPlacement('top_navigation'))
      const allowFullscreenCheckbox = screen.getByLabelText('Allow Fullscreen')

      expect(allowFullscreenCheckbox).not.toBeChecked()

      // Enable Allow Fullscreen
      await userEvent.click(allowFullscreenCheckbox)
      expect(allowFullscreenCheckbox).toBeChecked()

      // Disable Top Navigation placement
      await userEvent.click(topNavCheckbox)
      expect(topNavCheckbox).not.toBeChecked()
      expect(screen.queryByLabelText('Allow Fullscreen')).not.toBeInTheDocument()

      // Re-enable Top Navigation placement
      await userEvent.click(topNavCheckbox)
      expect(topNavCheckbox).toBeChecked()

      // Allow Fullscreen checkbox should reappear and maintain its checked state
      expect(screen.getByLabelText('Allow Fullscreen')).toBeChecked()
    })

    it('renders allow fullscreen checkbox only for top navigation when multiple placements exist', () => {
      const internalConfig = mockInternalConfiguration({
        placements: [
          {placement: 'top_navigation'},
          {placement: 'course_navigation'},
          {placement: 'account_navigation'},
          {placement: 'assignment_selection'},
        ],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <PlacementsConfirmationWrapper
          internalConfig={internalConfig}
          overlayStore={overlayStore}
        />,
      )

      // Should find exactly one Allow Fullscreen checkbox (for TopNavigation)
      const allowFullscreenCheckboxes = screen.getAllByLabelText('Allow Fullscreen')
      expect(allowFullscreenCheckboxes).toHaveLength(1)

      // Should find exactly one Default to Hidden checkbox (for CourseNavigation)
      const defaultHiddenCheckboxes = screen.getAllByLabelText(/default to hidden/i)
      expect(defaultHiddenCheckboxes).toHaveLength(1)

      // All placements should be rendered and enabled
      expect(screen.getByLabelText(i18nLtiPlacement('top_navigation'))).toBeChecked()
      expect(screen.getByLabelText(i18nLtiPlacement('course_navigation'))).toBeChecked()
      expect(screen.getByLabelText(i18nLtiPlacement('account_navigation'))).toBeChecked()
      expect(screen.getByLabelText(i18nLtiPlacement('assignment_selection'))).toBeChecked()
    })
  })
})
