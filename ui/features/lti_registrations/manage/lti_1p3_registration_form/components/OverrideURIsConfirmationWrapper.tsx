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

import {useScope as createI18nScope} from '@canvas/i18n'
import {isValidHttpUrl} from '../../../common/lib/validators/isValidHttpUrl'
import {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {Footer} from '../../registration_wizard_forms/Footer'
import {OverrideURIsConfirmation} from '../../registration_wizard_forms/OverrideURIsConfirmation'
import {
  getInputIdForField,
  validateOverrideUris,
} from '../../registration_overlay/validateLti1p3RegistrationOverlayState'

const I18n = createI18nScope('lti_registration.wizard')

export type OverrideURIsConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  reviewing: boolean
  onNextClicked: () => void
  onPreviousClicked: () => void
}

export const OverrideURIsConfirmationWrapper = React.memo(
  ({
    overlayStore,
    internalConfig,
    reviewing,
    onNextClicked,
    onPreviousClicked,
  }: OverrideURIsConfirmationWrapperProps) => {
    const onNextClickedCb = React.useCallback(() => {
      // if there are any errors, don't proceed
      const errors = validateOverrideUris(overlayStore.getState().state.override_uris)
      if (errors.length > 0) {
        document.getElementById(getInputIdForField(errors[0].field))?.focus()
      } else {
        onNextClicked()
      }
    }, [onNextClicked, overlayStore])

    return (
      <>
        <RegistrationModalBody>
          <OverrideURIsConfirmation overlayStore={overlayStore} internalConfig={internalConfig} />
        </RegistrationModalBody>
        <Footer
          currentScreen="intermediate"
          reviewing={reviewing}
          onNextClicked={onNextClickedCb}
          onPreviousClicked={onPreviousClicked}
        />
      </>
    )
  },
)
