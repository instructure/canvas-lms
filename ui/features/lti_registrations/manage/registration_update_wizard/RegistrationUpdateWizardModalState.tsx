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
import {LtiRegistration} from '../model/LtiRegistration'

export type RegistrationUpdateWizardModalState =
  | {
      open: false
    }
  | {
      open: true
      registration: LtiRegistration
    }

export type RegistrationUpdateWizardModalActions = {
  open: (registration: LtiRegistration) => void
  close: () => void
}

export const useRegistrationUpdateWizardModalState = create<
  {
    state: RegistrationUpdateWizardModalState
  } & RegistrationUpdateWizardModalActions
>(set => {
  return {
    state: {open: false},
    open: registration =>
      set(() => ({
        state: {registration, open: true},
      })),
    close: () =>
      set(() => ({
        state: {open: false},
      })),
  }
})
