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
import {PlacementsConfirmationWrapper} from '../components/PlacementsConfirmationWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {AllLtiPlacements, InternalOnlyLtiPlacements} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import {UNDOCUMENTED_PLACEMENTS} from '../../registration_wizard_forms/PlacementsConfirmation'

describe('PlacementsConfirmationWrapper', () => {
  it('renders a checkbox for every available placement, minus internal-only placements', () => {
    const internalConfig = mockInternalConfiguration({placements: []})
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    window.ENV.FEATURES.lti_asset_processor = true

    render(
      <PlacementsConfirmationWrapper internalConfig={internalConfig} overlayStore={overlayStore} />,
    )

    expect(screen.queryByLabelText(/default to hidden/i)).not.toBeInTheDocument()
    expect(screen.getAllByRole('checkbox')).toHaveLength(
      AllLtiPlacements.length - InternalOnlyLtiPlacements.length,
    )
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
})
