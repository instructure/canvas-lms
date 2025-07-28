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
import {createStore, type StoreApi} from 'zustand/vanilla'
import {subscribeWithSelector} from 'zustand/middleware'
import type {LtiScope} from '@canvas/lti/model/LtiScope'
import type {LtiPlacement} from '../model/LtiPlacement'
import type {LtiPrivacyLevel} from '../model/LtiPrivacyLevel'
import type {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import type {
  LtiConfigurationOverlay,
  LtiPlacementOverlay,
} from '../model/internal_lti_configuration/LtiConfigurationOverlay'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import {toUndefined} from '../../common/lib/toUndefined'
import type {InternalPlacementConfiguration} from '../model/internal_lti_configuration/placement_configuration/InternalPlacementConfiguration'

export interface DynamicRegistrationOverlayActions {
  updateDevKeyName: (name: string) => void
  updateRegistrationTitle: (s: string) => void
  toggleDisabledScope: (scope: LtiScope) => void
  toggleDisabledPlacement: (placement: LtiPlacement) => void
  updatePlacement: (
    placement_type: LtiPlacement,
  ) => (fn: (placementOverlay: LtiPlacementOverlay) => LtiPlacementOverlay) => void
  updatePrivacyLevel: (placement_type: LtiPrivacyLevel) => void
  updateDescription: (description: string) => void
  updateAdminNickname: (nickname: string) => void
  updateIconUrl: (placement: LtiPlacement, iconUrl?: string) => void
}

export type DynamicRegistrationOverlayState = {
  developerKeyName?: string
  adminNickname?: string
  overlay: LtiConfigurationOverlay
}

const updatePlacement =
  (placement_type: LtiPlacement) =>
  (fn: (placementOverlay: LtiPlacementOverlay) => LtiPlacementOverlay) =>
    updateState(state => ({
      ...state,
      overlay: {
        ...state.overlay,
        placements: {
          ...state.overlay.placements,
          [placement_type]: fn(state.overlay.placements?.[placement_type] || {}),
        },
      },
    }))

const stateFor = (state: DynamicRegistrationOverlayState) => ({state})

const updateState =
  (f: (state: DynamicRegistrationOverlayState) => DynamicRegistrationOverlayState) =>
  (fullState: {state: DynamicRegistrationOverlayState}): {state: DynamicRegistrationOverlayState} =>
    stateFor(f(fullState.state))

const updateDevKeyName = (name: string) =>
  updateState(state => {
    return {...state, developerKeyName: name}
  })

const updatePrivacyLevel = (privacyLevel: LtiPrivacyLevel) =>
  updateState(state => {
    return {...state, overlay: {...state.overlay, privacy_level: privacyLevel}}
  })

const updateRegistrationKey =
  <K extends keyof LtiConfigurationOverlay>(key: K) =>
  (f: (prevVal: LtiConfigurationOverlay[K]) => LtiConfigurationOverlay[K]) =>
    updateState(state => ({
      ...state,
      overlay: {...state.overlay, [key]: f(state.overlay[key])},
    }))

const toggleString =
  <S extends string>(s: S) =>
  (strings: Array<S> | null | undefined): Array<S> => {
    if (typeof strings === 'undefined' || strings === null) {
      return [s]
    } else if (strings.includes(s)) {
      return strings.filter(x => x !== s)
    } else {
      return [...strings, s]
    }
  }

const updateRegistrationTitle = (s: string) => updateRegistrationKey('title')(() => s)
const toggleDisabledScope = (scope: LtiScope) =>
  updateRegistrationKey('disabled_scopes')(toggleString(scope))
const toggleDisabledPlacement = (placement: LtiPlacement) =>
  updateRegistrationKey('disabled_placements')(toggleString(placement))
const updateDescription = (description: string) =>
  updateRegistrationKey('description')(() => description)
const updateAdminNickname = (nickname: string) =>
  updateState(state => {
    return {...state, adminNickname: nickname}
  })

export type DynamicRegistrationOverlayStore = StoreApi<
  {
    state: DynamicRegistrationOverlayState
  } & DynamicRegistrationOverlayActions
>

export const createDynamicRegistrationOverlayStore = (
  developerKeyName: string | null,
  ltiRegistration: LtiRegistrationWithConfiguration,
): StoreApi<
  {
    state: DynamicRegistrationOverlayState
  } & DynamicRegistrationOverlayActions
> =>
  createStore<{state: DynamicRegistrationOverlayState} & DynamicRegistrationOverlayActions>()(
    subscribeWithSelector(set => ({
      state: initialOverlayStateFromLtiRegistration(
        ltiRegistration,
        ltiRegistration.overlay?.data,
        developerKeyName,
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
          }))(state),
        ),
    })),
  )

const initialOverlayStateFromLtiRegistration = (
  registration: LtiRegistrationWithConfiguration,
  overlay?: LtiConfigurationOverlay | null,
  developerKeyName?: string | null,
): DynamicRegistrationOverlayState => {
  return {
    adminNickname: toUndefined(registration.admin_nickname),
    developerKeyName: developerKeyName || '',
    overlay: {
      description: toUndefined(overlay?.description || registration.configuration.description),
      title: toUndefined(overlay?.title || registration.configuration.title),
      disabled_scopes: overlay?.disabled_scopes || [],
      disabled_placements: overlay?.disabled_placements || [],
      placements: placementsWithOverlay(registration.configuration, overlay),
      privacy_level:
        overlay?.privacy_level || registration.configuration.privacy_level || 'anonymous',
    },
  }
}

const placementsWithOverlay = (
  configuration: InternalLtiConfiguration,
  overlay?: LtiConfigurationOverlay | null,
) => {
  return Object.fromEntries(
    configuration.placements.map(p => [
      p.placement,
      initialPlacementOverlayStateFromPlacementConfig(overlay?.placements || {})(p),
    ]),
  )
}
const initialPlacementOverlayStateFromPlacementConfig =
  (placementOverlays: LtiConfigurationOverlay['placements'] = {}) =>
  (placementConfig: InternalPlacementConfiguration): LtiPlacementOverlay => {
    const placementOverlay = placementOverlays[placementConfig.placement]
    return {
      icon_url: toUndefined(placementOverlay?.icon_url || placementConfig.icon_url),
      text: toUndefined(placementOverlay?.text || placementConfig.text),
      launch_height: toUndefined(
        placementOverlay?.launch_height || placementConfig.launch_height?.toString(),
      ),
      launch_width: toUndefined(
        placementOverlay?.launch_width || placementConfig.launch_width?.toString(),
      ),
      default: toUndefined(placementOverlay?.default || placementConfig.default),
    }
  }
