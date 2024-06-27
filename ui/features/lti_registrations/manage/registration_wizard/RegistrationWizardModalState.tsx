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
import create from 'zustand'

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
  method: 'dynamic_registration' | 'manual' | 'json'
  dynamicRegistrationUrl: string
  unifiedToolId: string
  /**
   * Controls whether the modal should close when the user
   * clicks "cancel" Should be true when the modal is
   * launched from the Product Detail page
   */
  exitOnCancel: boolean
  onSuccessfulInstallation?: () => void
}

export type RegistrationWizardModalStateActions = {
  updateLtiVersion: (version: '1p3' | '1p1') => void
  updateMethod: (method: 'dynamic_registration' | 'manual' | 'json') => void
  updateDynamicRegistrationUrl: (url: string) => void
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
  unifiedToolId: '',
  registering: false,
  exitOnCancel: false,
  updateLtiVersion: version => set({lti_version: version}),
  updateMethod: method => set({method}),
  updateDynamicRegistrationUrl: url => set({dynamicRegistrationUrl: url}),
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
  unifiedToolId: string = '',
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
  })
}
