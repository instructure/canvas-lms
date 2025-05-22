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
import {useScope as createI18nScope} from '@canvas/i18n'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {
  useRegistrationModalWizardState,
  type RegistrationWizardModalState,
  type RegistrationWizardModalStateActions,
  type JsonFetchStatus,
} from './RegistrationWizardModalState'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ProgressBar} from '@instructure/ui-progress'
import {DynamicRegistrationWizard} from '../dynamic_registration_wizard/DynamicRegistrationWizard'
import type {AccountId} from '../model/AccountId'
import type {DynamicRegistrationWizardService} from '../dynamic_registration_wizard/DynamicRegistrationWizardService'
import {isValidHttpUrl} from '../../common/lib/validators/isValidHttpUrl'
import {RegistrationModalBody} from './RegistrationModalBody'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Lti1p3RegistrationWizard} from '../lti_1p3_registration_form/Lti1p3RegistrationWizard'
import type {JsonUrlWizardService} from './JsonUrlWizardService'
import * as z from 'zod'
import {isSuccessful, isUnsuccessful} from '../../common/lib/apiResult/ApiResult'
import {TextArea} from '@instructure/ui-text-area'
import {isValidJson} from '../../common/lib/validators/isValidJson'
import type {FormMessage} from '@instructure/ui-form-field'
import type {Lti1p3RegistrationWizardService} from '../lti_1p3_registration_form/Lti1p3RegistrationWizardService'
import {EditLti1p3RegistrationWizard} from '../lti_1p3_registration_form/EditLti1p3RegistrationWizard'
import {Responsive} from '@instructure/ui-responsive'
import {ResponsiveWrapper} from '../registration_wizard_forms/ResponsiveWrapper'
import {Header} from '../registration_wizard_forms/Header'

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

  return (
    <ResponsiveWrapper
      render={modalProps => (
        <Modal label={label} open={state.open} size={modalProps?.size || 'medium'}>
          <ModalBodyWrapper
            state={state}
            accountId={props.accountId}
            dynamicRegistrationWizardService={props.dynamicRegistrationWizardService}
            lti1p3RegistrationWizardService={props.lti1p3RegistrationWizardService}
            jsonUrlWizardService={props.jsonUrlWizardService}
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
}: {
  state: RegistrationWizardModalState & RegistrationWizardModalStateActions
  accountId: AccountId
  dynamicRegistrationWizardService: DynamicRegistrationWizardService
  lti1p3RegistrationWizardService: Lti1p3RegistrationWizardService
  jsonUrlWizardService: JsonUrlWizardService
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
          registrationId={state.existingRegistrationId}
          onSuccessfulRegistration={() => {
            state.close()
            showFlashSuccess(
              state.existingRegistrationId
                ? I18n.t('App updated successfully!')
                : I18n.t('App installed successfully!'),
            )()
            state.onSuccessfulInstallation?.()
          }}
        />
      )
    } else if (state.method === 'manual' && state.existingRegistrationId) {
      return (
        <EditLti1p3RegistrationWizard
          accountId={accountId}
          onSuccessfulRegistration={() => {
            state.close()
            state.onSuccessfulInstallation?.()
          }}
          registrationId={state.existingRegistrationId}
          service={lti1p3RegistrationWizardService}
          unregister={() => {
            state.close()
          }}
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
          onSuccessfulRegistration={() => {
            state.close()
            state.onSuccessfulInstallation?.()
          }}
          unregister={state.unregister}
        />
      )
    } else {
      return (
        <InitializationModal
          state={state}
          accountId={accountId}
          jsonUrlWizardService={jsonUrlWizardService}
        />
      )
    }
  } else {
    return (
      <InitializationModal
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

const renderDebugMessage = (jsonUrlFetch: JsonFetchStatus) => {
  if (jsonUrlFetch._tag === 'loaded' && jsonUrlFetch.result._type === 'ApiError') {
    const result = z.object({errors: z.array(z.string())}).safeParse(jsonUrlFetch.result.body)
    if (result.success) {
      return result.data.errors.map((err, i) => <div key={i}>{err}</div>)
    }
  }
}

const InitializationModal = (props: InitializationModalBodyProps) => {
  const [debugging, setDebugging] = React.useState(false)

  React.useEffect(() => {
    const listener = (event: KeyboardEvent) => {
      if (event.metaKey && event.key === 'b') {
        setDebugging(prev => !prev)
      }
    }
    document.addEventListener('keydown', listener)
    return () => {
      document.removeEventListener('keydown', listener)
    }
  })

  return (
    <>
      <Header onClose={props.state.close} editing={!!props.state.existingRegistrationId} />
      <RegistrationModalBody>
        <View display="block" margin="0 0 medium 0">
          <RadioInputGroup
            description={I18n.t('Select LTI Version')}
            onChange={(_e, value) => {
              if (value === '1p3' || value === '1p1') {
                props.state.updateLtiVersion(value)
              } else {
                console.warn(`Invalid value for lti_version: ${value}`)
              }
            }}
            name="LTI Version"
            defaultValue={props.state.lti_version || '1p3'}
          >
            <RadioInput value="1p3" label="1.3" />
            <RadioInput value="1p1" label="1.1" data-pendo="lti-registration-1p1-interest" />
          </RadioInputGroup>
        </View>
        {props.state.lti_version === '1p3' && (
          <>
            <View display="block" margin="medium 0">
              <SimpleSelect
                renderLabel={I18n.t('Install Method')}
                assistiveText="Use arrow keys to navigate options."
                value={props.state.method}
                onChange={(_e, {value}) => {
                  if (value === 'dynamic_registration') {
                    props.state.updateMethod('dynamic_registration')
                  } else if (value === 'json_url') {
                    props.state.updateMethod('json_url')
                  } else if (value === 'json') {
                    props.state.updateMethod('json')
                  } else if (value === 'manual') {
                    props.state.updateMethod('manual')
                  } else {
                    // todo: add other methods here
                  }
                }}
              >
                <SimpleSelect.Option id="dynamic_registration" value="dynamic_registration">
                  {I18n.t('Dynamic Registration')}
                </SimpleSelect.Option>
                <SimpleSelect.Option id="json_url" value="json_url">
                  {I18n.t('Enter URL')}
                </SimpleSelect.Option>

                <SimpleSelect.Option id="json" value="json">
                  {I18n.t('JSON')}
                </SimpleSelect.Option>

                <SimpleSelect.Option id="manual" value="manual">
                  {I18n.t('Manual')}
                </SimpleSelect.Option>
              </SimpleSelect>
            </View>
            {props.state.method === 'dynamic_registration' && (
              <View display="block" margin="medium 0">
                <TextInput
                  renderLabel={I18n.t('Dynamic Registration URL')}
                  value={props.state.dynamicRegistrationUrl}
                  onChange={(_e, value) => props.state.updateDynamicRegistrationUrl(value)}
                  messages={dynamicRegistrationUrlInputMessages(props.state)}
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
                  messages={jsonUrlInputMessages(props.state)}
                />
              </View>
            )}
            {props.state.method === 'json' && (
              <View display="block" margin="medium 0">
                <TextArea
                  data-testid="json-code-input"
                  label={I18n.t('JSON Code')}
                  value={props.state.jsonCode}
                  onChange={event => props.state.updateJsonCode(event.currentTarget.value)}
                  height="10em"
                  maxHeight="10em"
                  themeOverride={{
                    fontFamily: 'monospace',
                  }}
                  messages={jsonCodeInputMessages(props.state)}
                />
              </View>
            )}

            {props.state.method === 'manual' && (
              <View display="block" margin="medium 0">
                <TextInput
                  data-testid="manual-name-input"
                  renderLabel={I18n.t('App Name')}
                  value={props.state.manualAppName}
                  onChange={(_e, value) => props.state.updateManualAppName(value)}
                />
              </View>
            )}
            {debugging && renderDebugMessage(props.state.jsonFetch)}
          </>
        )}
        {props.state.lti_version === '1p1' && (
          <View display="block" margin="medium 0" padding="small" background="secondary">
            <Text
              dangerouslySetInnerHTML={{
                __html: I18n.t(
                  'Thank you for your interest in 1.1. We are exploring the possibility of enabling 1.1 installs from the new apps page in future releases. For now, you can install 1.1 tools from the *%{legacyAppPage}*.',
                  {
                    legacyAppPage: 'legacy apps page',
                    wrappers: [
                      `<a href=/accounts/${props.accountId}/settings/configurations#tab-tools>$1</a>`,
                    ],
                  },
                ),
              }}
            />
          </View>
        )}
      </RegistrationModalBody>

      <Modal.Footer>
        <Button
          data-testid="registration-wizard-next-button"
          color="primary"
          type="submit"
          margin="small"
          disabled={validForm(props.state) === false || props.state.jsonFetch._tag === 'loading'}
          onClick={() => {
            // if it's json_url, we need to fetch the configuration first
            if (props.state.method === 'json_url' || props.state.method === 'json') {
              props.state.updateJsonFetchStatus({_tag: 'loading'})
              const body =
                props.state.method === 'json'
                  ? {
                      lti_configuration: JSON.parse(props.state.jsonCode),
                    }
                  : {url: props.state.jsonUrl}

              props.jsonUrlWizardService
                .fetchThirdPartyToolConfiguration(body, props.accountId)
                .then(result => {
                  props.state.updateJsonFetchStatus({
                    _tag: 'loaded',
                    result,
                  })
                })
            } else {
              props.state.register()
            }
          }}
        >
          {props.state.jsonFetch._tag === 'loading' ? I18n.t('Loading') : I18n.t('Next')}
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
    } else if (state.method === 'json') {
      return isValidJson(state.jsonCode)
    } else if (state.method === 'manual') {
      return state.manualAppName.trim() !== ''
    } else {
      return false
    }
  } else {
    return false
  }
}

const dynamicRegistrationUrlInputMessages = (
  state: RegistrationWizardModalState,
): Array<FormMessage> => {
  const defaultMessage: FormMessage = {
    text: I18n.t(
      'You can locate this URL on the integration page of the tool if it supports this method',
    ),
    type: 'hint',
  }
  if (!isValidHttpUrl(state.dynamicRegistrationUrl) && state.dynamicRegistrationUrl.trim() !== '') {
    return [{text: I18n.t('Please enter a valid URL'), type: 'error'}, defaultMessage]
  } else {
    return [defaultMessage]
  }
}

/**
 * Constructs error & info messages for the JSON URL input field
 * @param state
 * @returns
 */
const jsonUrlInputMessages = (state: RegistrationWizardModalState): Array<FormMessage> => {
  const fetchMessages = jsonFetchMessages(state)
  // if the URL is invalid, we need to show that message

  const withInfoMessage =
    fetchMessages.length === 0
      ? [
          {
            text: I18n.t(
              'You can locate this URL on the integration page of the tool if it supports this method',
            ),
            type: 'hint',
          } as const,
        ]
      : fetchMessages

  if (!isValidHttpUrl(state.jsonUrl) && state.jsonUrl.trim() !== '') {
    return [{text: I18n.t('Please enter a valid URL'), type: 'error'}, ...withInfoMessage]
  } else {
    return withInfoMessage
  }
}

/**
 * Constructs error & info messages for the JSON code input field
 * @param state
 * @returns
 */
const jsonCodeInputMessages = (state: RegistrationWizardModalState): Array<FormMessage> => {
  const fetchMessages = jsonFetchMessages(state)

  if (!isValidJson(state.jsonCode) && state.jsonCode.trim() !== '') {
    return [{text: I18n.t('Please enter valid JSON'), type: 'error'}, ...fetchMessages]
  } else {
    return fetchMessages
  }
}

/**
 * Constructs FormMessages based on the state of the JSON fetch,
 * used both with code & URL input fields
 * @param state
 * @param method
 * @returns
 */
const jsonFetchMessages = (state: RegistrationWizardModalState): Array<FormMessage> => {
  const jsonFetch = state.jsonFetch
  if (jsonFetch._tag === 'loaded' && isUnsuccessful(jsonFetch.result)) {
    const errorType = jsonFetch.result._type

    /**
     * True if the configuration is invalid or the JSON is invalid,
     * the implication being that the tool provider needs to fix the configuration
     */
    const configurationError =
      errorType === 'InvalidJson' || (errorType === 'ApiError' && jsonFetch.result.status === 422)

    return [
      {
        text: configurationError
          ? I18n.t(
              'The configuration is invalid. Please reach out to the app provider for assistance.',
            )
          : I18n.t('An error occurred. Please try again.'),
        type: 'error',
      } as const,
    ]
  } else {
    return []
  }
}
