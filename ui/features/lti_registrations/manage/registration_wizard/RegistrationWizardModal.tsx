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
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {useCallback} from 'react'
import {isSuccessful} from '../../common/lib/apiResult/ApiResult'
import {DynamicRegistrationWizard} from '../dynamic_registration_wizard/DynamicRegistrationWizard'
import type {DynamicRegistrationWizardService} from '../dynamic_registration_wizard/DynamicRegistrationWizardService'
import {EditLti1p3RegistrationWizard} from '../lti_1p3_registration_form/EditLti1p3RegistrationWizard'
import {Lti1p3RegistrationWizard} from '../lti_1p3_registration_form/Lti1p3RegistrationWizard'
import type {Lti1p3RegistrationWizardService} from '../lti_1p3_registration_form/Lti1p3RegistrationWizardService'
import type {AccountId} from '../model/AccountId'
import {ResponsiveWrapper} from '../registration_wizard_forms/ResponsiveWrapper'
import {RegistrationWizardInitialization} from './RegistrationWizardInitialization'
import type {JsonUrlWizardService} from './JsonUrlWizardService'
import {
  useRegistrationModalWizardState,
  type RegistrationWizardModalState,
  type RegistrationWizardModalStateActions,
} from './RegistrationWizardModalState'

const I18n = createI18nScope('lti_registrations')

export const MODAL_BODY_HEIGHT = '50vh'

export type RegistrationWizardModalProps = {
  accountId: AccountId
  dynamicRegistrationWizardService: DynamicRegistrationWizardService
  lti1p3RegistrationWizardService: Lti1p3RegistrationWizardService
  jsonUrlWizardService: JsonUrlWizardService
}

/**
 * This is the Registration wizard modal that is used to install an LTI app
 * to open, you can call the
 * {@link import('./RegistrationWizardModalState').openRegistrationWizard}
 * function from anywhere
 *
 * @param props
 * @returns
 */
export const RegistrationWizardModal = (props: RegistrationWizardModalProps) => {
  const state = useRegistrationModalWizardState(s => s)

  const label = state.existingRegistrationId ? I18n.t('Edit App') : I18n.t('Install App')

  /**
   * Handles the dismissal of the modal.
   * @returns Returns true if the user wants to close the modal, false otherwise
   */
  const onDismiss = useCallback(() => {
    const confirmationMessage = state.existingRegistrationId
      ? I18n.t('Are you sure you want to stop editing? Any changes will be lost.')
      : I18n.t('Are you sure you want to stop registering? Any progress will be lost.')

    const shouldClose = !state.registering || window.confirm(confirmationMessage)
    if (shouldClose) {
      state.close()
    }
    return shouldClose
  }, [state])

  return (
    <ResponsiveWrapper
      render={modalProps => (
        <Modal
          id="registration-wizard-modal"
          label={label}
          open={state.open}
          size={modalProps?.size || 'medium'}
          onDismiss={onDismiss}
        >
          <ModalBodyWrapper
            state={state}
            accountId={props.accountId}
            dynamicRegistrationWizardService={props.dynamicRegistrationWizardService}
            lti1p3RegistrationWizardService={props.lti1p3RegistrationWizardService}
            jsonUrlWizardService={props.jsonUrlWizardService}
            onDismiss={onDismiss}
          />
        </Modal>
      )}
    />
  )
}

const ModalBodyWrapper = ({
  state,
  accountId,
  dynamicRegistrationWizardService,
  lti1p3RegistrationWizardService,
  jsonUrlWizardService,
  onDismiss,
}: {
  state: RegistrationWizardModalState & RegistrationWizardModalStateActions
  accountId: AccountId
  dynamicRegistrationWizardService: DynamicRegistrationWizardService
  lti1p3RegistrationWizardService: Lti1p3RegistrationWizardService
  jsonUrlWizardService: JsonUrlWizardService
  onDismiss: () => boolean
}) => {
  if (state.registering) {
    if (
      (state.method === 'json_url' || state.method === 'json') &&
      state.jsonFetch._tag === 'loaded' &&
      isSuccessful(state.jsonFetch.result)
    ) {
      return (
        <Lti1p3RegistrationWizard
          accountId={accountId}
          service={lti1p3RegistrationWizardService}
          internalConfiguration={state.jsonFetch.result.data}
          unifiedToolId={state.unifiedToolId}
          onSuccessfulRegistration={id => {
            state.close()
            state.onSuccessfulInstallation?.(id)
          }}
          onDismiss={onDismiss}
        />
      )
    } else if (state.method === 'dynamic_registration') {
      return (
        <DynamicRegistrationWizard
          service={dynamicRegistrationWizardService}
          dynamicRegistrationUrl={state.dynamicRegistrationUrl}
          accountId={accountId}
          unifiedToolId={state.unifiedToolId}
          onDismiss={onDismiss}
          registrationId={state.existingRegistrationId}
          onSuccessfulRegistration={id => {
            state.close()
            showFlashSuccess(
              state.existingRegistrationId
                ? I18n.t('App updated successfully!')
                : I18n.t('App installed successfully!'),
            )()
            state.onSuccessfulInstallation?.(id)
          }}
        />
      )
    } else if (state.method === 'manual' && state.existingRegistrationId) {
      return (
        <EditLti1p3RegistrationWizard
          accountId={accountId}
          onSuccessfulRegistration={id => {
            state.close()
            state.onSuccessfulInstallation?.(id)
          }}
          registrationId={state.existingRegistrationId}
          service={lti1p3RegistrationWizardService}
          onDismiss={onDismiss}
          unifiedToolId={state.unifiedToolId}
        />
      )
    } else if (state.method === 'manual') {
      return (
        <Lti1p3RegistrationWizard
          accountId={accountId}
          service={lti1p3RegistrationWizardService}
          internalConfiguration={{
            description: '',
            launch_settings: {},
            title: state.manualAppName.trim(),
            target_link_uri: '',
            scopes: [],
            oidc_initiation_url: '',
            placements: [],
          }}
          unifiedToolId={state.unifiedToolId}
          onSuccessfulRegistration={id => {
            state.close()
            state.onSuccessfulInstallation?.(id)
          }}
          onDismiss={onDismiss}
        />
      )
    } else {
      return (
        <RegistrationWizardInitialization
          state={state}
          accountId={accountId}
          jsonUrlWizardService={jsonUrlWizardService}
        />
      )
    }
  } else {
    return (
      <RegistrationWizardInitialization
        state={state}
        accountId={accountId}
        jsonUrlWizardService={jsonUrlWizardService}
      />
    )
  }
}
