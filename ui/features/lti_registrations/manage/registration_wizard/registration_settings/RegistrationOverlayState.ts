/*
 * Copyright (C) 202: I18n.t("$1") - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version : I18n.t("$1") of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import createStore, {type StoreApi} from 'zustand/vanilla'
import {subscribeWithSelector} from 'zustand/middleware'
import type {RegistrationOverlay} from '../../model/RegistrationOverlay'
import type {LtiScope} from '../../model/LtiScope'
import type {LtiPlacement} from '../../model/LtiPlacement'
import type {LtiPlacementOverlay} from '../../model/PlacementOverlay'
import type {LtiConfiguration} from '../../model/lti_tool_configuration/LtiConfiguration'
import type {LtiPrivacyLevel} from '../../model/LtiPrivacyLevel'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import type {LtiPlacementConfig} from '../../model/lti_tool_configuration/LtiPlacementConfig'
import type {Extension} from '../../model/lti_tool_configuration/Extension'

export interface RegistrationOverlayActions {
  updateDevKeyName: (name: string) => void
  updateRegistrationTitle: (s: string) => void
  toggleDisabledScope: (scope: LtiScope) => void
  toggleDisabledPlacement: (scope: LtiPlacement) => void
  toggleDisabledSub: (sub: string) => void
  updateRegistrationIconUrl: (s: string) => void
  updateRegistrationLaunchHeight: (s: string) => void
  updateRegistrationLaunchWidth: (s: string) => void
  updatePlacement: (
    placement_type: LtiPlacement
  ) => (fn: (placementOverlay: LtiPlacementOverlay) => LtiPlacementOverlay) => void
  /**
   * Restore all values to their default values
   * @param configuration The configuration to apply
   */
  resetOverlays: (configuration: LtiConfiguration) => void
  updatePrivacyLevel: (placement_type: LtiPrivacyLevel) => void
  updateDescription: (description: string) => void
  updateAdminNickname: (nickname: string) => void
  updateIconUrl: (placement: LtiPlacement, iconUrl?: string) => void
}

export type RegistrationOverlayState = {
  developerKeyName?: string
  adminNickname?: string
  registration: RegistrationOverlay
}

const updatePlacement =
  (placement_type: LtiPlacement) =>
  (fn: (placementOverlay: LtiPlacementOverlay) => LtiPlacementOverlay) =>
    updateState(state => ({
      ...state,
      registration: {
        ...state.registration,
        placements: (state.registration.placements || []).map(p =>
          p.type === placement_type ? fn(p) : p
        ),
      },
    }))

const stateFor = (state: RegistrationOverlayState) => ({state})

const updateState =
  (f: (state: RegistrationOverlayState) => RegistrationOverlayState) =>
  (fullState: {state: RegistrationOverlayState}): {state: RegistrationOverlayState} =>
    stateFor(f(fullState.state))

const updateDevKeyName = (name: string) =>
  updateState(state => {
    return {...state, developerKeyName: name}
  })

const updatePrivacyLevel = (privacyLevel: LtiPrivacyLevel) =>
  updateState(state => {
    return {...state, registration: {...state.registration, privacy_level: privacyLevel}}
  })

const updateRegistrationKey =
  <K extends keyof RegistrationOverlay>(key: K) =>
  (f: (prevVal: RegistrationOverlay[K]) => RegistrationOverlay[K]) =>
    updateState(state => ({
      ...state,
      registration: {...state.registration, [key]: f(state.registration[key])},
    }))

const toggleString =
  <S extends string>(s: S) =>
  (strings: Array<S> | undefined): Array<S> => {
    if (typeof strings === 'undefined') {
      return [s]
    } else if (strings.includes(s)) {
      return strings.filter(x => x !== s)
    } else {
      return [...strings, s]
    }
  }

const updateRegistrationTitle = (s: string) => updateRegistrationKey('title')(() => s)
const toggleDisabledScope = (scope: LtiScope) =>
  updateRegistrationKey('disabledScopes')(toggleString(scope))
const toggleDisabledPlacement = (placement: LtiPlacement) =>
  updateRegistrationKey('disabledPlacements')(toggleString(placement))
const toggleDisabledSub = (sub: string) => updateRegistrationKey('disabledSubs')(toggleString(sub))
// const updateRegistrationSubs = updateRegistrationKey('subs')
const updateRegistrationIconUrl = (s: string) => updateRegistrationKey('icon_url')(() => s)
const updateRegistrationLaunchHeight = (s: string) =>
  updateRegistrationKey('launch_height')(() => s)
const updateRegistrationLaunchWidth = (s: string) => updateRegistrationKey('launch_width')(() => s)
const updateDescription = (description: string) =>
  updateRegistrationKey('description')(() => description)
const updateAdminNickname = (nickname: string) =>
  updateState(state => {
    return {...state, adminNickname: nickname}
  })
// const updateRegistrationPlacements = (s: string) => updateRegistrationKey('placements')(() => s)
const resetOverlays = (configuration: LtiConfiguration) =>
  updateState(state =>
    initialOverlayStateFromLtiRegistration(configuration, null, state.developerKeyName)
  )

export type RegistrationOverlayStore = StoreApi<
  {
    state: RegistrationOverlayState
  } & RegistrationOverlayActions
>

export const createRegistrationOverlayStore = (
  developerKeyName: string | null,
  ltiRegistration: LtiImsRegistration
): StoreApi<
  {
    state: RegistrationOverlayState
  } & RegistrationOverlayActions
> =>
  createStore<{state: RegistrationOverlayState} & RegistrationOverlayActions>(
    subscribeWithSelector(set => ({
      state: initialOverlayStateFromLtiRegistration(
        ltiRegistration.tool_configuration,
        ltiRegistration.overlay,
        developerKeyName
      ),
      updateDevKeyName: (name: string) =>
        set(state => {
          const updatedState = updateDevKeyName(name)(state)
          return updatedState
        }),
      updateRegistrationTitle: (s: string) => set(updateRegistrationTitle(s)),
      toggleDisabledScope: (scope: LtiScope) => set(state => toggleDisabledScope(scope)(state)),
      toggleDisabledPlacement: (placement: LtiPlacement) =>
        set(state => toggleDisabledPlacement(placement)(state)),
      toggleDisabledSub: (sub: string) => set(state => toggleDisabledSub(sub)(state)),
      updateRegistrationIconUrl: (s: string) => set(state => updateRegistrationIconUrl(s)(state)),
      updateRegistrationLaunchHeight: (s: string) =>
        set(state => updateRegistrationLaunchHeight(s)(state)),
      updateRegistrationLaunchWidth: (s: string) =>
        set(state => updateRegistrationLaunchWidth(s)(state)),
      resetOverlays: (configuration: LtiConfiguration) => set(resetOverlays(configuration)),
      updatePlacement:
        (placement_type: LtiPlacement) =>
        (fn: (placementOverlay: LtiPlacementOverlay) => LtiPlacementOverlay) =>
          set(updatePlacement(placement_type)(fn)),
      updatePrivacyLevel: (privacyLevel: LtiPrivacyLevel) => set(updatePrivacyLevel(privacyLevel)),
      updateDescription: (description: string) => set(updateDescription(description)),
      updateAdminNickname: (nickname: string) => set(updateAdminNickname(nickname)),
      updateIconUrl: (placement: LtiPlacement, iconUrl?: string) =>
        set(state =>
          updatePlacement(placement)(placementOverlay => ({
            ...placementOverlay,
            icon_url: iconUrl,
          }))(state)
        ),
    }))
  )

const initialOverlayStateFromLtiRegistration = (
  configuration: LtiConfiguration,
  overlay?: RegistrationOverlay | null,
  developerKeyName?: string | null
): RegistrationOverlayState => {
  return {
    developerKeyName: developerKeyName || '',
    registration: {
      title: configuration.title,
      icon_url: overlay?.icon_url || configuration.icon_url,
      disabledScopes: overlay?.disabledScopes || [],
      disabledPlacements: overlay?.disabledPlacements || [],
      disabledSubs: overlay?.disabledSubs || [],
      // TODO: include launch height/width here when it's available via a canvas extension
      // launch_height: developerKey.lti_registration.lti_tool_configuration.launch_height,
      // launch_width: developerKey.lti_registration.lti_tool_configuration.launch_width,
      launch_height: undefined,
      launch_width: undefined,
      placements: placementsWithOverlay(configuration, overlay),
      privacy_level:
        overlay?.privacy_level ||
        canvasPlatformSettings(configuration)?.privacy_level ||
        'anonymous',
    },
  }
}

export const canvasPlatformSettings = (configuration: LtiConfiguration): Extension | undefined =>
  configuration.extensions?.find(e => e.platform === 'canvas.instructure.com')

const placementsWithOverlay = (
  configuration: LtiConfiguration,
  overlay?: RegistrationOverlay | null
) =>
  canvasPlatformSettings(configuration)?.settings.placements.flatMap(
    initialPlacementOverlayStateFromPlacementConfig(overlay?.placements || [])
  ) || []

const initialPlacementOverlayStateFromPlacementConfig =
  (placementOverlays: LtiPlacementOverlay[] = []) =>
  (placementConfig: LtiPlacementConfig): LtiPlacementOverlay => {
    const placementOverlay = placementOverlays.find(pl => pl.type === placementConfig.placement)
    return {
      icon_url: placementOverlay?.icon_url || placementConfig.icon_url,
      label: placementOverlay?.label || placementConfig.text,
      // TODO: include launch height/width here when it's available via a canvas extension
      // launch_height: developerKey.lti_registration.lti_tool_configuration.launch_height,
      // launch_width: developerKey.lti_registration.lti_tool_configuration.launch_width,
      type: placementConfig.placement as LtiPlacement,
      launch_height: placementOverlay?.launch_height || undefined,
      launch_width: placementOverlay?.launch_width || undefined,
      default: placementConfig.default || undefined,
    }
  }
