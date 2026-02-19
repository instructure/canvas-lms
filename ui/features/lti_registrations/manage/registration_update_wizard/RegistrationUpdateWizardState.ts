/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {LtiRegistrationUpdateRequest} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'

type RegistrationUpdateWizardStep =
  | 'PermissionConfirmation'
  | 'PrivacyLevelConfirmation'
  | 'PlacementsConfirmation'
  | 'NamingConfirmation'
  | 'IconConfirmation'
  | 'Reviewing'

export const RegistrationUpdateWizardStepOrder: Array<RegistrationUpdateWizardStep> = [
  'Reviewing',
  'PermissionConfirmation',
  'PrivacyLevelConfirmation',
  'PlacementsConfirmation',
  'NamingConfirmation',
  'IconConfirmation',
]

export type RegistrationUpdateWizardState = {
  registrationUpdateRequest: LtiRegistrationUpdateRequest
  step: RegistrationUpdateWizardStep
  reviewing: boolean
}

export type RegistrationUpdateWizardActions = {
  advance: () => void
  previous: () => void
  setStep: (step: RegistrationUpdateWizardStep) => void
  isFirstStep: () => boolean
  isLastStep: () => boolean
}

export const mkUseRegistrationUpdateWizardState = (
  registrationUpdateRequest: LtiRegistrationUpdateRequest,
) =>
  create<{state: RegistrationUpdateWizardState} & RegistrationUpdateWizardActions>((set, get) => {
    const stateForStep = (
      nextStep: RegistrationUpdateWizardStep,
      state: RegistrationUpdateWizardState,
    ) => ({
      state: {
        ...state,
        reviewing: nextStep === 'Reviewing' ? true : state.reviewing,
        step: nextStep,
      },
    })
    return {
      state: {
        registrationUpdateRequest,
        step: RegistrationUpdateWizardStepOrder[0],
        reviewing: false,
      },
      advance: () => {
        set(state => {
          const currentStepIndex = RegistrationUpdateWizardStepOrder.indexOf(state.state.step)
          const nextStepIndex = currentStepIndex + 1
          if (nextStepIndex >= RegistrationUpdateWizardStepOrder.length) {
            return state
          }

          const nextStep = RegistrationUpdateWizardStepOrder[nextStepIndex]
          const newState = stateForStep(nextStep, state.state)
          return newState
        })
      },
      previous: () => {
        set(state => {
          const currentStepIndex = RegistrationUpdateWizardStepOrder.indexOf(state.state.step)
          if (currentStepIndex > 0) {
            const previousStep = RegistrationUpdateWizardStepOrder[currentStepIndex - 1]
            return stateForStep(previousStep, state.state)
          }
          return state
        })
      },
      setStep(nextStep) {
        set(state => stateForStep(nextStep, state.state))
      },
      isFirstStep: () => {
        const currentState = get()
        return currentState.state.step === RegistrationUpdateWizardStepOrder[0]
      },
      isLastStep: () => {
        const currentState = get()
        return (
          currentState.state.step ===
          RegistrationUpdateWizardStepOrder[RegistrationUpdateWizardStepOrder.length - 1]
        )
      },
    }
  })
