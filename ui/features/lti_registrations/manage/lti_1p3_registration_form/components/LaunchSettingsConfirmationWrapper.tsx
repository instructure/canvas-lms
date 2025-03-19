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
import {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {
  getInputIdForField,
  validateLaunchSettings,
} from '../../registration_overlay/validateLti1p3RegistrationOverlayState'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {Footer} from '../../registration_wizard_forms/Footer'
import {LaunchSettingsConfirmation} from '../../registration_wizard_forms/LaunchSettingsConfirmation'

export type LaunchSettingsConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  reviewing: boolean
  onPreviousClicked: () => void
  onNextClicked: () => void
}
export const LaunchSettingsConfirmationWrapper = (
  props: LaunchSettingsConfirmationWrapperProps,
) => {
  const [hasClickedNext, setHasClickedNext] = React.useState(false)
  const onNextClicked = React.useCallback(() => {
    // if there are any errors, don't proceed
    const errors = validateLaunchSettings(props.overlayStore.getState().state.launchSettings)
    if (errors.length > 0) {
      document.getElementById(getInputIdForField(errors[0].field))?.focus()
      setHasClickedNext(true)
    } else {
      props.onNextClicked()
    }
  }, [props.onNextClicked, props.overlayStore])
  return (
    <>
      <RegistrationModalBody>
        <LaunchSettingsConfirmation {...props} hasClickedNext={hasClickedNext} />
      </RegistrationModalBody>
      <Footer
        currentScreen="first"
        reviewing={props.reviewing}
        onNextClicked={onNextClicked}
        onPreviousClicked={props.onPreviousClicked}
      ></Footer>
    </>
  )
}
