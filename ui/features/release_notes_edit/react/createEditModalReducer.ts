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

import {createDefaultState} from './util'
import {type ReleaseNoteEditing} from './types'

export enum Actions {
  RESET = 1,
  SET_TARGET_ROLES,
  SET_RELEASE_DATE,
  SET_LANG_ATTR,
  SET_ERROR_ELEMENT,
  CLEAR_ERROR_ELEMENT,
  SET_SUBMIT,
}

export type Transition = {action: Actions; payload?: any}
export type ReducerParams = {
  state: ReleaseNoteEditing
  dispatch: (t: Transition) => void
}

export function reducer(state: ReleaseNoteEditing, transition: Transition): ReleaseNoteEditing {
  const {action, payload} = transition
  const {env, key, lang, value} = payload ?? {}

  switch (action) {
    case Actions.RESET:
      return createDefaultState(payload)

    case Actions.SET_TARGET_ROLES:
      return {...state, target_roles: value}

    case Actions.SET_RELEASE_DATE:
      return {...state, show_ats: {...state.show_ats, [env]: value}}

    case Actions.SET_LANG_ATTR:
      return {
        ...state,
        langs: {...state.langs, [lang]: {...state.langs[lang], [key]: value}},
      }

    case Actions.SET_ERROR_ELEMENT:
      return {...state, elementsWithErrors: {...state.elementsWithErrors, [key]: value}}

    case Actions.CLEAR_ERROR_ELEMENT:
      return {...state, elementsWithErrors: {...state.elementsWithErrors, [key]: undefined}}

    case Actions.SET_SUBMIT:
      return {...state, isSubmitting: true}

    default:
      throw new RangeError(`Unknown action given to CreateEditModal reducer: ${action}`)
  }
}
