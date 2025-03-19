/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {AllLtiScopes} from '@canvas/lti/model/LtiScope'
import * as React from 'react'
import {AllLtiPlacements} from '../../../../manage/model/LtiPlacement'
import {PlacementsConfirmation} from '../../../../manage/registration_wizard_forms/PlacementsConfirmation'
import {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {Lti1p3RegistrationOverlayStore} from '../../../registration_overlay/Lti1p3RegistrationOverlayStore'

const I18n = createI18nScope('lti_registrations')

type PlacementsConfirmationPerfWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  registration: LtiRegistrationWithAllInformation
  showAllSettings: boolean
}

/**
 * A wrapper around the PlacementConfirmation component that uses the
 * Lti1p3RegistrationOverlayStore to manage the state of the
 * Placements.
 *
 * This perf wrapper is used to avoid re-rendering the entire form.
 *
 * Once the DynamicRegistrationWizard is refactored to use the
 * Lti1p3RegistrationOverlayStore, these optimizations can be moved
 * into the PlacementConfirmation component itself, and this
 * wrapper can be removed.
 * @param param0
 * @returns
 */
export const PlacementsConfirmationPerfWrapper = React.memo(
  ({overlayStore, registration, showAllSettings}: PlacementsConfirmationPerfWrapperProps) => {
    const {
      courseNavigationDefaultHidden,
      onTogglePlacement,
      onToggleDefaultDisabled,
      enabledPlacements,
    } = overlayStore(s => ({
      courseNavigationDefaultHidden: s.state.placements.courseNavigationDefaultDisabled || false,
      onTogglePlacement: s.togglePlacement,
      onToggleDefaultDisabled: s.toggleCourseNavigationDefaultDisabled,
      enabledPlacements: s.state.placements.placements || [],
    }))

    /**
     * The possible placements that an admin can choose from.
     */
    const possiblePlacements = React.useMemo(
      () =>
        showAllSettings
          ? AllLtiPlacements
          : registration.configuration.placements.map(p => p.placement),
      [registration.configuration.placements],
    )

    return (
      <PlacementsConfirmation
        appName={registration.name}
        availablePlacements={possiblePlacements}
        courseNavigationDefaultHidden={courseNavigationDefaultHidden}
        enabledPlacements={enabledPlacements}
        onToggleDefaultDisabled={onToggleDefaultDisabled}
        onTogglePlacement={onTogglePlacement}
      />
    )
  },
)
