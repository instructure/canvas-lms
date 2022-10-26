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

import {useScope as useI18nScope} from '@canvas/i18n'
import {createActions} from 'redux-actions'

import api from './apiClient'
import LoadStates from './loadStates'
import MigrationStates from './migrationStates'

const I18n = useI18nScope('blueprint_settings_actions')

const types = [
  'LOAD_COURSES_START',
  'LOAD_COURSES_SUCCESS',
  'LOAD_COURSES_FAIL',
  'LOAD_ASSOCIATIONS_START',
  'LOAD_ASSOCIATIONS_SUCCESS',
  'LOAD_ASSOCIATIONS_FAIL',
  'LOAD_HISTORY_START',
  'LOAD_HISTORY_SUCCESS',
  'LOAD_HISTORY_FAIL',
  'SAVE_ASSOCIATIONS_START',
  'SAVE_ASSOCIATIONS_SUCCESS',
  'SAVE_ASSOCIATIONS_FAIL',
  'CHECK_MIGRATION_START',
  'CHECK_MIGRATION_SUCCESS',
  'CHECK_MIGRATION_FAIL',
  'BEGIN_MIGRATION_START',
  'BEGIN_MIGRATION_SUCCESS',
  'BEGIN_MIGRATION_FAIL',
  'ADD_COURSE_ASSOCIATIONS',
  'UNDO_ADD_COURSE_ASSOCIATIONS',
  'REMOVE_COURSE_ASSOCIATIONS',
  'UNDO_REMOVE_COURSE_ASSOCIATIONS',
  'CLEAR_ASSOCIATIONS',
  'LOAD_UNSYNCED_CHANGES_START',
  'LOAD_UNSYNCED_CHANGES_SUCCESS',
  'LOAD_UNSYNCED_CHANGES_FAIL',
  'ENABLE_SEND_NOTIFICATION',
  'INCLUDE_CUSTOM_NOTIFICATION_MESSAGE',
  'SET_NOTIFICATION_MESSAGE',
  'LOAD_CHANGE_START',
  'LOAD_CHANGE_SUCCESS',
  'LOAD_CHANGE_FAIL',
  'SELECT_CHANGE_LOG',
  'NOTIFY_INFO',
  'NOTIFY_ERROR',
  'CLEAR_NOTIFICATION',
  'INCLUDE_COURSE_SETTINGS',
  'ENABLE_PUBLISH_COURSES',
]
const actions = createActions(...types)

actions.constants = {
  MIGRATION_POLL_TIME: 3000,
}

const {notifyInfo, notifyError} = actions
actions.notifyInfo = payload => notifyInfo(Object.assign(payload, {type: 'info'}))
actions.notifyError = payload => notifyError(Object.assign(payload, {type: 'error'}))

actions.loadChange = params => (dispatch, getState) => {
  const state = getState()
  const change = state.changeLogs[params.changeId]
  if (change && LoadStates.isLoading(change.status)) return

  dispatch(actions.loadChangeStart(params))
  api
    .getFullMigration(state, params)
    .then(data => dispatch(actions.loadChangeSuccess(data)))
    .catch(err =>
      dispatch(
        actions.loadChangeFail({err, message: I18n.t('An error occurred while loading changes')})
      )
    )
}

actions.realSelectChangeLog = actions.selectChangeLog
actions.selectChangeLog = params => (dispatch, getState) => {
  dispatch(actions.realSelectChangeLog(params))
  if (params === null) return
  const state = getState()
  const change = state.changeLogs[params.changeId]
  if (!change || LoadStates.isNotLoaded(change.status)) {
    actions.loadChange(params)(dispatch, getState)
  }
}

actions.loadHistory = () => (dispatch, getState) => {
  dispatch(actions.loadHistoryStart())
  api
    .getSyncHistory(getState())
    .then(data => dispatch(actions.loadHistorySuccess(data)))
    .catch(err =>
      dispatch(
        actions.loadHistoryFail({
          err,
          message: I18n.t('An error ocurred while loading sync history'),
        })
      )
    )
}

actions.checkMigration =
  (startInterval = false) =>
  (dispatch, getState) => {
    const state = getState()
    // no need to check if another check is in progress
    if (state.isCheckingMigration) return
    dispatch(actions.checkMigrationStart())
    api
      .checkMigration(getState())
      .then(res => {
        dispatch(actions.checkMigrationSuccess(res.data))
        if (startInterval && MigrationStates.isLoadingState(res.data)) {
          actions.startMigrationStatusPoll()(dispatch, getState)
        }
      })

      .catch(err =>
        dispatch(
          actions.checkMigrationFail({
            err,
            message: I18n.t('An error occurred while checking the migration status'),
          })
        )
      )
  }

// we use a closure to scope migInterval to those two actions only
;(() => {
  let migInterval = null

  // our function action either needs to return an action object or a function
  // for thunk to execute, hence the weird looking function-returning-function
  actions.stopMigrationStatusPoll = () => () => {
    clearInterval(migInterval)
    migInterval = null
  }

  actions.pollMigrationStatus = () => (dispatch, getState) => {
    const state = getState()
    if (!state.isCheckingMigration && MigrationStates.isLoadingState(state.migrationStatus)) {
      actions.checkMigration()(dispatch, getState)
    } else if (MigrationStates.isEndState(state.migrationStatus)) {
      actions.stopMigrationStatusPoll()(dispatch, getState)
      switch (state.migrationStatus) {
        case MigrationStates.states.completed:
          dispatch(actions.notifyInfo({message: I18n.t('Sync completed successfully')}))
          break
        case MigrationStates.states.imports_failed:
        case MigrationStates.states.exports_failed:
          dispatch(
            actions.notifyError({message: I18n.t('There was an unexpected problem with the sync')})
          )
          break
        default:
          break
      }
    }
  }

  actions.startMigrationStatusPoll = () => (dispatch, getState) => {
    // don't start a new poll if one is in progress
    if (migInterval) return
    actions.checkMigration()(dispatch, getState)
    migInterval = setInterval(
      () => actions.pollMigrationStatus()(dispatch, getState),
      actions.constants.MIGRATION_POLL_TIME
    )
  }
})()

actions.beginMigration =
  (startInterval = true) =>
  (dispatch, getState) => {
    dispatch(actions.beginMigrationStart())
    api
      .beginMigration(getState())
      .then(res => {
        dispatch(actions.beginMigrationSuccess(res.data))
        if (startInterval && MigrationStates.isLoadingState(res.data.workflow_state)) {
          actions.startMigrationStatusPoll()(dispatch, getState)
        }
      })
      .catch(err =>
        dispatch(
          actions.beginMigrationFail({
            err,
            message: I18n.t('An error occurred while starting migration'),
          })
        )
      )
  }

actions.addAssociations = associations => (dispatch, getState) => {
  const state = getState()
  const existing = state.existingAssociations
  const toAdd = []
  const toUndo = []

  associations.forEach(courseId => {
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

  associations.forEach(courseId => {
    if (existing.find(course => course.id === courseId)) {
      toRm.push(courseId)
    } else {
      toUndo.push(courseId)
    }
  })

  if (toRm.length) {
    dispatch(actions.removeCourseAssociations(existing.filter(c => toRm.includes(c.id))))
  }

  if (toUndo.length) {
    dispatch(actions.undoAddCourseAssociations(toUndo))
  }
}

actions.loadCourses = filters => (dispatch, getState) => {
  dispatch(actions.loadCoursesStart())
  // responses may come out of order. only display results from the most recent query
  actions.loadCoursesSequence = (actions.loadCoursesSequence || 0) + 1
  const currentSequence = actions.loadCoursesSequence
  api
    .getCourses(getState(), filters)
    .then(res => {
      if (currentSequence === actions.loadCoursesSequence) {
        dispatch(actions.loadCoursesSuccess(res.data))
      }
    })
    .catch(err =>
      dispatch(
        actions.loadCoursesFail({err, message: I18n.t('An error occurred while loading courses')})
      )
    )
}

actions.loadAssociations = () => (dispatch, getState) => {
  const state = getState()
  // return if request is already in progress
  if (state.isLoadingAssociations) return
  dispatch(actions.loadAssociationsStart())
  api
    .getAssociations(state)
    .then(res => {
      const data = res.data.map(course => {
        const parsedCourse = Object.assign(course, {
          term: {
            id: '0',
            name: course.term_name,
          },
        })
        delete parsedCourse.term_name
        return parsedCourse
      })
      dispatch(actions.loadAssociationsSuccess(data))
    })
    .catch(err =>
      dispatch(
        actions.loadAssociationsFail({
          err,
          message: I18n.t('An error occurred while loading associations'),
        })
      )
    )
}

actions.saveAssociations = () => (dispatch, getState) => {
  dispatch(actions.saveAssociationsStart())
  const state = getState()
  api
    .saveAssociations(state)
    .then(() => {
      dispatch(
        actions.saveAssociationsSuccess({
          added: state.addedAssociations,
          removed: state.removedAssociations,
        })
      )
      dispatch(actions.notifyInfo({message: I18n.t('Associations saved successfully')}))
      if (state.addedAssociations.length > 0) {
        actions.beginMigration()(dispatch, getState)
      }
    })
    .catch(err =>
      dispatch(
        actions.saveAssociationsFail({
          err,
          message: I18n.t('An error occurred while saving associations'),
        })
      )
    )
}

actions.loadUnsyncedChanges = () => (dispatch, getState) => {
  dispatch(actions.loadUnsyncedChangesStart())
  api
    .loadUnsyncedChanges(getState())
    .then(res => dispatch(actions.loadUnsyncedChangesSuccess(res.data)))
    .catch(err =>
      dispatch(
        actions.loadUnsyncedChangesFail({
          err,
          message: I18n.t('An error ocurred while loading unsynced changes'),
        })
      )
    )
}

const actionTypes = types.reduce(
  (typesMap, actionType) => Object.assign(typesMap, {[actionType]: actionType}),
  {}
)

export {actionTypes, actions as default}
