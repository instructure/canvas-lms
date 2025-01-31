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
import {isSuccessful, type ApiResult} from '../../common/lib/apiResult/ApiResult'
import {ZUnifiedToolId, type UnifiedToolId} from '../model/UnifiedToolId'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'

export type JsonFetchStatus =
  | {
      _tag: 'initial'
    }
  | {
      _tag: 'loading'
    }
  | {
      _tag: 'loaded'
      result: ApiResult<InternalLtiConfiguration>
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
  /**
   * Contains the state of the URL input for the JSON Url method
   */
  jsonUrl: string
  /**
   * Contains the state of the JSON Code input for the JSON method
   */
  jsonCode: string
  /**
   * Contains the state of the Name input for the Manual method
   */
  manualAppName: string
  /**
   * The ID of the existing registration to edit. If this is set, the registration wizard will
   * open to the Manual Registration review screen, once the registration has been loaded from the backend.
   * If this is not set, the registration wizard will continue as if it were a new registration.
   */
  existingRegistrationId?: LtiRegistrationId
  unifiedToolId?: UnifiedToolId
  /**
   * Contains the state of fetching the JSON for the
   * JSON methods
   */
  jsonFetch: JsonFetchStatus
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
  updateManualAppName: (appName: string) => void
  updateJsonCode: (url: string) => void
  updateJsonFetchStatus: (status: JsonFetchStatus) => void
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
  jsonCode: '',
  manualAppName: '',
  unifiedToolId: undefined,
  registering: false,
  exitOnCancel: false,
  jsonFetch: {_tag: 'initial'},
  updateLtiVersion: version => set({lti_version: version}),
  updateMethod: method => set({method, jsonFetch: {_tag: 'initial'}}),
  updateDynamicRegistrationUrl: url => set({dynamicRegistrationUrl: url}),
  updateJsonUrl: url => set({jsonUrl: url, jsonFetch: {_tag: 'initial'}}),
  updateManualAppName: name => set({manualAppName: name}),
  updateJsonCode: code => set({jsonCode: code, jsonFetch: {_tag: 'initial'}}),
  register: () => set({registering: true}),
  unregister: () => {
    // todo: if we've already returned from the tool,
    // we need to delete the registration we created
    set(prev => {
      if (prev.exitOnCancel) {
        return {
          open: false,
        }
      } else {
        return {
          ltiImsRegistrationId: undefined,
          registering: false,
        }
      }
    })
  },
  updateJsonFetchStatus: status => {
    if (status._tag === 'loaded') {
      set({jsonFetch: status, registering: isSuccessful(status.result)})
    } else {
      set({jsonFetch: status})
    }
  },
  close: () => set({open: false}),
}))

export const openRegistrationWizard = (
  initialState: Partial<Omit<RegistrationWizardModalState, 'open'>>,
) => {
  useRegistrationModalWizardState.setState(prev => {
    return {
      ...prev,
      dynamicRegistrationUrl: '',
      unifiedToolId: ZUnifiedToolId.parse(''),
      jsonUrl: '',
      jsonUrlFetch: {_tag: 'initial'},
      lti_version: '1p3',
      method: 'dynamic_registration',
      existingRegistrationId: undefined,
      ...initialState,
      open: true,
    }
  })
}

export const openJsonRegistrationWizard = (
  jsonCode: string,
  internalLtiConfig: InternalLtiConfiguration,
  unifiedToolId?: UnifiedToolId,
  onSuccessfulInstallation?: () => void,
) => {
  useRegistrationModalWizardState.setState(prev => {
    return {
      ...prev,
      jsonCode,
      method: 'json',
      open: true,
      jsonFetch: {
        _tag: 'loaded',
        result: {
          _type: 'Success',
          data: internalLtiConfig,
        },
      },
      unifiedToolId,
      exitOnCancel: true,
      registering: true,
      onSuccessfulInstallation,
    }
  })
}

export const openJsonUrlRegistrationWizard = (
  jsonUrl: string,
  internalLtiConfig: InternalLtiConfiguration,
  unifiedToolId?: UnifiedToolId,
  onSuccessfulInstallation?: () => void,
) => {
  useRegistrationModalWizardState.setState(prev => {
    return {
      ...prev,
      jsonUrl,
      method: 'json_url',
      open: true,
      jsonFetch: {
        _tag: 'loaded',
        result: {
          _type: 'Success',
          data: internalLtiConfig,
        },
      },
      unifiedToolId,
      registering: true,
      exitOnCancel: true,
      onSuccessfulInstallation,
    }
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
  onSuccessfulInstallation?: () => void,
) => {
  openRegistrationWizard({
    dynamicRegistrationUrl,
    registering: true,
    exitOnCancel: true,
    onSuccessfulInstallation,
    unifiedToolId,
  })
}

/**
 * Allows users to edit the Dynamic Registration of an already existing LTI IMS Registration.
 * This will open the registration wizard to the review screen, once the registration has been loaded
 * from the backend.
 *
 * @param existingRegistrationId The ID of the LTI IMS Registration to edit.
 * @param onSuccessfulInstallation A callback to run after the update is finished successfully.
 */
export const openEditDynamicRegistrationWizard = (
  existingRegistrationId: LtiRegistrationId,
  onSuccessfulInstallation?: () => void,
) => {
  openRegistrationWizard({
    existingRegistrationId,
    registering: true,
    exitOnCancel: true,
    onSuccessfulInstallation,
  })
}

export const openEditManualRegistrationWizard = (
  existingRegistrationId: LtiRegistrationId,
  onSuccessfulInstallation?: () => void,
) => {
  openRegistrationWizard({
    existingRegistrationId,
    registering: true,
    exitOnCancel: true,
    onSuccessfulInstallation,
    method: 'manual',
  })
}
