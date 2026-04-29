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

import {isSuccessful, formatApiResultError} from '../../common/lib/apiResult/ApiResult'
import type {AccountId} from '../model/AccountId'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiConfigurationOverlay} from '../model/internal_lti_configuration/LtiConfigurationOverlay'
import {
  containsPlacementWithIcon,
  createLti1p3RegistrationOverlayStore,
  type Lti1p3RegistrationOverlayStore,
} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import {convertToLtiConfigurationOverlay} from '../registration_overlay/Lti1p3RegistrationOverlayStateHelpers'
import {
  validateLaunchSettings,
  validateOverrideUris,
  validateIconUris,
  getInputIdForField,
  type Lti1p3RegistrationOverlayStateError,
} from '../registration_overlay/validateLti1p3RegistrationOverlayState'

import type {Lti1p3RegistrationWizardService} from './Lti1p3RegistrationWizardService'
import {create} from 'zustand'
import {LtiRegistration, LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import {UnifiedToolId} from '../model/UnifiedToolId'

export type Lti1p3RegistrationWizardState = {
  overlayStore: Lti1p3RegistrationOverlayStore
  service: Lti1p3RegistrationWizardService
  _step: Lti1p3RegistrationWizardStep
  reviewing: boolean
  errorMessage?: string
  hasClickedNext?: boolean
}

export interface Lti1p3RegistrationWizardActions {
  setStep: (step: Lti1p3RegistrationWizardStep) => void
  setReviewing: (reviewing: boolean) => void
  install: (
    onSuccessfulInstallation: (registrationId: LtiRegistrationId) => void,
    accountId: AccountId,
    unifiedToolId?: string,
  ) => Promise<void>
  update: (
    onSuccessfulUpdate: (registrationId: LtiRegistrationId) => void,
    accountId: AccountId,
    registrationId: LtiRegistrationId,
    unifiedToolId?: string,
  ) => Promise<void>

  /**
   * Handle next button click with validation for the current step
   * Calls onErrors callback with validation errors if any
   */
  advanceStep: (
    accountId: AccountId,
    onSuccessfulRegistration: (registrationId: LtiRegistrationId) => void,
    onErrors: (errors: Array<Lti1p3RegistrationOverlayStateError>) => void,
    existingRegistration?: LtiRegistrationWithConfiguration,
    unifiedToolId?: UnifiedToolId,
  ) => void

  /**
   * Handle previous button click for the current step
   */
  previousStep: (currentStep: Lti1p3RegistrationWizardStep) => void

  /**
   * Check if current step can proceed (used for button state)
   */
  canProceed: (currentStep: Lti1p3RegistrationWizardStep) => boolean

  /**
   * Validate the current step and return validation errors
   * Returns empty array if no validation errors
   */
  validateStep: (
    currentStep: Lti1p3RegistrationWizardStep,
  ) => Array<Lti1p3RegistrationOverlayStateError>

  /**
   * Returns true if the current step should be skipped
   * false otherwise
   * @param currentStep
   * @returns
   */
  shouldSkipStep: (currentStep: Lti1p3RegistrationWizardStep) => boolean

  /**
   * Handle the final save/install action from the review screen
   */
  handleSave: (
    accountId: AccountId,
    existingRegistrationId?: LtiRegistrationId,
    unifiedToolId?: string,
    onSuccessfulSave?: (registrationId: LtiRegistrationId) => void,
  ) => void
}

export type Lti1p3RegistrationWizardStep =
  | 'LaunchSettings'
  | 'EulaSettings'
  | 'Permissions'
  | 'DataSharing'
  | 'Placements'
  | 'OverrideURIs'
  | 'Naming'
  | 'Icons'
  | 'Review'
  | 'Installing'
  | 'Updating'
  | 'Error'

const Lti1p3RegistrationWizardStepOrder: Array<Lti1p3RegistrationWizardStep> = [
  'LaunchSettings',
  'Permissions',
  'DataSharing',
  'Placements',
  'EulaSettings',
  'OverrideURIs',
  'Naming',
  'Icons',
  'Review',
]

export type Lti1p3RegistrationWizardStore = {
  state: Lti1p3RegistrationWizardState
} & Lti1p3RegistrationWizardActions

type CreateStoreProps = {
  internalConfig: InternalLtiConfiguration
  adminNickname?: string
  existingOverlay?: LtiConfigurationOverlay
  service: Lti1p3RegistrationWizardService
  reviewing?: boolean
}

export const createLti1p3RegistrationWizardState = ({
  adminNickname,
  existingOverlay,
  internalConfig,
  service,
  reviewing = false,
}: CreateStoreProps) =>
  create<Lti1p3RegistrationWizardStore>((set, get) => ({
    state: {
      overlayStore: createLti1p3RegistrationOverlayStore(
        internalConfig,
        adminNickname,
        existingOverlay,
      ),
      _step: 'LaunchSettings',
      service,
      reviewing,
    },
    setStep: step => set(state => ({state: {...state.state, _step: step}})),
    setReviewing: isReviewing => set(state => ({state: {...state.state, reviewing: isReviewing}})),
    // TODO: Once the two backend create/update endpoints are created, these methods should actually
    // call them, instead of just faking it.
    install: async (onSuccessfulInstallation, accountId, unifiedToolId) => {
      set(state => ({state: {...state.state, _step: 'Installing'}}))

      const {overlay, config} = convertToLtiConfigurationOverlay(
        get().state.overlayStore.getState().state,
        internalConfig,
      )

      const result = await service.createLtiRegistration(
        accountId,
        config,
        overlay,
        unifiedToolId,
        get().state.overlayStore.getState().state.naming.nickname,
      )

      if (isSuccessful(result)) {
        onSuccessfulInstallation(result.data.id)
      } else {
        set(state => ({
          state: {
            ...state.state,
            _step: 'Error',
            errorMessage: formatApiResultError(result),
          },
        }))
      }
    },
    update: async (onSuccessfulUpdate, accountId, registrationId) => {
      set(state => ({state: {...state.state, _step: 'Updating'}}))

      const {overlay, config} = convertToLtiConfigurationOverlay(
        get().state.overlayStore.getState().state,
        internalConfig,
      )

      const result = await service.updateLtiRegistration({
        accountId,
        registrationId,
        internalConfig: config,
        overlay,
        adminNickname: get().state.overlayStore.getState().state.naming.nickname,
      })

      if (isSuccessful(result)) {
        onSuccessfulUpdate(registrationId)
      } else {
        set(state => ({
          state: {
            ...state.state,
            _step: 'Error',
            errorMessage: formatApiResultError(result),
          },
        }))
      }
    },
    advanceStep: (
      accountId,
      onSuccessfulRegistration,
      onErrors,
      existingRegistration,
      unifiedToolId,
    ) => {
      const currentState = get()
      if (currentState.state._step === 'Review') {
        currentState.handleSave(
          accountId,
          existingRegistration?.id,
          unifiedToolId,
          onSuccessfulRegistration,
        )
      } else {
        set(state => {
          const errors = state.validateStep(state.state._step)
          if (errors.length > 0) {
            onErrors(errors)
            return {
              state: {
                ...state.state,
                hasClickedNext: true,
              },
            }
          }
          if (state.state.reviewing) {
            return {
              state: {
                ...state.state,
                _step: 'Review',
              },
            }
          }

          const currentStepIndex = Lti1p3RegistrationWizardStepOrder.indexOf(state.state._step)

          let candidateStepIndex = currentStepIndex + 1
          while (candidateStepIndex <= Lti1p3RegistrationWizardStepOrder.length - 1) {
            const candidateStep = Lti1p3RegistrationWizardStepOrder[candidateStepIndex]
            if (state.shouldSkipStep(candidateStep)) {
              candidateStepIndex++
              continue
            } else {
              break
            }
          }
          const nextStep =
            candidateStepIndex < Lti1p3RegistrationWizardStepOrder.length
              ? Lti1p3RegistrationWizardStepOrder[candidateStepIndex]
              : 'Review'

          return {
            state: {
              ...state.state,
              _step: nextStep,
              reviewing: nextStep === 'Review' ? true : state.state.reviewing,
            },
          }
        })
      }
    },
    previousStep: currentStep =>
      set(state => {
        const currentStepIndex = Lti1p3RegistrationWizardStepOrder.indexOf(currentStep)

        // starting at the current step, find the previous step in the order, skipping any that should be skipped
        let candidateStepIndex = currentStepIndex - 1
        while (candidateStepIndex > 0) {
          const candidateStep = Lti1p3RegistrationWizardStepOrder[candidateStepIndex]
          if (state.shouldSkipStep(candidateStep)) {
            candidateStepIndex--
            continue
          } else {
            break
          }
        }

        const previousStep =
          candidateStepIndex >= 0
            ? Lti1p3RegistrationWizardStepOrder[candidateStepIndex]
            : 'LaunchSettings'

        return {
          state: {
            ...state.state,
            _step: previousStep,
            reviewing: false,
          },
        }
      }),
    canProceed: _currentStep => {
      // All steps can proceed for now - can add validation logic here later if needed
      return true
    },
    shouldSkipStep: currentStep => {
      switch (currentStep) {
        case 'EulaSettings':
          return !get().state.overlayStore.getState().isEulaCapable()
        default:
          return false
      }
    },
    validateStep: currentStep => {
      const store = get()
      switch (currentStep) {
        case 'LaunchSettings':
          return validateLaunchSettings(store.state.overlayStore.getState().state.launchSettings)
        case 'OverrideURIs':
          return validateOverrideUris(store.state.overlayStore.getState().state.override_uris)
        case 'Icons':
          return validateIconUris(store.state.overlayStore.getState().state.icons)
        default:
          return []
      }
    },
    handleSave: (accountId, existingRegistrationId, unifiedToolId, onSuccessfulSave) => {
      const store = get()
      if (existingRegistrationId) {
        store.update(
          onSuccessfulSave || (() => {}),
          accountId,
          existingRegistrationId,
          unifiedToolId,
        )
      } else {
        store.install(onSuccessfulSave || (() => {}), accountId, unifiedToolId)
      }
    },
  }))
