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
import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {LtiPrivacyLevels} from '../../model/LtiPrivacyLevel'
import {PrivacyConfirmation} from '../../registration_wizard_forms/PrivacyConfirmation'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'

export type PrivacyConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
}

export const PrivacyConfirmationWrapper = ({
  overlayStore,
  internalConfig,
}: PrivacyConfirmationWrapperProps) => {
  const {state, ...actions} = overlayStore()

  const value =
    state.data_sharing.privacy_level ?? internalConfig.privacy_level ?? LtiPrivacyLevels.Anonymous

  return (
    <RegistrationModalBody>
      <PrivacyConfirmation
        appName={internalConfig.title}
        privacyLevelOnChange={actions.setPrivacyLevel}
        selectedPrivacyLevel={value}
      />
    </RegistrationModalBody>
  )
}
