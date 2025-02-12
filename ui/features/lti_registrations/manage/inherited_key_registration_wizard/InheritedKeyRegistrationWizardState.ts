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
import type {ApiResult} from '../../common/lib/apiResult/ApiResult'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'
import type {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'

/**
 * Actions for the inherited key registration modal
 */
export interface InheritedKeyActions {
  open: (
    developerKeyId: DeveloperKeyId,
    onSuccessfulInstallation?: OnSuccessfulInstallation,
  ) => void
  close: () => void
  loaded: (result: ApiResult<LtiRegistrationWithConfiguration>) => void
  install: () => void
}

export type OnSuccessfulInstallation = (config: LtiRegistrationWithConfiguration) => void

/**
 *
 */
export type InheritedKeyWizardState = {
  open: boolean
} & (
  | {
      _type: 'Initial'
    }
  | {
      _type: 'RequestingRegistration'
      onSuccessfulInstallation?: OnSuccessfulInstallation
      developerKeyId: DeveloperKeyId
    }
  | {
      _type: 'RegistrationLoaded'
      result: ApiResult<LtiRegistrationWithConfiguration>
      onSuccessfulInstallation?: OnSuccessfulInstallation
      developerKeyId: DeveloperKeyId
    }
  | {
      _type: 'InstallingRegistration'
      result: ApiResult<LtiRegistrationWithConfiguration>
      onSuccessfulInstallation?: OnSuccessfulInstallation
      developerKeyId: DeveloperKeyId
    }
)

export const stateFrom =
  <K extends InheritedKeyWizardState['_type']>(key: K) =>
  (
    modifier: (state: Extract<InheritedKeyWizardState, {_type: K}>) => InheritedKeyWizardState,
  ): ((state: InheritedKeyWizardState) => InheritedKeyWizardState) => {
    return state => {
      if (state._type === key) {
        return modifier(state as Extract<InheritedKeyWizardState, {_type: K}>)
      } else {
        return state
      }
    }
  }

/**
 * Wraps a value into an object with a state key, for use with Zustand
 * @param state
 * @returns
 */
const stateForTag =
  <K extends InheritedKeyWizardState['_type']>(
    _type: K,
    value: Omit<Extract<InheritedKeyWizardState, {_type: K}>, '_type'>,
  ) =>
  () => ({state: {_type, ...value}})

type StateUpdater = (
  updater: (s: {state: InheritedKeyWizardState} & InheritedKeyActions) => {
    state: InheritedKeyWizardState
  },
) => void

/**
 * Zustand store for the state of the inherited key registration modal
 */
export const useInheritedKeyWizardState = create<
  {state: InheritedKeyWizardState} & InheritedKeyActions
>((set: StateUpdater) => {
  const modifyState = (f: (prev: InheritedKeyWizardState) => InheritedKeyWizardState) => {
    set(({state}) => ({state: f(state)}))
  }
  return {
    state: {_type: 'Initial', open: false},
    open: (developerKeyId: DeveloperKeyId, onSuccessfulInstallation?: OnSuccessfulInstallation) => {
      set(
        stateForTag('RequestingRegistration', {
          open: true,
          developerKeyId,
          onSuccessfulInstallation,
        }),
      )
    },
    close: () => {
      modifyState(state => ({...state, open: false}))
    },
    loaded: result => {
      modifyState(
        stateFrom('RequestingRegistration')(state => ({
          ...state,
          _type: 'RegistrationLoaded' as const,
          result,
        })),
      )
    },
    install: () => {
      modifyState(
        stateFrom('RegistrationLoaded')(state => ({
          ...state,
          _type: 'InstallingRegistration',
        })),
      )
    },
  }
})

const inheritedKeyState = useInheritedKeyWizardState.getState()

export const openInheritedKeyWizard = (
  developerKeyId: DeveloperKeyId,
  onSuccessfulInstallation?: OnSuccessfulInstallation,
) => {
  inheritedKeyState.open(developerKeyId, onSuccessfulInstallation)
}
