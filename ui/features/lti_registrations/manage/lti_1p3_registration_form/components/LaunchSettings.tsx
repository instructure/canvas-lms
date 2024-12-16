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
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {useValidateLaunchSettings} from '../hooks/useValidateLaunchSettings'
import {
  formatCustomFields,
  type Lti1p3RegistrationOverlayStore,
} from '../Lti1p3RegistrationOverlayState'
import {TextInput} from '@instructure/ui-text-input'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Flex} from '@instructure/ui-flex'
import {Popover} from '@instructure/ui-popover'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {IconInfoLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {toUndefined} from '../../../common/lib/toUndefined'

const I18n = createI18nScope('lti_registrations')

export type LaunchSettingsProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  unregister: () => void
  reviewing: boolean
  onNextClicked: () => void
}

export const LaunchSettings = (props: LaunchSettingsProps) => {
  const config = props.internalConfig
  const {
    state: {launchSettings},
    ...actions
  } = props.overlayStore()

  const {
    redirectUrisMessages,
    targetLinkURIMessages,
    openIDConnectInitiationURLMessages,
    jwkMessages,
    domainMessages,
    customFieldsMessages,
  } = useValidateLaunchSettings(launchSettings, config)

  const isNextDisabled = Object.values(useValidateLaunchSettings(launchSettings, config)).some(
    messages => messages.length !== 0
  )

  return (
    <>
      <RegistrationModalBody>
        <Flex direction="column" gap="medium">
          <div>
            <Heading level="h3">{I18n.t('LTI 1.3 Registration')}</Heading>
            <Text
              dangerouslySetInnerHTML={{
                __html: I18n.t(
                  'Find more information about manual configuration in the *Canvas documentation.*',
                  {
                    wrapper: [
                      '<a href="https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html" target="_blank">$1</a>',
                    ],
                  }
                ),
              }}
            />
          </div>
          <div>
            <TextArea
              label={I18n.t('Redirect URIs')}
              maxHeight="76px"
              value={launchSettings.redirectURIs || ''}
              onChange={e => actions.setRedirectURIs(e.target.value)}
              aria-describedby="redirect_uris_hint"
              messages={redirectUrisMessages}
            />
            <Text size="small" id="redirect_uris_hint">
              {I18n.t('One per line')}
            </Text>
          </div>
          <TextInput
            renderLabel={I18n.t('Default Target Link URI')}
            value={launchSettings.targetLinkURI || ''}
            placeholder={config.target_link_uri}
            onChange={e => actions.setDefaultTargetLinkURI(e.target.value)}
            messages={targetLinkURIMessages}
            required={true}
          />
          <TextInput
            renderLabel={I18n.t('OpenID Connect Initiation URL')}
            value={launchSettings.openIDConnectInitiationURL || ''}
            onChange={e => actions.setOIDCInitiationURI(e.target.value)}
            required={true}
            messages={openIDConnectInitiationURLMessages}
          />
          <RadioInputGroup
            name="jwkMethod"
            description={I18n.t('JWK Method')}
            value={launchSettings.JwkMethod}
            onChange={(_, value) => actions.setJwkMethod(value as 'public_jwk_url' | 'public_jwk')}
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
              onChange={e => actions.setJwk(e.target.value)}
              messages={jwkMessages}
              themeOverride={{fontFamily: 'monospace'}}
            />
          ) : (
            <TextInput
              renderLabel={I18n.t('JWK URL')}
              value={launchSettings.JwkURL || ''}
              onChange={e => actions.setJwkURL(e.target.value)}
              messages={jwkMessages}
            />
          )}
          <TextInput
            renderLabel={I18n.t('Domain')}
            value={launchSettings.domain || ''}
            placeholder={toUndefined(config.domain)}
            onChange={e => actions.setDomain(e.target.value)}
            messages={domainMessages}
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
              onChange={e => actions.setCustomFields(e.target.value)}
              aria-describedby="custom_fields_hint"
              placeholder={
                config.custom_fields ? formatCustomFields(config.custom_fields) : undefined
              }
              messages={customFieldsMessages}
              data-testid="custom-fields"
            />
            <Text size="small" id="custom_fields_hint">
              {I18n.t('One per line. Format name=value')}
            </Text>
          </div>
        </Flex>
      </RegistrationModalBody>
      <Modal.Footer>
        <Button onClick={props.unregister} margin="small">
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary"
          onClick={props.onNextClicked}
          disabled={isNextDisabled}
          margin="small"
        >
          {props.reviewing ? I18n.t('Back to Review') : I18n.t('Next')}
        </Button>
      </Modal.Footer>
    </>
  )
}
