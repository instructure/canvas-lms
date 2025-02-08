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

export enum Actions {
  RESET = 1,
  SET_TARGET_ROLES,
  SET_RELEASE_DATE,
  SET_LANG_ATTR,
  SET_ERROR_ELEMENT,
  CLEAR_ERROR_ELEMENT,
  SET_SUBMIT,
}

type Transition = {action: Actions; payload?: any}
export type ReleaseNote = {
  id?: string
  target_roles: string[]
  langs: {[key: string]: {title: string; description: string}}
  show_ats: {[key: string]: string}
  published: boolean
  elementsWithErrors: {[key: string]: string}
  isSubmitting: boolean
}
export type ReducerParams = {
  state: ReleaseNote
  dispatch: (t: Transition) => void
}

const DEFAULT_STATE: ReleaseNote = {
  target_roles: ['user'],
  langs: {en: {title: '', description: ''}},
  show_ats: {},
  published: false,
  elementsWithErrors: {},
  isSubmitting: false,
}

export function createDefaultState(current: ReleaseNote | null) {
  if (current) return {...DEFAULT_STATE, ...current}
  return DEFAULT_STATE
}

export function reducer(state: ReleaseNote, transition: Transition): ReleaseNote {
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
