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

import {create} from 'zustand'
import {
  type ApiResult,
  formatApiResultError,
  isSuccessful,
  UnsuccessfulApiResult,
} from '../../common/lib/apiResult/ApiResult'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'
import type {LtiRegistrationWithAllInformation} from '../model/LtiRegistration'
import {
  createLti1p3RegistrationOverlayStore,
  type Lti1p3RegistrationOverlayStore,
} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import type {AccountId} from '../model/AccountId'
import {LtiRegistrationId} from '../model/LtiRegistrationId'
import type {InheritedKeyService} from './InheritedKeyService'

const InheritedKeyWizardStepOrder = [
  'LaunchSettings',
  'Permissions',
  'DataSharing',
  'Placements',
  'OverrideURIs',
  'Naming',
  'Icons',
  'Review',
] as const

export type InheritedKeyWizardStep = (typeof InheritedKeyWizardStepOrder)[number]

export const isInheritedStep = (step: string): step is InheritedKeyWizardStep => {
  return InheritedKeyWizardStepOrder.includes(step as InheritedKeyWizardStep)
}

export const isReviewingState = (state: InheritedKeyWizardState): boolean => {
  return isInheritedStep(state._type)
}

/**
 * Actions for the inherited key registration modal
 */
export interface InheritedKeyActions {
  open: (
    developerKeyId: DeveloperKeyId,
    onSuccessfulInstallation: OnSuccessfulInstallation,
    accountId?: AccountId,
  ) => void
  close: () => void
  registerDependencies: (
    service: InheritedKeyService,
    accountId: AccountId,
    onInstallSuccess: () => void,
    onInstallError: (error: UnsuccessfulApiResult) => void,
  ) => void
  loaded: (result: ApiResult<LtiRegistrationWithAllInformation>) => void
  install: () => Promise<void>
  error: (result: ApiResult<LtiRegistrationWithAllInformation>) => void
  advanceStep: () => void
  previousStep: () => void
  transitionToCustomizationState: (newState: InheritedKeyWizardStep) => void
}

export type CustomizationState<Tag extends InheritedKeyWizardStep> = {
  _type: Tag
  registration: LtiRegistrationWithAllInformation
  overlayStore: Lti1p3RegistrationOverlayStore
  open: boolean
  reviewing: boolean
  onSuccessfulInstallation: OnSuccessfulInstallation
  service: InheritedKeyService
  onInstallSuccess: () => void
  onInstallError: (error: UnsuccessfulApiResult) => void
}

export type OnSuccessfulInstallation = (id: LtiRegistrationId, name?: string) => void

export type InheritedKeyWizardState = {
  open: boolean
  reviewing: boolean
  onSuccessfulInstallation: OnSuccessfulInstallation
  onInstallSuccess: () => void
  onInstallError: (error: UnsuccessfulApiResult) => void
  service: InheritedKeyService
  developerKeyId?: DeveloperKeyId
  accountId?: AccountId
} & (
  | {
      _type: 'Initial'
    }
  | {
      _type: 'Error'
      result: ApiResult<LtiRegistrationWithAllInformation>
    }
  // old version when flag is off
  | {
      _type: 'RequestingRegistration'
    }
  | {
      _type: 'RegistrationLoaded'
      result: ApiResult<LtiRegistrationWithAllInformation>
    }
  // new version when flag is on
  | CustomizationState<'LaunchSettings'>
  | CustomizationState<'Permissions'>
  | CustomizationState<'DataSharing'>
  | CustomizationState<'Placements'>
  | CustomizationState<'OverrideURIs'>
  | CustomizationState<'Icons'>
  | CustomizationState<'Naming'>
  | CustomizationState<'Review'>
  | {
      _type: 'Installing'
      registration: LtiRegistrationWithAllInformation
      overlayStore?: Lti1p3RegistrationOverlayStore
    }
)

type StateUpdater = (
  updater: (s: {state: InheritedKeyWizardState} & InheritedKeyActions) => {
    state: InheritedKeyWizardState
  },
) => void

/**
 * Creates a Zustand store for the inherited key registration modal
 */
export const useInheritedKeyWizardState = create<
  {state: InheritedKeyWizardState} & InheritedKeyActions
>((set: StateUpdater, get) => {
  const modifyState = (f: (prev: InheritedKeyWizardState) => InheritedKeyWizardState) => {
    set(({state}) => ({state: f(state)}))
  }
  return {
    state: {
      _type: 'Initial',
      open: false,
      reviewing: false,
      developerKeyId: undefined,
      accountId: undefined,
      // callback for the caller
      onSuccessfulInstallation: () => {},
      // callbacks for the UI
      onInstallSuccess: () => {},
      onInstallError: () => {},
      service: {} as InheritedKeyService,
    },
    open: async (
      developerKeyId: DeveloperKeyId,
      onSuccessfulInstallation: OnSuccessfulInstallation,
      accountId?: AccountId,
    ) => {
      modifyState(state => ({
        ...state,
        _type: 'RequestingRegistration',
        open: true,
        reviewing: false,
        developerKeyId,
        onSuccessfulInstallation,
        accountId: accountId || state.accountId,
      }))

      const currentState = get().state
      if (
        currentState._type === 'RequestingRegistration' &&
        currentState.developerKeyId &&
        currentState.accountId
      ) {
        const result = await currentState.service.fetchRegistrationByClientId(
          currentState.accountId,
          currentState.developerKeyId,
        )
        get().loaded(result)
      }
    },
    close: () => {
      modifyState(state => ({...state, open: false}))
    },
    registerDependencies: (
      service: InheritedKeyService,
      accountId: AccountId,
      onInstallSuccess: () => void,
      onInstallError: (error: UnsuccessfulApiResult) => void,
    ) => {
      modifyState(state => ({
        ...state,
        service,
        accountId: accountId || state.accountId,
        onInstallSuccess,
        onInstallError,
      }))
    },
    error: result => {
      console.error('Failed to install app', formatApiResultError(result as UnsuccessfulApiResult))
      modifyState(state => ({...state, _type: 'Error', result}))
    },
    loaded: result => {
      if (!isSuccessful(result)) {
        get().error(result)
        get().close()
        return
      }

      modifyState(state => {
        if (state._type !== 'RequestingRegistration') {
          return state
        }

        if (!window.ENV?.FEATURES?.lti_registrations_templates) {
          // Old behavior: go to RegistrationLoaded
          return {
            ...state,
            _type: 'RegistrationLoaded' as const,
            result,
          }
        }

        // New behavior: create overlay store and start multi-step wizard
        const overlayStore = createLti1p3RegistrationOverlayStore(
          result.data.overlaid_configuration,
          result.data.admin_nickname || result.data.name,
          result.data.overlay?.data,
        )

        return {
          ...state,
          _type: 'LaunchSettings' as const,
          registration: result.data,
          overlayStore,
          reviewing: false,
        }
      })
    },
    install: async () => {
      modifyState(state => {
        if (state._type === 'RegistrationLoaded') {
          if (isSuccessful(state.result)) {
            return {
              ...state,
              _type: 'Installing' as const,
              registration: state.result.data,
            }
          }
          return state
        } else if (state._type === 'Review') {
          return {
            ...state,
            _type: 'Installing' as const,
          }
        }
        return state
      })

      const currentState = get().state
      if (currentState._type !== 'Installing' || !currentState.accountId) {
        return
      }

      const result = await currentState.service.installInheritedRegistration({
        accountId: currentState.accountId,
        registration: currentState.registration,
        overlayStore: currentState.overlayStore,
        service: currentState.service,
      })

      if (result._type === 'Success') {
        currentState.onInstallSuccess()
        currentState.onSuccessfulInstallation?.(result.registrationId, result.registrationName)
        get().close()
      } else {
        currentState.onInstallError(result)
        get().error(result)
      }
    },
    advanceStep: () => {
      const currentState = get().state
      if (currentState._type === 'Review') {
        // Final step, trigger install
        get().install()
      } else if (isReviewingState(currentState)) {
        const customizationState = currentState as CustomizationState<InheritedKeyWizardStep>
        // support "Back to Review"
        if (customizationState.reviewing) {
          modifyState(() => ({
            ...customizationState,
            reviewing: true,
            _type: 'Review' as const,
          }))
          return
        }

        const currentStepIndex = InheritedKeyWizardStepOrder.indexOf(customizationState._type)
        const candidateStepIndex = currentStepIndex + 1
        modifyState(() => ({
          ...customizationState,
          _type:
            candidateStepIndex < InheritedKeyWizardStepOrder.length
              ? InheritedKeyWizardStepOrder[candidateStepIndex]
              : customizationState._type,
        }))
      }
    },
    previousStep: () => {
      const currentState = get().state
      if (!isReviewingState(currentState)) return

      const customizationState = currentState as CustomizationState<InheritedKeyWizardStep>

      const currentStepIndex = InheritedKeyWizardStepOrder.indexOf(customizationState._type)
      const candidateStepIndex = currentStepIndex - 1
      const previousStep =
        candidateStepIndex >= 0
          ? InheritedKeyWizardStepOrder[candidateStepIndex]
          : InheritedKeyWizardStepOrder[0]

      modifyState(() => ({
        ...customizationState,
        _type: previousStep,
        reviewing: false,
      }))
    },
    transitionToCustomizationState: (newState: InheritedKeyWizardStep) => {
      const currentState = get().state
      if (!isReviewingState(currentState)) return

      modifyState(() => ({
        ...(currentState as CustomizationState<InheritedKeyWizardStep>),
        reviewing: true,
        _type: newState,
      }))
    },
  }
})

const inheritedKeyState = useInheritedKeyWizardState.getState()

export const openInheritedKeyWizard = (
  developerKeyId: DeveloperKeyId,
  onSuccessfulInstallation: OnSuccessfulInstallation,
  accountId?: AccountId,
) => {
  inheritedKeyState.open(developerKeyId, onSuccessfulInstallation, accountId)
}
