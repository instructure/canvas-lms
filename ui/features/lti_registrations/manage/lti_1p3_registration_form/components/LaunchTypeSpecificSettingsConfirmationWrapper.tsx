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

import React from 'react'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {LaunchTypeSpecificSettingsConfirmation} from '../../registration_wizard_forms/LaunchTypeSpecificSettingsConfirmation'
import {LtiPlacementlessMessageType} from '../../model/LtiMessageType'

export type LaunchTypeSpecificSettingsConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  settingType: LtiPlacementlessMessageType
}

export const LaunchTypeSpecificSettingsConfirmationWrapper = (
  props: LaunchTypeSpecificSettingsConfirmationWrapperProps,
) => {
  return (
    <>
      <RegistrationModalBody>
        <LaunchTypeSpecificSettingsConfirmation
          overlayStore={props.overlayStore}
          internalConfig={props.internalConfig}
          settingType={props.settingType}
        />
      </RegistrationModalBody>
    </>
  )
}
