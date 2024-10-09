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
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {Lti1p3RegistrationOverlayStore} from '../Lti1p3RegistrationOverlayState'
import {
  type LtiPlacement,
  supportsDeepLinkingRequest,
  supportsResourceLinkRequest,
} from '../../model/LtiPlacement'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {
  isLtiMessageType,
  LtiResourceLinkRequest,
  type LtiMessageType,
  LtiDeepLinkingRequest,
} from '../../model/LtiMessageType'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {View} from '@instructure/ui-view'
import {isValidHttpUrl} from '../../../common/lib/validators/isValidHttpUrl'
import {Modal} from '@instructure/ui-modal'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('lti_registration.wizard')

export type OverrideURIsConfirmationProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  registration: InternalLtiConfiguration
  onNextClicked: () => void
  onPreviousClicked: () => void
}

export const OverrideURIsConfirmation = ({
  overlayStore,
  registration,
  onNextClicked,
  onPreviousClicked,
}: OverrideURIsConfirmationProps) => {
  const [state, {setOverrideURI, setMessageType}] = useOverlayStore(overlayStore)

  const allURIsValid = React.useMemo(
    () => Object.values(state.override_uris.placements).every(p => !p.uri || isValidHttpUrl(p.uri)),
    [state.override_uris.placements]
  )

  const placements = React.useMemo(
    () => (state.placements.placements || registration.placements.map(p => p.placement)).sort(),
    [state.placements.placements, registration.placements]
  )
  const overrides = state.override_uris.placements
  return (
    <>
      <RegistrationModalBody>
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Override URIs')}
        </Heading>
        <Text>
          {I18n.t(
            'Choose to override Default Target Link URIs for each placement. For Deep Linking support, first check with your app vendor to ensure they support this functionality. (Optional)'
          )}
        </Text>
        {placements.map(p => {
          const overrideURI = overrides[p]?.uri || ''
          return (
            <PlacementOverrideURIFormField
              key={p}
              placement={p}
              defaultTargetLinkURI={
                registration.placements.find(r => r.placement === p)?.target_link_uri ||
                registration.target_link_uri
              }
              overrideURI={overrideURI}
              defaultMessageType={LtiResourceLinkRequest}
              onChangeOverrideURI={setOverrideURI}
              onChangeMessageType={setMessageType}
            />
          )
        })}
      </RegistrationModalBody>
      <Modal.Footer>
        <Button onClick={onPreviousClicked} margin="small">
          {I18n.t('Previous')}
        </Button>
        <Button onClick={onNextClicked} color="primary" margin="small" disabled={!allURIsValid}>
          {I18n.t('Next')}
        </Button>
      </Modal.Footer>
    </>
  )
}

type PlacementOverrideURIFormFieldProps = {
  placement: LtiPlacement
  overrideURI: string
  defaultMessageType: LtiMessageType
  defaultTargetLinkURI: string
  onChangeOverrideURI: (placement: LtiPlacement, uri: string) => void
  onChangeMessageType: (placement: LtiPlacement, messageType: LtiMessageType) => void
}

const PlacementOverrideURIFormField = React.memo((props: PlacementOverrideURIFormFieldProps) => {
  let messageTypeComponent: JSX.Element

  const supportsDeepLinking = supportsDeepLinkingRequest(props.placement)
  const supportsResourceLinking = supportsResourceLinkRequest(props.placement)

  if (supportsDeepLinking && supportsResourceLinking) {
    messageTypeComponent = (
      <RadioInputGroup
        description={I18n.t('Message Type')}
        layout="columns"
        name={`${props.placement}_radio_input_group`}
        defaultValue={props.defaultMessageType}
        onChange={(e, value) => {
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
    messageTypeComponent = (
      <>
        <Heading level="h4" margin="0 0 x-small 0">
          {I18n.t('Message Type')}
        </Heading>
        <Text>{supportsDeepLinking ? LtiDeepLinkingRequest : LtiResourceLinkRequest}</Text>
      </>
    )
  }
  return (
    <View margin="medium 0 0 0" as="div">
      <Heading level="h4" margin="0 0 small 0">
        {i18nLtiPlacement(props.placement)}
      </Heading>
      <View padding="0 0 0 small" as="div">
        {messageTypeComponent}
        <View margin="small 0 0 0" as="div">
          <TextInput
            renderLabel={I18n.t('Override URI')}
            value={props.overrideURI}
            placeholder={props.defaultTargetLinkURI}
            onChange={e => props.onChangeOverrideURI(props.placement, e.target.value)}
            messages={
              props.overrideURI.trim() === '' || isValidHttpUrl(props.overrideURI)
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
