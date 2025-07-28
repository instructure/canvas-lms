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
import {PrivacyConfirmation} from '../../../../manage/registration_wizard_forms/PrivacyConfirmation'
import {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {Lti1p3RegistrationOverlayStore} from '../../../registration_overlay/Lti1p3RegistrationOverlayStore'
import React from 'react'

type PrivacyConfirmationPerfWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  registration: LtiRegistrationWithAllInformation
}

/**
 * A wrapper around the PrivacyConfirmation component that uses the
 * Lti1p3RegistrationOverlayStore to manage the state of the
 * Privacy controls.
 *
 * This perf wrapper is used to avoid re-rendering the entire form.
 *
 * Once the DynamicRegistrationWizard is refactored to use the
 * Lti1p3RegistrationOverlayStore, these optimizations can be moved
 * into the PrivacyConfirmation component itself, and this
 * wrapper can be removed.
 * @param param0
 * @returns
 */
export const PrivacyConfirmationPerfWrapper = React.memo(
  ({overlayStore, registration}: PrivacyConfirmationPerfWrapperProps) => {
    const {selectedPrivacyLevel, privacyLevelOnChange} = overlayStore(s => ({
      selectedPrivacyLevel: s.state.data_sharing.privacy_level || 'anonymous',
      privacyLevelOnChange: s.setPrivacyLevel,
    }))
    return (
      <PrivacyConfirmation
        appName={registration.name}
        selectedPrivacyLevel={selectedPrivacyLevel}
        privacyLevelOnChange={privacyLevelOnChange}
      />
    )
  },
)
