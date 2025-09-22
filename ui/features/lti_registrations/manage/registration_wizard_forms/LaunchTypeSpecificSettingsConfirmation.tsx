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

import React from 'react'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import type {Lti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {MessageSetting} from '../model/internal_lti_configuration/InternalBaseLaunchSettings'
import {useShallow} from 'zustand/react/shallow'
import {LtiPlacementlessMessageType} from '../model/LtiMessageType'

const I18n = createI18nScope('lti_registrations')

export const launchTypeSpecificSettingsLabels: Record<
  LtiPlacementlessMessageType,
  {
    title: string
    enableLabel: string
    targetLinkUriLabel: string
    customFieldsLabel: string
  }
> = {
  LtiEulaRequest: {
    title: I18n.t('EULA Settings'),
    enableLabel: I18n.t('Enable EULA Request'),
    targetLinkUriLabel: I18n.t('EULA Target Link URI'),
    customFieldsLabel: I18n.t('EULA Custom Fields'),
  },
}

export type LaunchTypeSpecificSettingsConfirmationProps = {
  title?: string
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  settingType: LtiPlacementlessMessageType
}

export const LaunchTypeSpecificSettingsConfirmation = (
  props: LaunchTypeSpecificSettingsConfirmationProps,
) => {
  const {overlayStore, settingType} = props

  // Use the overlay store for message_settings
  const {messageSettings, setMessageSettings} = overlayStore(
    useShallow(state => ({
      messageSettings: state.state.launchSettings.message_settings || [],
      setMessageSettings: state.setMessageSettings,
    })),
  )

  // Track custom fields text separately for better UX
  const [customFieldsTexts, setCustomFieldsTexts] = React.useState<Record<string, string>>({})

  // Get the specific setting for this type, or create a default one
  const setting: MessageSetting = messageSettings.find(s => s.type === settingType) || {
    type: settingType,
    enabled: false,
    target_link_uri: '',
    custom_fields: {},
  }

  const handleSettingChange = (updatedSetting: MessageSetting) => {
    const newMessageSettings = (messageSettings || []).filter(
      (setting: MessageSetting) => setting.type !== updatedSetting.type,
    )
    if (updatedSetting.enabled) {
      newMessageSettings.push(updatedSetting)
    }
    setMessageSettings(newMessageSettings)
  }

  const handleCustomFieldsTextChange = (settingType: string, value: string) => {
    // Update the text immediately for UI responsiveness
    setCustomFieldsTexts(prev => ({...prev, [settingType]: value}))

    // Parse and update the actual setting using the same logic as computeOverlayedCustomFields
    const customFields = value
      ? Object.fromEntries(
          value
            .split('\n')
            .filter(f => !!f)
            .map(customField => {
              const [key, value] = customField.split('=')
              return [key, value]
            }),
        )
      : {}

    handleSettingChange({...setting, custom_fields: customFields})
  }

  const getCustomFieldsText = (): string => {
    // Return the current text being typed, or fall back to the formatted setting
    if (customFieldsTexts[settingType] !== undefined) {
      return customFieldsTexts[settingType]
    }
    return Object.entries(setting.custom_fields || {})
      .map(([key, value]) => `${key}=${value}`)
      .join('\n')
  }

  const labels = launchTypeSpecificSettingsLabels[setting.type as LtiPlacementlessMessageType]

  return (
    <View as="div" key={setting.type} style={{overflow: 'visible'}}>
      <Heading level="h3" margin="0 0 small 0">
        {labels?.title || setting.type}
      </Heading>

      <Flex direction="column" gap="medium">
        <Flex.Item>
          <View as="div" padding="xx-small">
            <Checkbox
              label={labels?.enableLabel || I18n.t('Enable %{type}', {type: setting.type})}
              checked={setting.enabled}
              onChange={e => handleSettingChange({...setting, enabled: e.target.checked})}
            />
          </View>
        </Flex.Item>

        {setting.enabled && (
          <>
            <Flex.Item>
              <TextInput
                renderLabel={labels?.targetLinkUriLabel || I18n.t('Target Link URI')}
                placeholder={I18n.t('Enter target link URI (optional)')}
                value={setting.target_link_uri || ''}
                onChange={e => handleSettingChange({...setting, target_link_uri: e.target.value})}
              />
            </Flex.Item>

            <Flex.Item>
              <TextArea
                label={labels?.customFieldsLabel || I18n.t('Custom Fields')}
                placeholder={I18n.t('Enter custom fields in key=value format, one per line')}
                value={getCustomFieldsText()}
                onChange={e => handleCustomFieldsTextChange(settingType, e.target.value)}
                height="100px"
              />
              <Text size="small" color="secondary">
                {I18n.t('Format: key=value, one per line')}
              </Text>
            </Flex.Item>
          </>
        )}
      </Flex>
    </View>
  )
}
