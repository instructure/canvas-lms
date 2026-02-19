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

import React, {useCallback} from 'react'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AccountId} from '../model/AccountId'
import {useRegistrationUpdateWizardModalState} from './RegistrationUpdateWizardModalState'
import {RegistrationUpdateWizard} from './RegistrationUpdateWizard'
import {ResponsiveWrapper} from '../registration_wizard_forms/ResponsiveWrapper'

const I18n = createI18nScope('lti_registrations')

export interface RegistrationUpdateWizardModalProps {
  accountId: AccountId
}

/**
 * This is the Registration Update wizard modal that is used to update an LTI registration.
 * To open it, call the `open` function from the useRegistrationUpdateWizardModalState hook.
 *
 * @param props
 * @returns
 */
export const RegistrationUpdateWizardModal = ({accountId}: RegistrationUpdateWizardModalProps) => {
  const {state, close} = useRegistrationUpdateWizardModalState()

  /**
   * Handles the dismissal of the modal.
   * Shows a confirmation dialog if the user is in the middle of the wizard.
   */
  const onDismiss = useCallback(() => {
    const shouldClose = window.confirm(
      I18n.t('Are you sure you want to stop updating? Any changes will be lost.'),
    )
    if (shouldClose) {
      close()
    }
    return shouldClose
  }, [close])

  if (!state.open) {
    return null
  }

  return (
    <ResponsiveWrapper
      render={modalProps => (
        <Modal
          id="registration-update-wizard-modal"
          label={I18n.t('Update App')}
          open={state.open}
          size={modalProps?.size || 'large'}
          onDismiss={onDismiss}
        >
          <RegistrationUpdateWizard
            accountId={accountId}
            registration={state.registration}
            ltiRegistrationUpdateRequestId={state.ltiRegistrationUpdateRequestId}
            onDismiss={onDismiss}
            onSuccess={close}
          />
        </Modal>
      )}
    />
  )
}
