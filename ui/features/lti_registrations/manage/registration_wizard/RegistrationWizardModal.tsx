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
import {Modal} from '@instructure/ui-modal'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {
  useRegistrationModalWizardState,
  type RegistrationWizardModalState,
  type RegistrationWizardModalStateActions,
} from './RegistrationWizardModalState'
import {Select} from '@instructure/ui-select'
import {TextInput} from '@instructure/ui-text-input'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {ProgressBar} from '@instructure/ui-progress'
import {DynamicRegistrationWizard} from '../dynamic_registration_wizard/DynamicRegistrationWizard'
import {type AccountId} from '../model/AccountId'
import {
  fetchRegistrationToken,
  getRegistrationByUUID,
  updateRegistrationOverlay,
} from '../api/ltiImsRegistration'
import {
  deleteDeveloperKey,
  updateAdminNickname,
  updateDeveloperKeyWorkflowState,
} from '../api/developerKey'
import type {DynamicRegistrationWizardService} from '../dynamic_registration_wizard/DynamicRegistrationWizardService'
import {isValidHttpUrl} from '../../common/lib/validators/isValidHttpUrl'
import {RegistrationModalBody} from './RegistrationModalBody'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {refreshRegistrations} from '../pages/manage/ManagePageLoadingState'

const I18n = useI18nScope('lti_registrations')

export const MODAL_BODY_HEIGHT = '50vh'

export type RegistrationWizardModalProps = {
  accountId: AccountId
}

export const RegistrationWizardModal = (props: RegistrationWizardModalProps) => {
  const state = useRegistrationModalWizardState(s => s)

  return (
    <Modal label={I18n.t('Install App')} open={state.open} size="medium">
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={state.close}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Install App')}</Heading>
      </Modal.Header>
      {!state.registering ? (
        <ProgressBar
          meterColor="info"
          shouldAnimate={true}
          size="x-small"
          screenReaderLabel={I18n.t('Installation Progress')}
          valueNow={0}
          valueMax={100}
          themeOverride={{
            trackBottomBorderWidth: '0',
          }}
          margin="0 0 small"
        />
      ) : null}

      <ModalBodyWrapper state={state} accountId={props.accountId} />
    </Modal>
  )
}

const dynamicRegistrationWizardService: DynamicRegistrationWizardService = {
  deleteDeveloperKey,
  fetchRegistrationToken,
  getRegistrationByUUID,
  updateDeveloperKeyWorkflowState,
  updateAdminNickname,
  updateRegistrationOverlay,
}

const ModalBodyWrapper = ({
  state,
  accountId,
}: {
  state: RegistrationWizardModalState & RegistrationWizardModalStateActions
  accountId: AccountId
}) => {
  return state.registering && state.method === 'dynamic_registration' ? (
    <DynamicRegistrationWizard
      service={dynamicRegistrationWizardService}
      dynamicRegistrationUrl={state.dynamicRegistrationUrl}
      accountId={accountId}
      unifiedToolId={state.unifiedToolId}
      unregister={state.unregister}
      onSuccessfulRegistration={() => {
        state.unregister()
        showFlashSuccess(I18n.t('App installed successfully!'))()
        state.onSuccessfulInstallation?.()
      }}
    />
  ) : (
    <InitializationModalBody state={state} />
  )
}

export type InitializationModalBodyProps = {
  state: RegistrationWizardModalState & RegistrationWizardModalStateActions
}

const InitializationModalBody = (props: InitializationModalBodyProps) => {
  return (
    <>
      <RegistrationModalBody>
        <View display="block" margin="0 0 medium 0">
          <RadioInputGroup
            description={I18n.t('Select LTI Version')}
            onChange={(_e, value) => {
              if (value === '1p3' || value === '1p1') {
                props.state.updateLtiVersion(value)
              } else {
                // eslint-disable-next-line no-console
                console.warn(`Invalid value for lti_version: ${value}`)
              }
            }}
            name="example1"
            defaultValue="1p3"
          >
            <RadioInput value="1p3" label="1.3" />
            <RadioInput value="1p1" label="1.1" data-heap="lti-registration-1p1-interest" />
          </RadioInputGroup>
        </View>
        {props.state.lti_version === '1p3' && (
          <>
            <View display="block" margin="medium 0">
              <Select
                disabled={true}
                renderLabel={I18n.t('Install Method')}
                assistiveText="Use arrow keys to navigate options."
                inputValue={I18n.t('Dynamic Registration')}
                onRequestSelectOption={() => {
                  // todo: update this to change the method
                  // when those methods are implemented
                }}
              >
                <Select.Option
                  id="dynamic_registration"
                  isSelected={props.state.method === 'dynamic_registration'}
                >
                  {I18n.t('Dynamic Registration')}
                </Select.Option>
              </Select>
            </View>
            {props.state.method === 'dynamic_registration' && (
              <View display="block" margin="medium 0">
                <TextInput
                  renderLabel={I18n.t('Dynamic Registration URL')}
                  value={props.state.dynamicRegistrationUrl}
                  onChange={(_e, value) => props.state.updateDynamicRegistrationUrl(value)}
                  messages={[
                    {
                      text: I18n.t(
                        'You can locate this URL on the integration page of the tool if it supports this method'
                      ),
                      type: 'hint',
                    },
                  ]}
                />
              </View>
            )}
          </>
        )}
      </RegistrationModalBody>

      <Modal.Footer>
        <Button
          color="primary"
          type="submit"
          margin="small"
          disabled={validForm(props.state) === false}
          onClick={() => {
            props.state.register()
          }}
        >
          {I18n.t('Next')}
        </Button>
      </Modal.Footer>
    </>
  )
}

const validForm = (state: RegistrationWizardModalState) => {
  if (state.lti_version === '1p3') {
    return isValidHttpUrl(state.dynamicRegistrationUrl)
  } else {
    return false
  }
}
