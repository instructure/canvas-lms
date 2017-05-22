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

import I18n from 'i18n!blueprint_settings'
import { createActions } from 'redux-actions'
import { showAjaxFlashAlert } from 'jsx/shared/AjaxFlashAlert'
import api from './apiClient'

const handleError = (msg, dispatch, actionCreator) => (err) => {
  showAjaxFlashAlert(msg, err)
  if (dispatch && actionCreator) {
    dispatch(actionCreator(err))
  }
}

const types = [
  'LOAD_COURSES_START', 'LOAD_COURSES_SUCCESS', 'LOAD_COURSES_FAIL',
  'LOAD_ASSOCIATIONS_START', 'LOAD_ASSOCIATIONS_SUCCESS', 'LOAD_ASSOCIATIONS_FAIL',
  'LOAD_HISTORY_START', 'LOAD_HISTORY_SUCCESS', 'LOAD_HISTORY_FAIL',
  'SAVE_ASSOCIATIONS_START', 'SAVE_ASSOCIATIONS_SUCCESS', 'SAVE_ASSOCIATIONS_FAIL',
  'CHECK_MIGRATION_START', 'CHECK_MIGRATION_SUCCESS', 'CHECK_MIGRATION_FAIL',
  'BEGIN_MIGRATION_START', 'BEGIN_MIGRATION_SUCCESS', 'BEGIN_MIGRATION_FAIL',
  'ADD_COURSE_ASSOCIATIONS', 'UNDO_ADD_COURSE_ASSOCIATIONS',
  'REMOVE_COURSE_ASSOCIATIONS', 'UNDO_REMOVE_COURSE_ASSOCIATIONS',
  'CLEAR_ASSOCIATIONS',
  'LOAD_UNSYNCHED_CHANGES_START', 'LOAD_UNSYNCHED_CHANGES_SUCCESS', 'LOAD_UNSYNCHED_CHANGES_FAIL',
  'ENABLE_SEND_NOTIFICATION', 'INCLUDE_CUSTOM_NOTIFICATION_MESSAGE', 'SET_NOTIFICATION_MESSAGE'
]
const actions = createActions(...types)

actions.loadHistory = () => (dispatch, getState) => {
  dispatch(actions.loadHistoryStart())
  api.getSyncHistory(getState())
    .then(data => dispatch(actions.loadHistorySuccess(data)))
    .catch(err => dispatch(actions.loadHistoryFail(err)))
}

actions.checkMigration = () => (dispatch, getState) => {
  dispatch(actions.checkMigrationStart())
  api.checkMigration(getState())
    .then(res => dispatch(actions.checkMigrationSuccess(res.data)))
    .catch(handleError(I18n.t('An error occurred while checking the migration status'), dispatch, actions.checkMigrationFail))
}

actions.beginMigration = () => (dispatch, getState) => {
  dispatch(actions.beginMigrationStart())
  api.beginMigration(getState())
    .then(res => dispatch(actions.beginMigrationSuccess(res.data)))
    .catch(handleError(I18n.t('An error occurred while starting migration'), dispatch, actions.beginMigrationFail))
}

actions.addAssociations = associations => (dispatch, getState) => {
  const state = getState()
  const existing = state.existingAssociations
  const toAdd = []
  const toUndo = []

  associations.forEach((courseId) => {
    if (existing.find(course => course.id === courseId)) {
      toUndo.push(courseId)
    } else {
      toAdd.push(courseId)
    }
  })

  if (toAdd.length) {
    const courses = state.courses.concat(state.existingAssociations)
    dispatch(actions.addCourseAssociations(courses.filter(c => toAdd.includes(c.id))))
  }

  if (toUndo.length) {
    dispatch(actions.undoRemoveCourseAssociations(toUndo))
  }
}

actions.removeAssociations = associations => (dispatch, getState) => {
  const existing = getState().existingAssociations
  const toRm = []
  const toUndo = []

  associations.forEach((courseId) => {
    if (existing.find(course => course.id === courseId)) {
      toRm.push(courseId)
    } else {
      toUndo.push(courseId)
    }
  })

  if (toRm.length) {
    dispatch(actions.removeCourseAssociations(toRm))
  }

  if (toUndo.length) {
    dispatch(actions.undoAddCourseAssociations(toUndo))
  }
}

actions.loadCourses = filters => (dispatch, getState) => {
  dispatch(actions.loadCoursesStart())
  api.getCourses(getState(), filters)
    .then(res => dispatch(actions.loadCoursesSuccess(res.data)))
    .catch(handleError(I18n.t('An error occurred while loading courses'), dispatch, actions.loadCoursesFail))
}

actions.loadAssociations = () => (dispatch, getState) => {
  const state = getState()
  // return if request is already in progress
  if (state.isLoadingAssociations) return
  dispatch(actions.loadAssociationsStart())
  api.getAssociations(state)
    .then((res) => {
      const data = res.data.map(course =>
        Object.assign({}, course, {
          term: {
            id: '0',
            name: course.term_name,
          },
          term_name: undefined,
        }))
      dispatch(actions.loadAssociationsSuccess(data))
    })
    .catch(handleError(I18n.t('An error occurred while loading associations'), dispatch, actions.loadAssociationsFail))
}

actions.saveAssociations = () => (dispatch, getState) => {
  dispatch(actions.saveAssociationsStart())
  const state = getState()
  api.saveAssociations(state)
    .then(() => dispatch(actions.saveAssociationsSuccess({ added: state.addedAssociations, removed: state.removedAssociations })))
    .catch(handleError(I18n.t('An error occurred while saving associations'), dispatch, actions.saveAssociationsFail))
}

actions.loadUnsynchedChanges = () => (dispatch, getState) => {
  dispatch(actions.loadUnsynchedChangesStart())
  api.loadUnsynchedChanges(getState())
    .then(res => dispatch(actions.loadUnsynchedChangesSuccess(res.data)))
    .catch(err => dispatch(actions.loadUnsynchedChangesFail(err)))
}

const actionTypes = types.reduce((typesMap, actionType) =>
  Object.assign(typesMap, { [actionType]: actionType }), {})

export { actionTypes, actions as default }
