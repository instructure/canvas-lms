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

import { combineReducers } from 'redux'
import { handleActions } from 'redux-actions'
import { actionTypes } from './actions'
import MigrationStates from './migrationStates'

const identity = (defaultState = null) => {
  return state => state === undefined ? defaultState : state
}

export default combineReducers({
  accountId: identity(),
  course: identity(),
  terms: identity([]),
  subAccounts: identity([]),
  migrationStatus: handleActions({
    [actionTypes.CHECK_MIGRATION_SUCCESS]: (state, action) => action.payload,
    [actionTypes.BEGIN_MIGRATION_SUCCESS]: (state, action) => action.payload.workflow_state,
  }, MigrationStates.unknown),
  hasCheckedMigration: handleActions({
    [actionTypes.CHECK_MIGRATION_SUCCESS]: () => true,
    [actionTypes.BEGIN_MIGRATION_SUCCESS]: () => true,
  }, false),
  isCheckinMigration: handleActions({
    [actionTypes.CHECK_MIGRATION_START]: () => true,
    [actionTypes.CHECK_MIGRATION_SUCCESS]: () => false,
    [actionTypes.CHECK_MIGRATION_FAIL]: () => false,
  }, false),
  hasLoadedCourses: handleActions({
    [actionTypes.LOAD_COURSES_SUCCESS]: () => true,
  }, false),
  courses: handleActions({
    [actionTypes.LOAD_COURSES_SUCCESS]: (state, action) => action.payload,
  }, []),
  hasLoadedAssociations: handleActions({
    [actionTypes.LOAD_ASSOCIATIONS_SUCCESS]: () => true,
  }, false),
  existingAssociations: handleActions({
    [actionTypes.LOAD_ASSOCIATIONS_SUCCESS]: (state, action) => action.payload,
    [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: (state, action) => {
      const { added = [], removed = [] } = action.payload
      return state.filter(course => !removed.includes(course.id)).concat(added)
    },
  }, []),
  addedAssociations: handleActions({
    [actionTypes.CLEAR_ASSOCIATIONS]: () => [],
    [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: () => [],
    [actionTypes.ADD_COURSE_ASSOCIATIONS]: (state, action) => state.concat(action.payload),
    [actionTypes.UNDO_ADD_COURSE_ASSOCIATIONS]: (state, action) => state.filter(course => !action.payload.includes(course.id)),
  }, []),
  removedAssociations: handleActions({
    [actionTypes.CLEAR_ASSOCIATIONS]: () => [],
    [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: () => [],
    [actionTypes.REMOVE_COURSE_ASSOCIATIONS]: (state, action) => state.concat(action.payload),
    [actionTypes.UNDO_REMOVE_COURSE_ASSOCIATIONS]: (state, action) => state.filter(courseId => !action.payload.includes(courseId)),
  }, []),
  isLoadingBeginMigration: handleActions({
    [actionTypes.BEGIN_MIGRATION_START]: () => true,
    [actionTypes.BEGIN_MIGRATION_SUCCESS]: () => false,
    [actionTypes.BEGIN_MIGRATION_FAIL]: () => false,
  }, false),
  isLoadingCourses: handleActions({
    [actionTypes.LOAD_COURSES_START]: () => true,
    [actionTypes.LOAD_COURSES_SUCCESS]: () => false,
    [actionTypes.LOAD_COURSES_FAIL]: () => false,
  }, false),
  isLoadingAssociations: handleActions({
    [actionTypes.LOAD_ASSOCIATIONS_START]: () => true,
    [actionTypes.LOAD_ASSOCIATIONS_SUCCESS]: () => false,
    [actionTypes.LOAD_ASSOCIATIONS_FAIL]: () => false,
  }, false),
  isSavingAssociations: handleActions({
    [actionTypes.SAVE_ASSOCIATIONS_START]: () => true,
    [actionTypes.SAVE_ASSOCIATIONS_SUCCESS]: () => false,
    [actionTypes.SAVE_ASSOCIATIONS_FAIL]: () => false,
  }, false),
  errors: (state = [], action) => {
    return action.error
      ? state.concat([action.payload.message])
      : state
  },
})
