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
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  canvasPlatformSettings,
  type RegistrationOverlayStore,
} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {usePlacements} from '../hooks/usePlacements'
import {TextInput} from '@instructure/ui-text-input'
import pageNotFoundPandaUrl from '@canvas/images/PageNotFoundPanda.svg'
import {IconImageLine} from '@instructure/ui-icons'
import {
  LtiPlacements,
  LtiPlacementsWithIcons,
  i18nLtiPlacement,
  type LtiPlacementWithIcon,
} from '../../model/LtiPlacement'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import type {DynamicRegistrationActions} from '../DynamicRegistrationWizardState'
import {isValidHttpUrl} from '../../../common/lib/validators/isValidHttpUrl'
import type {FormMessage} from '@instructure/ui-form-field'
import {useDebouncedCallback} from 'use-debounce'
import {Img} from '@instructure/ui-img'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'

const I18n = useI18nScope('lti_registration.wizard')
export type IconConfirmationProps = {
  overlayStore: RegistrationOverlayStore
  registration: LtiImsRegistration
  reviewing: boolean
  transitionToConfirmationState: DynamicRegistrationActions['transitionToConfirmationState']
  transitionToReviewingState: DynamicRegistrationActions['transitionToReviewingState']
}

export const IconConfirmation = ({
  overlayStore,
  registration,
  reviewing,
  transitionToConfirmationState,
  transitionToReviewingState,
}: IconConfirmationProps) => {
  const [overlayState, actions] = useOverlayStore(overlayStore)
  const placements = usePlacements(registration)
  const iconPlacements = React.useMemo(
    () =>
      placements.filter((p): p is LtiPlacementWithIcon =>
        LtiPlacementsWithIcons.includes(p as LtiPlacementWithIcon)
      ),
    [placements]
  )
  const [actualInputValues, setActualInputValues] = React.useState<
    Partial<Record<LtiPlacementWithIcon, string>>
  >(
    iconPlacements.reduce((acc, placement) => {
      const iconUrl = overlayState.registration.placements?.find(
        p => p.type === placement
      )?.icon_url
      return {
        ...acc,
        [placement]: iconUrl ?? '',
      }
    }, {})
  )
  const [debouncedUpdate, _, callPending] = useDebouncedCallback(
    (placement: LtiPlacementWithIcon, value: string) => actions.updateIconUrl(placement, value),
    500
  )

  React.useEffect(() => {
    return () => {
      callPending()
    }
  }, [callPending])

  const renderIconInput = (placement: LtiPlacementWithIcon) => {
    const inputUrl = actualInputValues[placement]

    const defaultIconUrl = canvasPlatformSettings(registration.tool_configuration)?.settings
      .icon_url

    let src = overlayState.registration.placements?.find(p => p.type === placement)?.icon_url
    let messages: FormMessage[] = []
    if (inputUrl && !isValidHttpUrl(inputUrl)) {
      messages = [{type: 'error', text: I18n.t('Invalid URL')}]
    } else if (placement === LtiPlacements.EditorButton && !inputUrl && !defaultIconUrl) {
      src = `${window.location.origin}/lti/tool_default_icon?name=${
        overlayState.adminNickname ?? registration.client_name
      }&id=${registration.developer_key_id}`
      messages = [
        {
          type: 'hint',
          text: I18n.t(
            'If left blank, a default icon resembling the one displayed will be provided. Color may vary.'
          ),
        },
      ]
    } else if (!inputUrl && !defaultIconUrl) {
      messages = [{type: 'hint', text: I18n.t('If left blank, no icon will display.')}]
    } else if (!inputUrl && defaultIconUrl) {
      src = defaultIconUrl
      messages = [
        {type: 'hint', text: I18n.t("If left blank, the tool's default icon will display.")},
      ]
    }

    const imgTitle = I18n.t('%{placement} icon', {
      placement: i18nLtiPlacement(placement),
    })

    return (
      <div key={placement}>
        <TextInput
          renderLabel={<Heading level="h4">{i18nLtiPlacement(placement)}</Heading>}
          placeholder={defaultIconUrl ?? ''}
          renderAfterInput={
            src && isValidHttpUrl(src) ? (
              <div
                style={{
                  overflow: 'hidden',
                  margin: '0.5rem 0',
                  padding: '0.25rem',
                }}
              >
                <Img
                  src={src}
                  alt={imgTitle}
                  loading="lazy"
                  height="2rem"
                  width="2rem"
                  elementRef={ref => {
                    if (ref instanceof HTMLImageElement) {
                      ref.onerror = () => {
                        ref.src = pageNotFoundPandaUrl
                      }
                    }
                  }}
                />
              </div>
            ) : (
              <div
                style={{
                  // The styling here ensures the icon, even with the bonus background from the padding,
                  // appears to be the same size as an actual tool icon
                  padding: '0.25rem',
                  color: 'white',
                  backgroundColor: 'gray',
                  borderRadius: '0.25rem',
                  margin: '0.75rem 0.25rem',
                }}
              >
                <IconImageLine width="1.5rem" height="1.5rem" title={imgTitle} />
              </div>
            )
          }
          value={inputUrl ?? ''}
          onChange={e => {
            setActualInputValues({
              ...actualInputValues,
              [placement]: e.target.value,
            })
            debouncedUpdate(placement, e.target.value)
          }}
          messages={messages}
        />
      </div>
    )
  }

  return (
    <>
      <RegistrationModalBody>
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Icon URLs')}
        </Heading>
        {iconPlacements.length > 0 ? (
          <>
            <Text>{I18n.t('Choose what icon displays in each placement (optional).')}</Text>
            <Flex direction="column" gap="medium" margin="medium 0 medium 0">
              {iconPlacements.map(renderIconInput)}
            </Flex>
          </>
        ) : (
          <Text>{I18n.t("This tool doesn't have any placements with configurable icons.")}</Text>
        )}
      </RegistrationModalBody>
      <Modal.Footer>
        <Button
          margin="small"
          color="secondary"
          type="submit"
          onClick={() => {
            transitionToConfirmationState('IconConfirmation', 'NamingConfirmation', false)
          }}
        >
          {I18n.t('Previous')}
        </Button>
        <Button
          margin="small"
          color="primary"
          type="submit"
          interaction={
            Object.values(actualInputValues).every(v => !v || isValidHttpUrl(v))
              ? 'enabled'
              : 'disabled'
          }
          onClick={() => transitionToReviewingState('IconConfirmation')}
        >
          {reviewing ? I18n.t('Back to Review') : I18n.t('Next')}
        </Button>
      </Modal.Footer>
    </>
  )
}
