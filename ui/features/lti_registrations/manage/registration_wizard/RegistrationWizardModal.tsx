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
import {Modal} from '@instructure/ui-modal'
import {useScope as useI18nScope} from '@canvas/i18n'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {
  useRegistrationModalWizardState,
  type RegistrationWizardModalState,
  type RegistrationWizardModalStateActions,
} from './RegistrationWizardModalState'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {ProgressBar} from '@instructure/ui-progress'
import {DynamicRegistrationWizard} from '../dynamic_registration_wizard/DynamicRegistrationWizard'
import {type AccountId} from '../model/AccountId'
import type {DynamicRegistrationWizardService} from '../dynamic_registration_wizard/DynamicRegistrationWizardService'
import {isValidHttpUrl} from '../../common/lib/validators/isValidHttpUrl'
import {RegistrationModalBody} from './RegistrationModalBody'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Lti1p3RegistrationWizard} from '../lti_1p3_registration_form/Lti1p3RegistrationWizard'
import type {JsonUrlWizardService} from './JsonUrlWizardService'

const I18n = useI18nScope('lti_registrations')

export const MODAL_BODY_HEIGHT = '50vh'

export type RegistrationWizardModalProps = {
  accountId: AccountId
  dynamicRegistrationWizardService: DynamicRegistrationWizardService
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

  const label = state.ltiImsRegistrationId ? I18n.t('Edit App') : I18n.t('Install App')

  return (
    <Modal label={label} open={state.open} size="medium">
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={state.close}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{label}</Heading>
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

      <ModalBodyWrapper
        state={state}
        accountId={props.accountId}
        dynamicRegistrationWizardService={props.dynamicRegistrationWizardService}
        jsonUrlWizardService={props.jsonUrlWizardService}
      />
    </Modal>
  )
}

const ModalBodyWrapper = ({
  state,
  accountId,
  dynamicRegistrationWizardService,
  jsonUrlWizardService,
}: {
  state: RegistrationWizardModalState & RegistrationWizardModalStateActions
  accountId: AccountId
  dynamicRegistrationWizardService: DynamicRegistrationWizardService
  jsonUrlWizardService: JsonUrlWizardService
}) => {
  if (state.registering) {
    if (
      state.method === 'json_url' &&
      state.jsonUrlFetch._tag === 'loaded' &&
      state.jsonUrlFetch.result._type === 'success'
    ) {
      return (
        <Lti1p3RegistrationWizard
          accountId={accountId}
          configuration={state.jsonUrlFetch.result.data}
          unifiedToolId={state.unifiedToolId}
          onSuccessfulRegistration={() => {
            state.close()
            state.onSuccessfulInstallation?.()
          }}
          unregister={state.unregister}
        />
      )
    } else if (state.method === 'dynamic_registration') {
      return (
        <DynamicRegistrationWizard
          service={dynamicRegistrationWizardService}
          dynamicRegistrationUrl={state.dynamicRegistrationUrl}
          accountId={accountId}
          unifiedToolId={state.unifiedToolId}
          unregister={state.unregister}
          registrationId={state.ltiImsRegistrationId}
          onSuccessfulRegistration={() => {
            state.close()
            showFlashSuccess(
              state.ltiImsRegistrationId
                ? I18n.t('App updated successfully!')
                : I18n.t('App installed successfully!')
            )()
            state.onSuccessfulInstallation?.()
          }}
        />
      )
    } else {
      return (
        <InitializationModalBody
          state={state}
          accountId={accountId}
          jsonUrlWizardService={jsonUrlWizardService}
        />
      )
    }
  } else {
    return (
      <InitializationModalBody
        state={state}
        accountId={accountId}
        jsonUrlWizardService={jsonUrlWizardService}
      />
    )
  }
}

export type InitializationModalBodyProps = {
  state: RegistrationWizardModalState & RegistrationWizardModalStateActions
  jsonUrlWizardService: JsonUrlWizardService
  accountId: AccountId
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
              <SimpleSelect
                renderLabel={I18n.t('Install Method')}
                assistiveText="Use arrow keys to navigate options."
                value={props.state.method}
                disabled={!window.ENV.FEATURES.lti_registrations_next}
                onChange={(e, {value}) => {
                  if (value === 'dynamic_registration') {
                    props.state.updateMethod('dynamic_registration')
                  } else if (value === 'json_url') {
                    props.state.updateMethod('json_url')
                  } else {
                    // todo: add other methods here
                  }
                }}
              >
                <SimpleSelect.Option id="dynamic_registration" value="dynamic_registration">
                  {I18n.t('Dynamic Registration')}
                </SimpleSelect.Option>
                {window.ENV.FEATURES.lti_registrations_next && (
                  <SimpleSelect.Option id="json_url" value="json_url">
                    {I18n.t('Enter URL')}
                  </SimpleSelect.Option>
                )}
              </SimpleSelect>
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
            {props.state.method === 'json_url' && (
              <View display="block" margin="medium 0">
                <TextInput
                  data-testid="json-url-input"
                  renderLabel={I18n.t('JSON URL')}
                  value={props.state.jsonUrl}
                  onChange={(_e, value) => props.state.updateJsonUrl(value)}
                  messages={jsonUrlFetchMessages(props.state)}
                />
              </View>
            )}
          </>
        )}
      </RegistrationModalBody>

      <Modal.Footer>
        <Button
          data-testid="registration-wizard-next-button"
          color="primary"
          type="submit"
          margin="small"
          disabled={validForm(props.state) === false || props.state.jsonUrlFetch._tag === 'loading'}
          onClick={() => {
            // if it's json_url, we need to fetch the configuration first
            if (props.state.method === 'json_url') {
              props.state.updateJsonFetchStatus({_tag: 'loading'})
              props.jsonUrlWizardService
                .fetchThirdPartyToolConfiguration(props.state.jsonUrl, props.accountId)
                .then(result => {
                  props.state.updateJsonFetchStatus({_tag: 'loaded', result})
                })
            } else {
              props.state.register()
            }
          }}
        >
          {props.state.jsonUrlFetch._tag === 'loading' ? I18n.t('Loading') : I18n.t('Next')}
        </Button>
      </Modal.Footer>
    </>
  )
}

const validForm = (state: RegistrationWizardModalState) => {
  if (state.lti_version === '1p3') {
    if (state.method === 'dynamic_registration') {
      return isValidHttpUrl(state.dynamicRegistrationUrl)
    } else if (state.method === 'json_url') {
      return isValidHttpUrl(state.jsonUrl)
    } else {
      return false
    }
  } else {
    return false
  }
}

const jsonUrlFetchMessages = (state: RegistrationWizardModalState) => {
  const jsonUrlFetch = state.jsonUrlFetch
  if (jsonUrlFetch._tag === 'loaded' && jsonUrlFetch.result._type !== 'success') {
    const errorType = jsonUrlFetch.result._type
    return [
      {
        text:
          errorType === 'ApiParseError' || errorType === 'InvalidJson'
            ? I18n.t(
                'The configuration is invalid. Please reach out to the app provider for assistance.'
              )
            : I18n.t('An error occurred. Please try again.'),
        type: 'error',
      } as const,
    ]
  } else {
    return [
      {
        text: I18n.t(
          'You can locate this URL on the integration page of the tool if it supports this method'
        ),
        type: 'hint',
      } as const,
    ]
  }
}
