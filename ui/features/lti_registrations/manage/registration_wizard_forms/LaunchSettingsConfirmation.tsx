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
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {useValidateLaunchSettings} from '../lti_1p3_registration_form/hooks/useValidateLaunchSettings'
import {TextInput} from '@instructure/ui-text-input'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Popover} from '@instructure/ui-popover'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {IconInfoLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import {toUndefined} from '../../common/lib/toUndefined'
import {Lti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import {Lti1p3RegistrationOverlayState} from '../registration_overlay/Lti1p3RegistrationOverlayState'
import {getInputIdForField} from '../registration_overlay/validateLti1p3RegistrationOverlayState'
import {formatCustomFields} from '../registration_overlay/Lti1p3RegistrationOverlayStateHelpers'
import {useShallow} from 'zustand/react/shallow'

const I18n = createI18nScope('lti_registrations')

export type LaunchSettingsConfirmationProps = {
  title?: string
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  hasClickedNext?: boolean
}

type LaunchSettingsField = keyof Lti1p3RegistrationOverlayState['launchSettings']

export const LaunchSettingsConfirmation = (props: LaunchSettingsConfirmationProps) => {
  const {
    launchSettings,
    setRedirectURIs,
    setDefaultTargetLinkURI,
    setJwkMethod,
    setOIDCInitiationURI,
    setJwkURL,
    setJwk,
    setDomain,
    setCustomFields,
    hasSubmitted,
  } = props.overlayStore(
    useShallow(s => ({
      launchSettings: s.state.launchSettings,
      setRedirectURIs: s.setRedirectURIs,
      setDefaultTargetLinkURI: s.setDefaultTargetLinkURI,
      setJwkMethod: s.setJwkMethod,
      setOIDCInitiationURI: s.setOIDCInitiationURI,
      setJwkURL: s.setJwkURL,
      setJwk: s.setJwk,
      setDomain: s.setDomain,
      setCustomFields: s.setCustomFields,
      hasSubmitted: s.state.hasSubmitted,
    })),
  )

  const config = props.internalConfig

  const errors = useValidateLaunchSettings(launchSettings)
  const {
    redirectUrisMessages,
    targetLinkURIMessages,
    openIDConnectInitiationURLMessages,
    jwkMessages,
    domainMessages,
    customFieldsMessages,
  } = errors

  const [blurStatus, setBlurStatus] = React.useState<Partial<Record<LaunchSettingsField, boolean>>>(
    {},
  )

  /**
   * Handles the onBlur event for the given field.
   * @param field The field to handle the onBlur event for.
   * @param required Whether the field is required.
   * @returns A function that handles the onBlur event for the given field.
   */
  const handleBlur = React.useCallback(
    (field: LaunchSettingsField, required: boolean = false) =>
      (event: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement>): void => {
        setBlurStatus(prev => ({
          ...prev,
          [field]: event.currentTarget.value.trim() !== '' || required,
        }))
      },
    [setBlurStatus],
  )

  return (
    <Flex direction="column" gap="medium">
      <div>
        <Heading level="h3">{props.title ? props.title : I18n.t('LTI 1.3 Registration')}</Heading>
        <Text
          dangerouslySetInnerHTML={{
            __html: I18n.t(
              'Find more information about manual configuration in the *Canvas documentation.*',
              {
                wrapper: [
                  '<a href="https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html" target="_blank">$1</a>',
                ],
              },
            ),
          }}
        />
      </div>
      <div>
        <TextArea
          label={I18n.t('Redirect URIs')}
          required={true}
          maxHeight="76px"
          value={launchSettings.redirectURIs || ''}
          onChange={e => setRedirectURIs(e.target.value)}
          aria-describedby="redirect_uris_hint"
          messages={
            redirectUrisMessages && (blurStatus.redirectURIs || hasSubmitted)
              ? redirectUrisMessages
              : []
          }
          // TextArea's onBlur prop is typed incorrectly
          onBlur={handleBlur('redirectURIs', true) as unknown as any}
          id={getInputIdForField(`redirectURIs`)}
        />
        <Text size="small" id="redirect_uris_hint">
          {I18n.t('One per line')}
        </Text>
      </div>
      <TextInput
        renderLabel={I18n.t('Default Target Link URI')}
        value={launchSettings.targetLinkURI || ''}
        placeholder={config.target_link_uri}
        onChange={e => setDefaultTargetLinkURI(e.target.value)}
        messages={
          targetLinkURIMessages && (blurStatus.targetLinkURI || hasSubmitted)
            ? targetLinkURIMessages
            : []
        }
        isRequired={true}
        onBlur={handleBlur('targetLinkURI', true)}
        id={getInputIdForField('targetLinkURI')}
      />
      <TextInput
        renderLabel={I18n.t('OpenID Connect Initiation URL')}
        value={launchSettings.openIDConnectInitiationURL || ''}
        onChange={e => setOIDCInitiationURI(e.target.value)}
        isRequired={true}
        messages={
          openIDConnectInitiationURLMessages &&
          (blurStatus.openIDConnectInitiationURL || hasSubmitted)
            ? openIDConnectInitiationURLMessages
            : []
        }
        onBlur={handleBlur('openIDConnectInitiationURL', true)}
        id={getInputIdForField('openIDConnectInitiationURL')}
      />
      <RadioInputGroup
        name="jwkMethod"
        description={I18n.t('JWK Method')}
        value={launchSettings.JwkMethod}
        onChange={(_, value) => setJwkMethod(value as 'public_jwk_url' | 'public_jwk')}
        layout="columns"
      >
        <RadioInput value="public_jwk_url" label={I18n.t('Public JWK URL')} />
        <RadioInput value="public_jwk" label={I18n.t('Public JWK')} />
      </RadioInputGroup>
      {launchSettings.JwkMethod === 'public_jwk' ? (
        <TextArea
          label={I18n.t('JWK')}
          maxHeight="10rem"
          value={launchSettings.Jwk || ''}
          onChange={e => setJwk(e.target.value)}
          messages={jwkMessages && (blurStatus.Jwk || hasSubmitted) ? jwkMessages : []}
          themeOverride={{fontFamily: 'monospace'}}
          // TextArea's onBlur prop is typed incorrectly
          onBlur={handleBlur('Jwk', true) as unknown as any}
          id={getInputIdForField('Jwk')}
          required={true}
        />
      ) : (
        <TextInput
          renderLabel={I18n.t('JWK URL')}
          value={launchSettings.JwkURL || ''}
          onChange={e => setJwkURL(e.target.value)}
          messages={jwkMessages && (blurStatus.JwkURL || hasSubmitted) ? jwkMessages : []}
          onBlur={handleBlur('JwkURL', true)}
          id={getInputIdForField('JwkURL')}
          data-testid={getInputIdForField('JwkURL')}
          required={true}
        />
      )}
      <TextInput
        renderLabel={I18n.t('Domain')}
        value={launchSettings.domain || ''}
        placeholder={toUndefined(config.domain)}
        onChange={e => setDomain(e.target.value)}
        messages={domainMessages && (blurStatus.domain || hasSubmitted) ? domainMessages : []}
        onBlur={handleBlur('domain')}
        id={getInputIdForField('domain')}
      />
      <div>
        <TextArea
          label={
            <>
              <Text>{I18n.t('Custom Fields')}</Text>
              <Popover
                placement="end"
                color="primary-inverse"
                on={['click', 'focus']}
                renderTrigger={
                  <IconButton
                    margin="0 0 0 x-small"
                    screenReaderLabel={I18n.t('Custom Fields Help')}
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                  />
                }
              >
                <View margin="small" display="block">
                  <Text
                    dangerouslySetInnerHTML={{
                      __html: I18n.t('Refer to the *Canvas documentation* for more details.', {
                        wrapper: [
                          '<a href="https://canvas.instructure.com/doc/api/file.tools_variable_substitutions.html" target="_blank">$1</a>',
                        ],
                      }),
                    }}
                  />
                </View>
              </Popover>
            </>
          }
          maxHeight="10rem"
          value={launchSettings.customFields || ''}
          onChange={e => setCustomFields(e.target.value)}
          aria-describedby="custom_fields_hint"
          placeholder={config.custom_fields ? formatCustomFields(config.custom_fields) : undefined}
          messages={
            customFieldsMessages && (blurStatus.customFields || hasSubmitted)
              ? customFieldsMessages
              : []
          }
          data-testid="custom-fields"
          // TextArea's onBlur prop is typed incorrectly
          onBlur={handleBlur('customFields') as unknown as any}
          id={getInputIdForField('customFields')}
        />
        <Text size="small" id="custom_fields_hint">
          {I18n.t('One per line. Format name=value')}
        </Text>
      </div>
    </Flex>
  )
}
