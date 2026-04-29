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
import {IconImageLine, IconAddSolid} from '@instructure/ui-icons'
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
import type {LtiRegistrationUpdateRequest} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import type {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import {diffPlacements} from '../model/placementDiffer'

const I18n = createI18nScope('lti_registration.wizard')
export interface IconConfirmationProps {
  internalConfig: InternalLtiConfiguration
  name: string
  developerKeyId?: DeveloperKeyId
  allPlacements: readonly LtiPlacement[]
  placementIconOverrides: Partial<Record<LtiPlacementWithIcon, string>>
  setPlacementIconUrl: (placement: LtiPlacementWithIcon, iconUrl: string) => void
  defaultIconUrl?: string
  setDefaultIconUrl: (iconUrl: string) => void
  hasSubmitted: boolean
  registrationUpdateRequest?: LtiRegistrationUpdateRequest
  existingRegistration?: LtiRegistrationWithConfiguration
}

export const IconConfirmation = React.memo(
  ({
    name,
    internalConfig,
    developerKeyId,
    allPlacements,
    placementIconOverrides,
    setPlacementIconUrl,
    defaultIconUrl,
    setDefaultIconUrl,
    hasSubmitted,
    registrationUpdateRequest,
    existingRegistration,
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

    // Compute added and removed placements using the differ utility
    const {added: addedPlacements} = React.useMemo(
      () => diffPlacements(existingRegistration, registrationUpdateRequest),
      [existingRegistration, registrationUpdateRequest],
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

    const existingPlacementsWithIcons = React.useMemo(
      () => placementsWithIcons.filter(p => !addedPlacements.includes(p)),
      [placementsWithIcons, addedPlacements],
    )

    const newlyAddedPlacementsWithIcons = React.useMemo(
      () => placementsWithIcons.filter(p => addedPlacements.includes(p)),
      [placementsWithIcons, addedPlacements],
    )

    const [placementImgValues, setPlacementImgValues] =
      React.useState<Partial<Record<LtiPlacementWithIcon, string>>>(placementIconOverrides)

    const [defaultIconImgValue, setDefaultIconImgValue] = React.useState<string | undefined>(
      defaultIconUrl,
    )

    const [defaultIconBlurred, setDefaultIconBlurred] = React.useState(false)

    const debouncedImgUrlsUpdate = useDebouncedCallback(
      (placement: LtiPlacementWithIcon, value: string) =>
        setPlacementImgValues(prev => ({...prev, [placement]: value})),
      500,
    )

    const debouncedDefaultIconUpdate = useDebouncedCallback((value: string) => {
      setDefaultIconImgValue(value)
    }, 500)

    const updateIconUrl = React.useCallback(
      (placement: LtiPlacementWithIcon, value: string) => {
        setPlacementIconUrl(placement, value)
        debouncedImgUrlsUpdate(placement, value)
      },
      [debouncedImgUrlsUpdate, setPlacementIconUrl],
    )

    const updateDefaultIconUrl = React.useCallback(
      (value: string) => {
        setDefaultIconUrl(value)
        debouncedDefaultIconUpdate(value)
      },
      [debouncedDefaultIconUpdate, setDefaultIconUrl],
    )

    React.useEffect(() => {
      return () => {
        debouncedImgUrlsUpdate.flush()
        debouncedDefaultIconUpdate.flush()
      }
    }, [debouncedImgUrlsUpdate, debouncedDefaultIconUpdate])

    return (
      <>
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Tool Icon URL')}
        </Heading>
        <Text>
          {I18n.t("Choose the tool's default icon and its icon on the Apps page (optional).")}
        </Text>
        <div style={{marginTop: '1rem', marginBottom: '1rem'}}>
          <DefaultIconUrlInput
            defaultIconUrl={internalConfig.launch_settings?.icon_url}
            inputUrl={defaultIconUrl}
            imageUrl={defaultIconImgValue}
            onInputUrlChange={updateDefaultIconUrl}
            showErrors={defaultIconBlurred || hasSubmitted}
            onBlur={() => setDefaultIconBlurred(true)}
          />
        </div>
        <Heading level="h3" margin="medium 0 x-small 0">
          {I18n.t('Placement Icon URLs')}
        </Heading>
        {placementsWithIcons.length > 0 ? (
          <>
            <Text>{I18n.t('Choose what icon displays in each placement (optional).')}</Text>
            {existingPlacementsWithIcons.length > 0 && (
              <Flex direction="column" gap="medium" margin="medium 0 medium 0">
                {existingPlacementsWithIcons.map(placement => {
                  // prefer the placement-specific icon, but fall back to the top-level default
                  const defaultIcon =
                    internalConfig.placements?.find(p => p.placement === placement)?.icon_url ||
                    defaultIconUrl
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
            )}
            {newlyAddedPlacementsWithIcons.length > 0 && (
              <Flex direction="column" alignItems="start" gap="small" margin="small 0 medium 0">
                <Heading level="h4" margin="0 0 x-small 0">
                  <Flex direction="row" gap="small">
                    <IconAddSolid />
                    {I18n.t('Added')}
                  </Flex>
                </Heading>
                <Flex direction="column" gap="medium" width="100%">
                  {newlyAddedPlacementsWithIcons.map(placement => {
                    // prefer the placement-specific icon, but fall back to the top-level default
                    const defaultIcon =
                      internalConfig.placements?.find(p => p.placement === placement)?.icon_url ||
                      defaultIconUrl
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
              </Flex>
            )}
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

type DefaultIconUrlInputProps = {
  defaultIconUrl?: string
  inputUrl?: string
  imageUrl?: string
  onInputUrlChange: (value: string) => void
  onBlur: () => void
  showErrors: boolean
}

const DefaultIconUrlInput = React.memo(
  ({
    defaultIconUrl,
    inputUrl,
    imageUrl,
    onInputUrlChange,
    onBlur,
    showErrors,
  }: DefaultIconUrlInputProps) => {
    let messages: FormMessage[] = []
    if (inputUrl && !isValidHttpUrl(inputUrl) && showErrors) {
      messages = [{type: 'error', text: I18n.t('Invalid URL')}]
    }

    const imgTitle = I18n.t('Tool icon')
    const renderedImageUrl = imageUrl?.trim() || defaultIconUrl

    return (
      <TextInput
        id={getInputIdForField('default_icon_url')}
        onBlur={onBlur}
        renderLabel={I18n.t('Tool Icon URL')}
        placeholder={defaultIconUrl}
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
                data-testid="img-default-icon"
                alt={imgTitle}
                loading="lazy"
                height="2rem"
                width="2rem"
              />
            </div>
          ) : (
            <div
              style={{
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
        onChange={e => onInputUrlChange(e.target.value)}
        messages={messages}
      />
    )
  },
)

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
