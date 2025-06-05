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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import pageNotFoundPandaUrl from '@canvas/images/PageNotFoundPanda.svg'
import {IconImageLine} from '@instructure/ui-icons'
import {isValidHttpUrl} from '../../common/lib/validators/isValidHttpUrl'
import type {FormMessage} from '@instructure/ui-form-field'
import {useDebouncedCallback} from 'use-debounce'
import {Img} from '@instructure/ui-img'
import {
  isLtiPlacementWithDefaultIcon,
  LtiPlacementsWithIcons,
  type LtiPlacement,
  type LtiPlacementWithIcon,
} from '../model/LtiPlacement'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import {ltiToolDefaultIconUrl} from '../model/ltiToolIcons'
import {getInputIdForField} from '../registration_overlay/validateLti1p3RegistrationOverlayState'

const I18n = createI18nScope('lti_registration.wizard')
export interface IconConfirmationProps {
  internalConfig: InternalLtiConfiguration
  name: string
  developerKeyId?: DeveloperKeyId
  allPlacements: readonly LtiPlacement[]
  placementIconOverrides: Partial<Record<LtiPlacementWithIcon, string>>
  setPlacementIconUrl: (placement: LtiPlacementWithIcon, iconUrl: string) => void
  hasSubmitted: boolean
}

export const IconConfirmation = React.memo(
  ({
    name,
    internalConfig,
    developerKeyId,
    allPlacements,
    placementIconOverrides,
    setPlacementIconUrl,
    hasSubmitted,
  }: IconConfirmationProps) => {
    const [blurStatus, setBlurStatus] = React.useState<
      Partial<Record<LtiPlacementWithIcon, boolean>>
    >({})

    const handleBlur = React.useCallback(
      (placement: LtiPlacementWithIcon) =>
        (event: React.FocusEvent<HTMLInputElement>): void => {
          setBlurStatus(prev => ({...prev, [placement]: event.currentTarget.value.trim() !== ''}))
        },
      [setBlurStatus],
    )

    const placementsWithIcons = React.useMemo(
      () =>
        allPlacements
          .toSorted()
          .filter((p): p is LtiPlacementWithIcon =>
            LtiPlacementsWithIcons.includes(p as LtiPlacementWithIcon),
          ),
      [allPlacements],
    )

    const [placementImgValues, setPlacementImgValues] =
      React.useState<Partial<Record<LtiPlacementWithIcon, string>>>(placementIconOverrides)

    const debouncedImgUrlsUpdate = useDebouncedCallback(
      (placement: LtiPlacementWithIcon, value: string) =>
        setPlacementImgValues(prev => ({...prev, [placement]: value})),
      500,
    )

    const updateIconUrl = React.useCallback(
      (placement: LtiPlacementWithIcon, value: string) => {
        setPlacementIconUrl(placement, value)
        debouncedImgUrlsUpdate(placement, value)
      },
      [debouncedImgUrlsUpdate, setPlacementIconUrl],
    )

    React.useEffect(() => {
      return () => {
        debouncedImgUrlsUpdate.flush()
      }
    }, [debouncedImgUrlsUpdate])

    return (
      <>
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Icon URLs')}
        </Heading>
        {placementsWithIcons.length > 0 ? (
          <>
            <Text>{I18n.t('Choose what icon displays in each placement (optional).')}</Text>
            <Flex direction="column" gap="medium" margin="medium 0 medium 0">
              {placementsWithIcons.map(placement => {
                // prefer the placement-specific icon, but fall back to the top-level default
                const defaultIcon =
                  internalConfig.placements?.find(p => p.placement === placement)?.icon_url ??
                  internalConfig.launch_settings?.icon_url
                return (
                  <IconOverrideInput
                    handleBlur={handleBlur}
                    showErrors={(blurStatus[placement] ?? false) || hasSubmitted}
                    key={placement}
                    placement={placement}
                    toolName={name}
                    defaultIconUrl={defaultIcon}
                    developerKeyId={developerKeyId}
                    inputUrl={placementIconOverrides[placement]}
                    imageUrl={placementImgValues[placement]}
                    onInputUrlChange={updateIconUrl}
                  />
                )
              })}
            </Flex>
          </>
        ) : (
          <Text>{I18n.t("This tool doesn't have any placements with configurable icons.")}</Text>
        )}
      </>
    )
  },
)

type IconOverrideInputProps = {
  placement: LtiPlacementWithIcon
  toolName: string
  defaultIconUrl?: string
  developerKeyId?: DeveloperKeyId
  inputUrl?: string
  imageUrl?: string
  onInputUrlChange: (placement: LtiPlacementWithIcon, value: string) => void
  handleBlur: (
    placement: LtiPlacementWithIcon,
  ) => (event: React.FocusEvent<HTMLInputElement>) => void
  showErrors: boolean
}

const IconOverrideInput = React.memo(
  ({
    handleBlur,
    showErrors,
    placement,
    toolName,
    defaultIconUrl,
    developerKeyId,
    inputUrl,
    imageUrl,
    onInputUrlChange,
  }: IconOverrideInputProps) => {
    let messages: FormMessage[] = []
    if (inputUrl && !isValidHttpUrl(inputUrl) && showErrors) {
      messages = [{type: 'error', text: I18n.t('Invalid URL')}]
    } else if (isLtiPlacementWithDefaultIcon(placement) && !inputUrl && !defaultIconUrl) {
      imageUrl = ltiToolDefaultIconUrl({
        base: window.location.origin,
        toolName,
        developerKeyId,
      })
      messages = [
        {
          type: 'hint',
          text: I18n.t(
            'If left blank, a default icon resembling the one displayed will be provided. Color may vary.',
          ),
        },
      ]
    } else if (!inputUrl && !defaultIconUrl) {
      messages = [{type: 'hint', text: I18n.t('If left blank, no icon will display.')}]
    } else if (!inputUrl && defaultIconUrl) {
      imageUrl = defaultIconUrl
      messages = [
        {type: 'hint', text: I18n.t("If left blank, the tool's default icon will display.")},
      ]
    }

    const imgTitle = I18n.t('%{placement} icon', {
      placement: i18nLtiPlacement(placement),
    })

    const renderedImageUrl = imageUrl ?? defaultIconUrl

    const onBlur = React.useMemo(() => handleBlur(placement), [handleBlur, placement])

    return (
      <div key={placement}>
        <TextInput
          id={getInputIdForField(`icon_uri_${placement}`)}
          onBlur={onBlur}
          renderLabel={<Heading level="h4">{i18nLtiPlacement(placement)}</Heading>}
          placeholder={defaultIconUrl ?? ''}
          renderAfterInput={
            renderedImageUrl && isValidHttpUrl(renderedImageUrl) ? (
              <div
                style={{
                  overflow: 'hidden',
                  margin: '0.5rem 0',
                  padding: '0.25rem',
                }}
              >
                <Img
                  src={renderedImageUrl}
                  data-testid={`img-icon-${placement}`}
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
          onChange={e => onInputUrlChange(placement, e.target.value)}
          messages={messages}
        />
      </div>
    )
  },
)
