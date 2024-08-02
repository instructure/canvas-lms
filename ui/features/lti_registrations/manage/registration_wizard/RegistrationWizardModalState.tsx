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
import type {ApiResult} from '../../common/lib/apiResult/ApiResult'
import create from 'zustand'
import type {LtiConfiguration} from '../model/lti_tool_configuration/LtiConfiguration'
import type {UnifiedToolId} from '../model/UnifiedToolId'

type JsonUrlFetchStatus =
  | {
      _tag: 'initial'
    }
  | {
      _tag: 'loading'
    }
  | {
      _tag: 'loaded'
      result: ApiResult<LtiConfiguration>
    }

export type RegistrationWizardModalState = {
  open: boolean
  /**
   * True is the user has selected the registration type
   * and method and clicked "next"
   *
   * When we launch the registration wizard from
   * other places, this will be true immediately
   * when launched (i.e. when a user clicks "install"
   * from the Discover page, and the dyn reg url is
   * already known)
   */
  registering: boolean
  lti_version: '1p3' | '1p1'
  method: InstallMethod
  dynamicRegistrationUrl: string
  jsonUrl: string
  unifiedToolId?: UnifiedToolId
  /**
   * Contains the state of fetching the JSON for the
   * JSON url method
   */
  jsonUrlFetch: JsonUrlFetchStatus
  /**
   * Controls whether the modal should close when the user
   * clicks "cancel" Should be true when the modal is
   * launched from the Product Detail page
   */
  exitOnCancel: boolean
  onSuccessfulInstallation?: () => void
}

type InstallMethod = 'dynamic_registration' | 'manual' | 'json' | 'json_url'

export type RegistrationWizardModalStateActions = {
  updateLtiVersion: (version: '1p3' | '1p1') => void
  updateMethod: (method: InstallMethod) => void
  updateDynamicRegistrationUrl: (url: string) => void
  updateJsonUrl: (url: string) => void
  updateJsonFetchStatus: (status: JsonUrlFetchStatus) => void
  register: () => void
  unregister: () => void
  close: () => void
}

export const useRegistrationModalWizardState = create<
  RegistrationWizardModalState & RegistrationWizardModalStateActions
>(set => ({
  open: false,
  lti_version: '1p3',
  progress: 0,
  progressMax: 100,
  method: 'dynamic_registration',
  dynamicRegistrationUrl: '',
  jsonUrl: '',
  unifiedToolId: undefined,
  registering: false,
  exitOnCancel: false,
  jsonUrlFetch: {_tag: 'initial'},
  updateLtiVersion: version => set({lti_version: version}),
  updateMethod: method => set({method}),
  updateDynamicRegistrationUrl: url => set({dynamicRegistrationUrl: url}),
  updateJsonUrl: url => set({jsonUrl: url}),
  register: () => set({registering: true}),
  unregister: () => {
    // todo: if we've already returned from the tool,
    // we need to delete the registration we created
    set(prev => {
      return {
        open: !prev.exitOnCancel,
        registering: prev.exitOnCancel,
      }
    })
  },
  updateJsonFetchStatus: status => {
    if (status._tag === 'loaded') {
      set({jsonUrlFetch: status, registering: status.result._type === 'success'})
    } else {
      set({jsonUrlFetch: status})
    }
  },
  close: () => set({open: false}),
}))

export const openRegistrationWizard = (
  initialState: Omit<RegistrationWizardModalState, 'open'>
) => {
  useRegistrationModalWizardState.setState({
    ...initialState,
    open: true,
  })
}

/**
 * Opens the registration wizard with the dynamic registration URL
 * already populated and the registration flow started
 * @param dynamicRegistrationUrl The URL to use for dynamic registration
 * @param unifiedToolId Correlates all installations of the same tool. Optional.
 */
export const openDynamicRegistrationWizard = (
  dynamicRegistrationUrl: string,
  unifiedToolId?: UnifiedToolId,
  onSuccessfulInstallation?: () => void
) => {
  openRegistrationWizard({
    dynamicRegistrationUrl,
    lti_version: '1p3',
    method: 'dynamic_registration',
    registering: true,
    exitOnCancel: true,
    onSuccessfulInstallation,
    unifiedToolId,
    jsonUrl: '',
    jsonUrlFetch: {_tag: 'initial'},
  })
}
