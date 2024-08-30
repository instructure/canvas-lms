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

import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import {
  createLti1p3RegistrationOverlayStore,
  type Lti1p3RegistrationOverlayStore,
} from './Lti1p3RegistrationOverlayState'
import create from 'zustand'

export type Lti1p3RegistrationWizardState = {
  overlayStore: Lti1p3RegistrationOverlayStore
  _step: Lti1p3RegistrationWizardStep
  reviewing: boolean
  installing: boolean
}

export interface Lti1p3RegistrationWizardActions {
  setStep: (step: Lti1p3RegistrationWizardStep) => void
  setReviewing: (reviewing: boolean) => void
  setInstalling: (installing: boolean) => void
}

type Lti1p3RegistrationWizardStep =
  | 'LaunchSettings'
  | 'Permissions'
  | 'DataSharing'
  | 'Placements'
  | 'OverrideURIs'
  | 'Naming'
  | 'Icons'
  | 'Review'

export type Lti1p3RegistrationWizardStore = {
  state: Lti1p3RegistrationWizardState
} & Lti1p3RegistrationWizardActions

type CreateStoreProps = {
  internalConfig: InternalLtiConfiguration
  reviewing?: boolean
  installing?: boolean
}

export const createLti1p3RegistrationWizardState = ({
  internalConfig,
  reviewing = false,
  installing = true,
}: CreateStoreProps) =>
  create<Lti1p3RegistrationWizardStore>(set => ({
    state: {
      overlayStore: createLti1p3RegistrationOverlayStore(internalConfig),
      _step: 'LaunchSettings',
      reviewing,
      installing,
    },
    setStep: step => set(state => ({state: {...state.state, _step: step}})),
    setReviewing: isReviewing => set(state => ({state: {...state.state, reviewing: isReviewing}})),
    setInstalling: isInstalling =>
      set(state => ({state: {...state.state, installing: isInstalling}})),
  }))
