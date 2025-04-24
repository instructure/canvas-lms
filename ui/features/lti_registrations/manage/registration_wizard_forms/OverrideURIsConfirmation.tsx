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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'
import {
  LtiResourceLinkRequest,
  LtiMessageType,
  isLtiMessageType,
  LtiDeepLinkingRequest,
} from '../model/LtiMessageType'
import {
  LtiPlacement,
  supportsDeepLinkingRequest,
  supportsResourceLinkRequest,
} from '../model/LtiPlacement'
import {isValidHttpUrl} from '../../common/lib/validators/isValidHttpUrl'
import {getInputIdForField} from '../registration_overlay/validateLti1p3RegistrationOverlayState'
import {Lti1p3RegistrationOverlayState} from '../registration_overlay/Lti1p3RegistrationOverlayState'
import {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import {Lti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'

const I18n = createI18nScope('lti_registration.wizard')

export const OverrideURIsConfirmation = React.memo(
  ({internalConfig, overlayStore}: OverrideURIsConfirmationProps) => {
    const {statePlacements, overrides, setOverrideURI, setMessageType} = overlayStore(s => ({
      statePlacements: s.state.placements.placements,
      overrides: s.state.override_uris.placements,
      setOverrideURI: s.setOverrideURI,
      setMessageType: s.setMessageType,
    }))

    const placements = (statePlacements || internalConfig.placements.map(p => p.placement)).sort()

    const [blurStatus, setBlurStatus] = React.useState<Partial<Record<LtiPlacement, boolean>>>({})

    const handleBlur = React.useCallback(
      (placement: LtiPlacement) =>
        (event: React.FocusEvent<HTMLInputElement>): void => {
          setBlurStatus(prev => ({...prev, [placement]: event.target.value.trim() !== ''}))
        },
      [setBlurStatus],
    )

    return (
      <>
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Override URIs')}
        </Heading>
        <Text>
          {I18n.t(
            'Choose to override Default Target Link URIs for each placement. For Deep Linking support, first check with your app vendor to ensure they support this functionality. (Optional)',
          )}
        </Text>
        {placements.map(p => {
          const overrideURI = overrides[p]?.uri || ''
          return (
            <PlacementOverrideURIFormField
              handleBlur={handleBlur}
              wasBlurred={blurStatus[p] ?? false}
              key={p}
              placement={p}
              defaultTargetLinkURI={
                internalConfig.placements.find(r => r.placement === p)?.target_link_uri ||
                internalConfig.target_link_uri
              }
              overrideURI={overrideURI}
              defaultMessageType={overrides[p]?.message_type || LtiResourceLinkRequest}
              onChangeOverrideURI={setOverrideURI}
              onChangeMessageType={setMessageType}
            />
          )
        })}
      </>
    )
  },
)

export type OverrideURIsConfirmationProps = {
  internalConfig: InternalLtiConfiguration
  overlayStore: Lti1p3RegistrationOverlayStore
}

type PlacementOverrideURIFormFieldProps = {
  handleBlur: (placement: LtiPlacement) => (event: React.FocusEvent<HTMLInputElement>) => void
  wasBlurred: boolean
  placement: LtiPlacement
  overrideURI: string
  defaultMessageType: LtiMessageType
  defaultTargetLinkURI: string
  onChangeOverrideURI: (placement: LtiPlacement, uri: string) => void
  onChangeMessageType: (placement: LtiPlacement, messageType: LtiMessageType) => void
}

const messageTypeElement = (props: PlacementOverrideURIFormFieldProps) => {
  const supportsDeepLinking = supportsDeepLinkingRequest(props.placement)
  const supportsResourceLinking = supportsResourceLinkRequest(props.placement)
  if (supportsDeepLinking && supportsResourceLinking) {
    return (
      <RadioInputGroup
        description={I18n.t('Message Type')}
        layout="columns"
        name={`${props.placement}_radio_input_group`}
        defaultValue={props.defaultMessageType}
        onChange={(_, value) => {
          if (isLtiMessageType(value)) {
            props.onChangeMessageType(props.placement, value)
          }
        }}
      >
        <RadioInput value={LtiResourceLinkRequest} label={LtiResourceLinkRequest} />
        <RadioInput value={LtiDeepLinkingRequest} label={LtiDeepLinkingRequest} />
      </RadioInputGroup>
    )
  } else {
    return (
      <>
        <Heading level="h4" margin="0 0 x-small 0">
          {I18n.t('Message Type')}
        </Heading>
        <Text>{supportsDeepLinking ? LtiDeepLinkingRequest : LtiResourceLinkRequest}</Text>
      </>
    )
  }
}

const PlacementOverrideURIFormField = React.memo((props: PlacementOverrideURIFormFieldProps) => {
  return (
    <View margin="medium 0 0 0" as="div">
      <Heading level="h4" margin="0 0 small 0">
        {i18nLtiPlacement(props.placement)}
      </Heading>
      <View padding="0 0 0 small" as="div">
        {messageTypeElement(props)}
        <View margin="small 0 0 0" as="div">
          <TextInput
            id={getInputIdForField(`override_uri_${props.placement}`)}
            renderLabel={I18n.t('Override URI')}
            value={props.overrideURI}
            placeholder={props.defaultTargetLinkURI}
            onChange={e => props.onChangeOverrideURI(props.placement, e.target.value)}
            onBlur={props.handleBlur(props.placement)}
            messages={
              props.overrideURI.trim() === '' ||
              isValidHttpUrl(props.overrideURI) ||
              !props.wasBlurred
                ? []
                : [
                    {
                      type: 'error',
                      text: I18n.t('Invalid URL'),
                    },
                  ]
            }
          />
        </View>
      </View>
    </View>
  )
})
