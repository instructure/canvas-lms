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
import LoadStates from './loadStates'
import MigrationStates from './migrationStates'

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
  'LOAD_UNSYNCED_CHANGES_START', 'LOAD_UNSYNCED_CHANGES_SUCCESS', 'LOAD_UNSYNCED_CHANGES_FAIL',
  'ENABLE_SEND_NOTIFICATION', 'INCLUDE_CUSTOM_NOTIFICATION_MESSAGE', 'SET_NOTIFICATION_MESSAGE',
  'LOAD_CHANGE_START', 'LOAD_CHANGE_SUCCESS', 'LOAD_CHANGE_FAIL', 'SELECT_CHANGE_LOG',
]
const actions = createActions(...types)

actions.loadChange = changeId => (dispatch, getState) => {
  const state = getState()
  const change = state.changeLogs[changeId]
  if (change && LoadStates.isLoading(change.status)) return;

  dispatch(actions.loadChangeStart())
  api.getFullMigration(state, changeId)
    .then(data => dispatch(actions.loadChangeSuccess(data)))
    .catch(handleError(I18n.t('An error occurred while loading changes'), dispatch, actions.loadChangeFail))
}

actions.realSelectChangeLog = actions.selectChangeLog
actions.selectChangeLog = ({ changeId }) => (dispatch, getState) => {
  dispatch(actions.realSelectChangeLog({ changeId }))
  if (changeId === null) return;
  const state = getState()
  const change = state.changeLogs[changeId]
  if (!change || LoadStates.isNotLoaded(change.status)) {
    actions.loadChange(changeId)(dispatch, getState)
  }
}

actions.loadHistory = () => (dispatch, getState) => {
  dispatch(actions.loadHistoryStart())
  api.getSyncHistory(getState())
    .then(data => dispatch(actions.loadHistorySuccess(data)))
    .catch(err => dispatch(actions.loadHistoryFail(err)))
}

actions.checkMigration = () => (dispatch, getState) => {
  const state = getState()
  // no need to check if another check is in progress
  if (state.isCheckingMigration) return;
  dispatch(actions.checkMigrationStart())
  api.checkMigration(getState())
    .then(res => dispatch(actions.checkMigrationSuccess(res.data)))
    .catch(handleError(I18n.t('An error occurred while checking the migration status'), dispatch, actions.checkMigrationFail))
}

// we use a closure to scope migInterval to those two actions only
(() => {
  let migInterval = null

  const resetInterval = () => {
    clearInterval(migInterval)
    migInterval = null
  }

  actions.startMigrationStatusPoll = () => (dispatch, getState) => {
    // don't start a new poll if one is in progress
    if (migInterval) return;
    actions.checkMigration()(dispatch, getState)
    migInterval = setInterval(() => {
      const state = getState()
      if (!state.isCheckingMigration && MigrationStates.isLoadingState(state.migrationStatus)) {
        actions.checkMigration()(dispatch, getState)
      } else if (MigrationStates.isEndState(state.migrationStatus)) {
        resetInterval()
        switch (state.migrationStatus) {
          case MigrationStates.states.completed:
            showAjaxFlashAlert(I18n.t('Sync completed successfully'))
            break
          case MigrationStates.states.imports_failed:
          case MigrationStates.states.exports_failed:
            showAjaxFlashAlert(I18n.t('There was an unexpected problem with the sync', 'error'))
            break;
          default:
            break
        }
      }
    }, 3000)
  }

  // our function action either needs to return an action object or a function
  // for thunk to execute, hence the weird looking function-returning-function
  actions.stopMigrationStatusPoll = () => () => {
    resetInterval()
  }
})()

actions.beginMigration = (startInteval = true) => (dispatch, getState) => {
  dispatch(actions.beginMigrationStart())
  api.beginMigration(getState())
    .then((res) => {
      dispatch(actions.beginMigrationSuccess(res.data))
      if (startInteval && MigrationStates.isLoadingState(res.data.workflow_state)) {
        actions.startMigrationStatusPoll()(dispatch, getState)
      }
    })
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
    .then(() => {
      dispatch(actions.saveAssociationsSuccess({ added: state.addedAssociations, removed: state.removedAssociations }))
      showAjaxFlashAlert(I18n.t('Associations saved successfully'))
      if (state.addedAssociations.length > 0) {
        actions.beginMigration()(dispatch, getState)
      }
    })
    .catch(handleError(I18n.t('An error occurred while saving associations'), dispatch, actions.saveAssociationsFail))
}

actions.loadUnsyncedChanges = () => (dispatch, getState) => {
  dispatch(actions.loadUnsyncedChangesStart())
  api.loadUnsyncedChanges(getState())
    .then(res => dispatch(actions.loadUnsyncedChangesSuccess(res.data)))
    .catch(err => dispatch(actions.loadUnsyncedChangesFail(err)))
}

const actionTypes = types.reduce((typesMap, actionType) =>
  Object.assign(typesMap, { [actionType]: actionType }), {})

export { actionTypes, actions as default }
