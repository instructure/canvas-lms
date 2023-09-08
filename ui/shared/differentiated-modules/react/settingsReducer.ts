/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export type SettingsPanelState = {
  moduleName: string
  unlockAt: string
  lockUntilChecked: boolean
  nameInputMessages: Array<{type: 'error' | 'hint' | 'success' | 'screenreader-only'; text: string}>
}

export const defaultState: SettingsPanelState = {
  moduleName: '',
  unlockAt: '',
  lockUntilChecked: false,
  nameInputMessages: [],
}

export const enum actions {
  SET_MODULE_NAME = 'SET_MODULE_NAME',
  SET_UNLOCK_AT = 'SET_UNLOCK_AT',
  SET_LOCK_UNTIL_CHECKED = 'SET_LOCK_UNTIL_CHECKED',
  SET_NAME_INPUT_MESSAGES = 'SET_NAME_INPUT_MESSAGES',
}

export function reducer(
  state: SettingsPanelState,
  action: {type: actions; payload: any}
): SettingsPanelState {
  switch (action.type) {
    case actions.SET_MODULE_NAME:
      return {...state, moduleName: action.payload}
    case actions.SET_UNLOCK_AT:
      return {...state, unlockAt: action.payload}
    case actions.SET_LOCK_UNTIL_CHECKED:
      return {...state, lockUntilChecked: action.payload}
    case actions.SET_NAME_INPUT_MESSAGES:
      return {...state, nameInputMessages: action.payload}
    default:
      return state
  }
}
