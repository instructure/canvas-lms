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

import {AccountId} from '@canvas/lti-apps/models/AccountId'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import React from 'react'
import {JsonUrlWizardService} from './JsonUrlWizardService'
import {RegistrationModalBody} from './RegistrationModalBody'
import {
  RegistrationWizardModalState,
  RegistrationWizardModalStateActions,
  type JsonFetchStatus,
} from './RegistrationWizardModalState'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Header} from '../registration_wizard_forms/Header'
import {View} from '@instructure/ui-view'
import {isValidHttpUrl} from '../../common/lib/validators/isValidHttpUrl'
import {isSuccessful, isUnsuccessful} from '../../common/lib/apiResult/ApiResult'
import {Text} from '@instructure/ui-text'
import type {FormMessage} from '@instructure/ui-form-field'
import {isValidJson} from '../../common/lib/validators/isValidJson'
import * as z from 'zod'

const I18n = createI18nScope('lti_registrations')

export type RegistrationWizardInitializationProps = {
  state: RegistrationWizardModalState & RegistrationWizardModalStateActions
  jsonUrlWizardService: JsonUrlWizardService
  accountId: AccountId
}

/**
 * Renders the initialization step of the registration wizard, which
 * allows the user to select LTI version, installation method and
 * additional details based on those selections.
 *
 * After making selections, the user can click "Next" to proceed and
 * will be moved to the appropriate next step based on their choices.
 *
 * Currently allows selection of LTI 1.3 only, with installation methods:
 * - Dynamic Registration
 * - JSON URL
 * - JSON Code
 * - Manual
 *
 * @param props
 * @returns
 */
export const RegistrationWizardInitialization = (props: RegistrationWizardInitializationProps) => {
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

  const blankConfigurationMessage = props.state.isInstructureTool
    ? I18n.t(
        'A configuration is not available for this tool. Please reach out to your CSM for more information on how to install it.',
      )
    : I18n.t(
        'A configuration is not available for this tool. Please reach out to the tool provider for more information on how to install it.',
      )

  return (
    <>
      <Header onClose={props.state.close} editing={!!props.state.existingRegistrationId} />
      <RegistrationModalBody>
        {props.state.showBlankConfigurationMessage && (
          <Alert
            variant="info"
            margin="0 0 medium"
            hasShadow={false}
            variantScreenReaderLabel="Information, "
          >
            {blankConfigurationMessage}
          </Alert>
        )}
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
            <RadioInput value="1p3" label="1.3" data-pendo="lti-registration-1p3-install" />
            <RadioInput value="1p1" label="1.1" data-pendo="lti-registration-1p1-interest" />
          </RadioInputGroup>
        </View>
        {props.state.lti_version === '1p3' && (
          <>
            <View display="block" margin="medium 0">
              <SimpleSelect
                id="lti-registration-install-method-selector"
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
          margin="0"
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

const renderDebugMessage = (jsonUrlFetch: JsonFetchStatus) => {
  if (jsonUrlFetch._tag === 'loaded' && jsonUrlFetch.result._type === 'ApiError') {
    const result = z.object({errors: z.array(z.string())}).safeParse(jsonUrlFetch.result.body)
    if (result.success) {
      return result.data.errors.map((err, i) => <div key={i}>{err}</div>)
    }
  }
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
