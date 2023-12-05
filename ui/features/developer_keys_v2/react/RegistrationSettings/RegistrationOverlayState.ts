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
import type {LtiPlacement} from '../../model/LtiPlacements'
import type {LtiMessage, LtiRegistration} from '../../model/LtiRegistration'
import createStore from 'zustand/vanilla'
import type {LtiScope} from '../../model/LtiScopes'
import {subscribeWithSelector} from 'zustand/middleware'

export interface RegistrationOverlayStore extends RegistrationOverlayActions {
  state: RegistrationOverlayState
}

interface RegistrationOverlayActions {
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
  ) => (fn: (placementOverlay: PlacementOverlay) => PlacementOverlay) => void
  resetOverlays: (ltiRegistration: LtiRegistration) => void
}

// fields explicitly not overlayable:
// - Owner Email
// - Redirect URIs
// - Notes
// - Target Link URI
// - OIDC Connect initiation Url
// - JWK Method

// Key-level fields editable:
// - Name

// Registration-level fields not overlayable:
// - Domain
// - Tool Id - wut even is this

// Registration-level fields overlayable:
// - Title
// - Description
// - scopes :check:
// - Subs (in place of privacy_level?) :check:
// - Icon URL
// - Text - wut?
// - Launch Height/Launch Width

// Placement-level fields not overlayable:
//   - Target link uri
//   - Message type

// Placement-level fields overlayable:
// - Enabled/disabled
// - Icon Url
// - Text
// - Launch Height/Launch Width

export interface RegistrationOverlay {
  title?: string
  disabledScopes: Array<LtiScope>
  disabledSubs: Array<string>
  icon_url?: string | null
  launch_height?: string
  launch_width?: string
  disabledPlacements: Array<LtiPlacement>
  placements: Array<PlacementOverlay>
}

export interface PlacementOverlay {
  type: LtiPlacement
  icon_url?: string
  label?: string
  launch_height?: string
  launch_width?: string
}

export type RegistrationOverlayState = {
  developerKeyName?: string
  registration: RegistrationOverlay
}

const updatePlacement =
  (placement_type: LtiPlacement) =>
  (fn: (placementOverlay: PlacementOverlay) => PlacementOverlay) =>
    updateState(state => ({
      ...state,
      registration: {
        ...state.registration,
        placements: state.registration.placements.map(p => (p.type === placement_type ? fn(p) : p)),
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

const updateRegistrationKey =
  <K extends keyof RegistrationOverlay>(key: K) =>
  (f: (prevVal: RegistrationOverlay[K]) => RegistrationOverlay[K]) =>
    updateState(state => ({
      ...state,
      registration: {...state.registration, [key]: f(state.registration[key])},
    }))

const toggleString =
  <S extends string>(s: S) =>
  (strings: Array<S>): Array<S> =>
    strings.includes(s) ? strings.filter(x => x !== s) : [...strings, s]

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
// const updateRegistrationPlacements = (s: string) => updateRegistrationKey('placements')(() => s)
const resetOverlays = (registration: LtiRegistration) =>
  updateState(state =>
    initialOverlayStateFromLtiRegistration(registration, state.developerKeyName, false)
  )

// title?: string
// scopes?: string[]
// subs?: string[]
// icon_url?: string
// launch_height?: string
// launch_width?: string
// placements?: Array<PlacementOverlay>

export const createRegistrationOverlayStore = (
  developerKeyName: string | null,
  ltiRegistration: LtiRegistration,
  applyOverlay: boolean = true
) =>
  createStore<{state: RegistrationOverlayState} & RegistrationOverlayActions>(
    subscribeWithSelector(set => ({
      state: initialOverlayStateFromLtiRegistration(
        ltiRegistration,
        developerKeyName,
        applyOverlay
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
      resetOverlays: (registration: LtiRegistration) => set(resetOverlays(registration)),
      updatePlacement:
        (placement_type: LtiPlacement) =>
        (fn: (placementOverlay: PlacementOverlay) => PlacementOverlay) =>
          set(updatePlacement(placement_type)(fn)),
    }))
  )

const initialOverlayStateFromLtiRegistration = (
  ltiRegistration: LtiRegistration,
  developerKeyName?: string | null,
  applyOverlay: boolean = true
): RegistrationOverlayState => {
  const reg = ltiRegistration

  const valueFor = <A>(value: A, overlayedValue: A | null | undefined): A => {
    const newValue = applyOverlay ? overlayedValue || value : value
    return newValue
  }
  return {
    developerKeyName: developerKeyName || '',
    registration: {
      title: ltiRegistration.client_name,
      icon_url: valueFor(reg.logo_uri, reg.overlay?.icon_url),
      disabledScopes: valueFor([], reg.overlay?.disabledScopes),
      disabledPlacements: valueFor([], reg.overlay?.disabledPlacements),
      disabledSubs: valueFor([], reg.overlay?.disabledSubs),
      // TODO: include launch height/width here when it's available via a canvas extension
      // launch_height: developerKey.lti_registration.lti_tool_configuration.launch_height,
      // launch_width: developerKey.lti_registration.lti_tool_configuration.launch_width,
      launch_height: undefined,
      launch_width: undefined,
      placements: placementsWithOverlay(reg, applyOverlay),
    },
  }
}

const placementsWithOverlay = (reg: LtiRegistration, applyOverlay: boolean) =>
  reg.lti_tool_configuration.messages.flatMap(
    initialPlacementOverlayStateFromMessage(
      reg.overlay?.placements || [],
      reg.overlay?.disabledPlacements || [],
      applyOverlay
    )
  )

const initialPlacementOverlayStateFromMessage =
  (
    placementOverlays: PlacementOverlay[],
    disabledPlacements: LtiPlacement[],
    applyOverlay: boolean
  ) =>
  (message: LtiMessage): Array<PlacementOverlay> =>
    message.placements.map(p => {
      const valueFor = <A>(value: A, overlayedValue: A | null | undefined): A => {
        const newValue = applyOverlay ? overlayedValue || value : value
        return newValue
      }
      const placementOverlay = placementOverlays.find(pl => pl.type === p)
      return {
        enabled: !disabledPlacements.includes(p),
        icon_url: valueFor(message.icon_uri, placementOverlay?.icon_url),
        label: valueFor(message.label, placementOverlay?.label),
        // TODO: include launch height/width here when it's available via a canvas extension
        // launch_height: developerKey.lti_registration.lti_tool_configuration.launch_height,
        // launch_width: developerKey.lti_registration.lti_tool_configuration.launch_width,
        type: p,
        launch_height: valueFor(undefined, placementOverlay?.launch_height),
        launch_width: valueFor(undefined, placementOverlay?.launch_width),
      }
    })
