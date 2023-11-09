/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment-timezone'

export interface BlackoutDate {
  readonly id?: number | string
  temp_id?: string
  readonly course_id?: number | string
  event_title: string
  start_date: moment.Moment
  end_date: moment.Moment
  readonly admin_level?: boolean
  is_calendar_event?: boolean
  // Only for CalendarEvent blackout dates:
  readonly title?: string
  readonly start_at?: moment.Moment
  readonly end_at?: moment.Moment
}

export enum SyncState {
  SYNCED, // up to date
  SYNCING, // actively syncing
  UNSYNCED, // there are pending changes
}
export interface BlackoutDateState {
  syncing: SyncState
  blackoutDates: BlackoutDate[]
}

export type CourseExternalToolStatus = 'OFF' | 'ON' | 'HIDE'
export type InputInteraction = 'enabled' | 'disabled' | 'readonly'

export interface Course {
  readonly id: string
  readonly name: string
  readonly start_at: string
  readonly end_at: string
  readonly created_at: string
  readonly time_zone?: string
  readonly default_view?: 'feed' | 'wiki' | 'modules' | 'assignments' | 'syllabus' | null
  readonly is_student?: boolean
  readonly is_instructor?: boolean
}

/* Redux action types */

/*
  The following types are intended to make it easy to write typesafe redux actions with minimal boilerplate.
  Actions created with createAction will return in the following formats:

  Without a payload:

    { type: "Constant" }

  With a payload:

    { type: "Constant", payload: payload }

  Typescript can then easily infer the type of the action using ReturnType.

  ActionsUnion is useful for mapping over the return types of a group of actions collected in an object,
  so that the reducer can do typesafe switching based on the action type.

  Example:

  // Actions

  export enum Constants {
    DO_THING = "DO_THING",
    DO_THING_WITH_PAYLOAD = "DO_THING_WITH_PAYLOAD"
  }

  export const actions = {
    doThing: () => createAction(Constants.DO_THING),
    doThingWithPayload: (stuff: string) => createAction(Constants.DO_THING_WITH_PAYLOAD, stuff),
  }

  export type ThingActions = ActionsUnion<typeof actions>;

  // Reducer

  const reducer = (state = {}, action: ThingActions) => {
    switch(action.type) {
      case Constants.DO_THING:
        return state;
      case Constants.DO_THING_WITH_PAYLOAD:
        // Typescript knows the shape of payload at this point, because our actions are typesafe. This means it'll
        // warn us if we do some sort of type mismatch, or try to access something off of payload that doesn't exist.
        return { ...state, stuff: action.payload };
    }
  }

  This setup was inspired by this blog post, which you can read if you want more background on how this all works:
  https://medium.com/@martin_hotell/improved-redux-type-safety-with-typescript-2-8-2c11a8062575
*/

interface Action<T extends string> {
  type: T
}

interface ActionWithPayload<T extends string, P> extends Action<T> {
  payload: P
}

export function createAction<T extends string>(type: T): Action<T>
export function createAction<T extends string, P>(type: T, payload: P): ActionWithPayload<T, P>
export function createAction<T extends string, P>(type: T, payload?: P) {
  return payload === undefined ? {type} : {type, payload}
}

type ActionCreatorsMapObject = {[actionCreator: string]: (...args: any[]) => any}
export type ActionsUnion<A extends ActionCreatorsMapObject> = ReturnType<A[keyof A]>
