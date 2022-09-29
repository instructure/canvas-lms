/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {combineReducers} from 'redux'
import {handleActions} from 'redux-actions'
import {actionTypes} from './actions'
import MigrationStates from './migrationStates'
import LoadStates from './loadStates'

const identity =
  (defaultState = null) =>
  state =>
    state === undefined ? defaultState : state

const changeLogReducer = combineReducers({
  changeId: identity(),
  status: handleActions(
    {
      [actionTypes.LOAD_CHANGE_START]: () => LoadStates.states.loading,
      [actionTypes.LOAD_CHANGE_SUCCESS]: () => LoadStates.states.loaded,
      [actionTypes.LOAD_CHANGE_FAILED]: () => LoadStates.states.not_loaded,
    },
    LoadStates.states.not_loaded
  ),
  data: handleActions(
    {
      [actionTypes.LOAD_CHANGE_SUCCESS]: (state, action) => action.payload,
    },
    null
  ),
})

const createNotification = data => ({
  id: Date.now().toString(),
  type: data.type || (data.err ? 'error' : 'info'),
  message: data.message,
  err: data.err,
})

const notificationReducer = handleActions(
  {
    [actionTypes.NOTIFY_INFO]: (state, action) =>
      state.concat([createNotification(action.payload)]),
    [actionTypes.CLEAR_NOTIFICATION]: (state, action) =>
      state.slice().filter(not => not.id !== action.payload),
  },
  []
)

export default combineReducers({
  course: identity(null),
  masterCourse: identity(),
  isMasterCourse: identity(),
  isChildCourse: identity(),
  canManageCourse: identity(),
  canAutoPublishCourses: identity(),
  accountId: identity(),
  terms: identity([]),
  subAccounts: identity([]),
  notifications: (state, action) => {
    let newState = notificationReducer(state, action)

    // duck typing error notifications from structure of _FAIL actions
    if (action.payload && action.payload.err && action.payload.message) {
      newState = newState.concat([createNotification(action.payload)])
    }

    return newState
  },
  selectedChangeLog: handleActions(
    {
      [actionTypes.SELECT_CHANGE_LOG]: (state, action) =>
        (action.payload && action.payload.changeId) || null,
    },
    null
  ),
  changeLogs: (state = {}, action) => {
    let newState = state
    const {changeId} = action.payload || {}

    if (changeId) {
      newState = {[changeId]: changeLogReducer(state[changeId] || {changeId}, action)}
    }

    return newState
  },
  isLoadingHistory: handleActions(
    {
      [actionTypes.LOAD_HISTORY_START]: () => true,
      [actionTypes.LOAD_HISTORY_SUCCESS]: () => false,
      [actionTypes.LOAD_HISTORY_FAIL]: () => false,
    },
    false
  ),
  hasLoadedHistory: handleActions(
    {
      [actionTypes.LOAD_HISTORY_SUCCESS]: () => true,
      [actionTypes.CHECK_MIGRATION_SUCCESS]: (state, action) =>
        MigrationStates.isEndState(action.payload) ? false : state,
    },
    false
  ),
  migrations: handleActions(
    {
      [actionTypes.LOAD_HISTORY_SUCCESS]: (state, action) => action.payload,
    },
    []
  ),
  migrationStatus: handleActions(
    {
      [actionTypes.CHECK_MIGRATION_SUCCESS]: (state, action) => action.payload,
      [actionTypes.BEGIN_MIGRATION_SUCCESS]: (state, action) => action.payload.workflow_state,
    },
    MigrationStates.states.unknown
  ),
  hasCheckedMigration: handleActions(
    {
      [actionTypes.CHECK_MIGRATION_SUCCESS]: () => true,
      [actionTypes.BEGIN_MIGRATION_SUCCESS]: () => true,
    },
    false
  ),
  isCheckingMigration: handleActions(
    {
      [actionTypes.CHECK_MIGRATION_START]: () => true,
      [actionTypes.CHECK_MIGRATION_SUCCESS]: () => false,
      [actionTypes.CHECK_MIGRATION_FAIL]: () => false,
    },
    false
  ),
  hasLoadedCourses: handleActions(
    {
      [actionTypes.LOAD_COURSES_SUCCESS]: () => true,
    },
    false
  ),
  courses: handleActions(
    {
      [actionTypes.LOAD_COURSES_SUCCESS]: (state, action) => action.payload,
    },
    []
  ),
  hasLoadedAssociations: handleActions(
    {
      [actionTypes.LOAD_ASSOCIATIONS_SUCCESS]: () => true,
    },
    false
  ),
  existingAssociations: handleActions(
    {
      [actionTypes.LOAD_ASSOCIATIONS_SUCCESS]: (state, action) => action.payload,
      [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: (state, action) => {
        const {added = [], removed = []} = action.payload
        const removedIds = removed.map(course => course.id)
        return state.filter(course => !removedIds.includes(course.id)).concat(added)
      },
    },
    []
  ),
  addedAssociations: handleActions(
    {
      [actionTypes.CLEAR_ASSOCIATIONS]: () => [],
      [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: () => [],
      [actionTypes.ADD_COURSE_ASSOCIATIONS]: (state, action) => state.concat(action.payload),
      [actionTypes.UNDO_ADD_COURSE_ASSOCIATIONS]: (state, action) =>
        state.filter(course => !action.payload.includes(course.id)),
    },
    []
  ),
  removedAssociations: handleActions(
    {
      [actionTypes.CLEAR_ASSOCIATIONS]: () => [],
      [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: () => [],
      [actionTypes.REMOVE_COURSE_ASSOCIATIONS]: (state, action) => state.concat(action.payload),
      [actionTypes.UNDO_REMOVE_COURSE_ASSOCIATIONS]: (state, action) =>
        state.filter(course => !action.payload.includes(course.id)),
    },
    []
  ),
  isLoadingBeginMigration: handleActions(
    {
      [actionTypes.BEGIN_MIGRATION_START]: () => true,
      [actionTypes.BEGIN_MIGRATION_SUCCESS]: () => false,
      [actionTypes.BEGIN_MIGRATION_FAIL]: () => false,
    },
    false
  ),
  isLoadingCourses: handleActions(
    {
      [actionTypes.LOAD_COURSES_START]: () => true,
      [actionTypes.LOAD_COURSES_SUCCESS]: () => false,
      [actionTypes.LOAD_COURSES_FAIL]: () => false,
    },
    false
  ),
  isLoadingAssociations: handleActions(
    {
      [actionTypes.LOAD_ASSOCIATIONS_START]: () => true,
      [actionTypes.LOAD_ASSOCIATIONS_SUCCESS]: () => false,
      [actionTypes.LOAD_ASSOCIATIONS_FAIL]: () => false,
    },
    false
  ),
  isSavingAssociations: handleActions(
    {
      [actionTypes.SAVE_ASSOCIATIONS_START]: () => true,
      [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: () => false,
      [actionTypes.SAVE_ASSOCIATIONS_FAIL]: () => false,
    },
    false
  ),
  isLoadingUnsyncedChanges: handleActions(
    {
      [actionTypes.LOAD_UNSYNCED_CHANGES_START]: () => true,
      [actionTypes.LOAD_UNSYNCED_CHANGES_SUCCESS]: () => false,
      [actionTypes.LOAD_UNSYNCED_CHANGES_FAIL]: () => false,
    },
    false
  ),
  hasLoadedUnsyncedChanges: handleActions(
    {
      [actionTypes.LOAD_UNSYNCED_CHANGES_START]: () => false,
      [actionTypes.LOAD_UNSYNCED_CHANGES_SUCCESS]: () => true,
    },
    false
  ),
  unsyncedChanges: handleActions(
    {
      [actionTypes.LOAD_UNSYNCED_CHANGES_SUCCESS]: (state, action) => action.payload,
    },
    []
  ),
  willSendNotification: handleActions(
    {
      [actionTypes.ENABLE_SEND_NOTIFICATION]: (state, action) => action.payload,
    },
    false
  ),
  willIncludeCustomNotificationMessage: handleActions(
    {
      [actionTypes.INCLUDE_CUSTOM_NOTIFICATION_MESSAGE]: (state, action) => action.payload,
    },
    false
  ),
  notificationMessage: handleActions(
    {
      [actionTypes.SET_NOTIFICATION_MESSAGE]: (state, action) => action.payload,
    },
    ''
  ),
  willIncludeCourseSettings: handleActions(
    {
      [actionTypes.INCLUDE_COURSE_SETTINGS]: (state, action) => action.payload,
    },
    false
  ),
  willPublishCourses: handleActions(
    {
      [actionTypes.ENABLE_PUBLISH_COURSES]: (state, action) => action.payload,
    },
    false
  ),
})
