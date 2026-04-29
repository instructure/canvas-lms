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
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {NamingConfirmation} from '../../registration_wizard_forms/NamingConfirmation'
import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import type {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {getDefaultPlacementTextFromConfig} from './helpers'
import {filterPlacementsByFeatureFlags} from '@canvas/lti/model/LtiPlacementFilter'
import {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'

export type NamingConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  registrationUpdateRequest?: LtiRegistrationUpdateRequest
  existingRegistration?: LtiRegistrationWithConfiguration
}

export const NamingConfirmationWrapper = ({
  overlayStore,
  internalConfig,
  registrationUpdateRequest,
  existingRegistration,
}: NamingConfirmationWrapperProps) => {
  const {state, ...actions} = overlayStore()

  const placements = filterPlacementsByFeatureFlags(state.placements.placements ?? []).map(p => ({
    placement: p,
    label: state.naming.placements[p] ?? '',
    defaultValue: getDefaultPlacementTextFromConfig(p, internalConfig),
  }))

  return (
    <RegistrationModalBody>
      <NamingConfirmation
        toolName={internalConfig.title}
        adminNickname={state.naming.nickname}
        onUpdateAdminNickname={actions.setAdminNickname}
        description={state.naming.description}
        descriptionPlaceholder={internalConfig.description ?? undefined}
        onUpdateDescription={actions.setDescription}
        placements={placements}
        onUpdatePlacementLabel={actions.setPlacementLabel}
        registrationUpdateRequest={registrationUpdateRequest}
        existingRegistration={existingRegistration}
      />
    </RegistrationModalBody>
  )
}
