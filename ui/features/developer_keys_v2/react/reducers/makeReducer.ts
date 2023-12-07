/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import actions, {
  type DeveloperKeyActionNames,
  type ToActionCreatorName,
} from '../actions/developerKeysActions'

type ActionFromActionName<ActionName extends DeveloperKeyActionNames> = ReturnType<
  (typeof actions)[ToActionCreatorName<ActionName>]
>

type DevKeyReducerMap<State> = Partial<{
  [K in DeveloperKeyActionNames]: (state: State, action: ActionFromActionName<K>) => State
}>

/**
 * Constructs a reducer from a map of action names to reducer functions.
 * The action types are inferred from the type of the actions map.
 * @param initialState
 * @param reducerMap
 * @returns
 */
export const makeReducer =
  <State>(initialState: State, reducerMap: DevKeyReducerMap<State>) =>
  (state: State = initialState, action: {type: DeveloperKeyActionNames}) => {
    const reducerFn = reducerMap[action.type]
    if (typeof reducerFn !== 'undefined') {
      // as any cast here because DevKeyReducerMap is unrelated
      // to action.type
      return reducerFn(state, action as any)
    } else {
      return state
    }
  }
