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

import {AllLtiScopes} from '@canvas/lti/model/LtiScope'
import * as React from 'react'
import {getDefaultPlacementTextFromConfig} from '../../../../manage/lti_1p3_registration_form/components/helpers'
import {NamingConfirmation} from '../../../../manage/registration_wizard_forms/NamingConfirmation'
import {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {Lti1p3RegistrationOverlayStore} from '../../../registration_overlay/Lti1p3RegistrationOverlayStore'

type NamingConfirmationPerfWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  registration: LtiRegistrationWithAllInformation
  showAllSettings: boolean
}

/**
 * A wrapper around the NamingConfirmation component that uses the
 * Lti1p3RegistrationOverlayStore to manage the state of the
 * Namings.
 *
 * This perf wrapper is used to avoid re-rendering the entire form.
 *
 * Once the DynamicRegistrationWizard is refactored to use the
 * Lti1p3RegistrationOverlayStore, these optimizations can be moved
 * into the NamingConfirmation component itself, and this
 * wrapper can be removed.
 * @param param0
 * @returns
 */
export const NamingConfirmationPerfWrapper = React.memo(
  ({overlayStore, registration, showAllSettings}: NamingConfirmationPerfWrapperProps) => {
    const {
      onUpdateAdminNickname,
      onUpdateDescription,
      onUpdatePlacementLabel,
      selectedPlacements,
      placementNames,
      adminNickname,
      description,
      descriptionPlaceholder,
    } = overlayStore(({state, ...actions}) => ({
      onUpdateAdminNickname: actions.setAdminNickname,
      onUpdateDescription: actions.setDescription,
      onUpdatePlacementLabel: actions.setPlacementLabel,
      selectedPlacements: state.placements.placements || [],
      placementNames: state.naming.placements,
      adminNickname: state.naming.nickname ?? '',
      description: state.naming.description ?? '',
      descriptionPlaceholder: registration.configuration.description ?? undefined,
    }))

    const placements = React.useMemo(
      () =>
        selectedPlacements.map(p => ({
          placement: p,
          label: placementNames[p] ?? '',
          defaultValue: getDefaultPlacementTextFromConfig(p, registration.configuration),
        })),
      [registration.configuration, selectedPlacements, placementNames],
    )

    return (
      <NamingConfirmation
        onUpdateAdminNickname={onUpdateAdminNickname}
        onUpdateDescription={onUpdateDescription}
        onUpdatePlacementLabel={onUpdatePlacementLabel}
        placements={placements}
        toolName={registration.name}
        adminNickname={adminNickname}
        description={description}
        descriptionPlaceholder={descriptionPlaceholder}
      />
    )
  },
)
