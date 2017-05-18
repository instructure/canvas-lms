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

import actions from 'jsx/blueprint_courses/actions'
import reducer from 'jsx/blueprint_courses/reducer'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'
import LoadStates from 'jsx/blueprint_courses/loadStates'
import sampleData from './sampleData'

QUnit.module('Blurpint Courses reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('sets courses on LOAD_COURSES_SUCCESS', () => {
  const newState = reduce(actions.loadCoursesSuccess(sampleData.courses))
  deepEqual(newState.courses, sampleData.courses)
})

test('sets existingAssociations on LOAD_LISTINGS_SUCCESS', () => {
  const newState = reduce(actions.loadAssociationsSuccess(sampleData.courses))
  deepEqual(newState.existingAssociations, sampleData.courses)
})

test('adds associations to existingAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const existing = [sampleData.courses[0]]
  const added = [sampleData.courses[1]]
  const newState = reduce(actions.saveAssociationsSuccess({ added }), { existingAssociations: existing })
  deepEqual(newState.existingAssociations, sampleData.courses)
})

test('removes associations froms existingAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({ removed: ['1'] }), { existingAssociations: sampleData.courses })
  deepEqual(newState.existingAssociations, [sampleData.courses[1]])
})

test('resets addedAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({}))
  deepEqual(newState.addedAssociations, [])
})

test('resets addedAssociations on CLEAR_ASSOCIATIONS', () => {
  const newState = reduce(actions.clearAssociations())
  deepEqual(newState.addedAssociations, [])
})

test('adds associations to addedAssociations on ADD_COURSE_ASSOCIATIONS', () => {
  const existing = [sampleData.courses[0]]
  const added = [sampleData.courses[1]]
  const newState = reduce(actions.addCourseAssociations(added), { addedAssociations: existing })
  deepEqual(newState.addedAssociations, sampleData.courses)
})

test('removes associations from addedAssociations on UNDO_ADD_COURSE_ASSOCIATIONS', () => {
  const newState = reduce(actions.undoAddCourseAssociations(['1']), { addedAssociations: sampleData.courses })
  deepEqual(newState.addedAssociations, [sampleData.courses[1]])
})

test('resets removedAssociations on CLEAR_ASSOCIATIONS', () => {
  const newState = reduce(actions.clearAssociations())
  deepEqual(newState.removedAssociations, [])
})

test('resets removedAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({}))
  deepEqual(newState.removedAssociations, [])
})

test('adds associations to removedAssociations on REMOVE_COURSE_ASSOCIATIONS', () => {
  const newState = reduce(actions.removeCourseAssociations(['1']), { removedAssociations: ['2'] })
  deepEqual(newState.removedAssociations, ['2', '1'])
})

test('removes associations from removedAssociations on UNDO_REMOVE_COURSE_ASSOCIATIONS', () => {
  const newState = reduce(actions.undoRemoveCourseAssociations(['1']), { removedAssociations: ['1', '2'] })
  deepEqual(newState.removedAssociations, ['2'])
})

test('sets hasLoadedCourses to true on LOAD_COURSES_SUCCESS', () => {
  const newState = reduce(actions.loadCoursesSuccess({}))
  equal(newState.hasLoadedCourses, true)
})

test('sets isLoadingCourses to true on LOAD_COURSES_START', () => {
  const newState = reduce(actions.loadCoursesStart())
  equal(newState.isLoadingCourses, true)
})

test('sets isLoadingCourses to false on LOAD_COURSES_SUCCESS', () => {
  const newState = reduce(actions.loadCoursesSuccess({}))
  equal(newState.isLoadingCourses, false)
})

test('sets isLoadingCourses to false on LOAD_COURSES_FAIL', () => {
  const newState = reduce(actions.loadCoursesFail())
  equal(newState.isLoadingCourses, false)
})

test('sets hasLoadedAssociations to true on LOAD_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.loadAssociationsSuccess([]))
  equal(newState.hasLoadedAssociations, true)
})

test('sets isLoadingAssociations to true on LOAD_ASSOCIATIONS_START', () => {
  const newState = reduce(actions.loadAssociationsStart())
  equal(newState.isLoadingAssociations, true)
})

test('sets isLoadingAssociations to false on LOAD_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.loadAssociationsSuccess([]))
  equal(newState.isLoadingAssociations, false)
})

test('sets isLoadingAssociations to false on LOAD_ASSOCIATIONS_FAIL', () => {
  const newState = reduce(actions.loadAssociationsFail())
  equal(newState.isLoadingAssociations, false)
})

test('sets isSavingAssociations to true on SAVE_ASSOCIATIONS_START', () => {
  const newState = reduce(actions.saveAssociationsStart())
  equal(newState.isSavingAssociations, true)
})

test('sets isSavingAssociations to false on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({}))
  equal(newState.isSavingAssociations, false)
})

test('sets isSavingAssociations to false on SAVE_ASSOCIATIONS_FAIL', () => {
  const newState = reduce(actions.saveAssociationsFail())
  equal(newState.isSavingAssociations, false)
})

test('sets isLoadingBeginMigration to true on BEGIN_MIGRATION_START', () => {
  const newState = reduce(actions.beginMigrationStart())
  equal(newState.isLoadingBeginMigration, true)
})

test('sets isLoadingBeginMigration to false on BEGIN_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.beginMigrationSuccess({ workflow_state: 'queued' }))
  equal(newState.isLoadingBeginMigration, false)
})

test('sets isLoadingBeginMigration to false on BEGIN_MIGRATION_FAIL', () => {
  const newState = reduce(actions.beginMigrationFail())
  equal(newState.isLoadingBeginMigration, false)
})

test('sets hasCheckedMigration to true on CHECK_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.checkMigrationSuccess('queued'))
  equal(newState.hasCheckedMigration, true)
})

test('sets hasCheckedMigration to true on BEGIN_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.beginMigrationSuccess({ workflow_state: 'queued' }))
  equal(newState.hasCheckedMigration, true)
})

test('sets isCheckingMigration to true on CHECK_MIGRATION_START', () => {
  const newState = reduce(actions.checkMigrationStart())
  equal(newState.isCheckingMigration, true)
})

test('sets isCheckingMigration to false on CHECK_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.checkMigrationSuccess('queued'))
  equal(newState.isCheckingMigration, false)
})

test('sets isCheckingMigration to false on CHECK_MIGRATION_FAIL', () => {
  const newState = reduce(actions.checkMigrationFail())
  equal(newState.isCheckingMigration, false)
})

test('sets migrationStatus to true on BEGIN_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.beginMigrationSuccess({ workflow_state: 'queued' }))
  equal(newState.migrationStatus, 'queued')
})

test('sets migrationStatus to true on CHECK_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.checkMigrationSuccess('queued'))
  equal(newState.migrationStatus, 'queued')
})

test('sets hasLoadedHistory to true on LOAD_HISTORY_SUCCESS', () => {
  const newState = reduce(actions.loadHistorySuccess({}))
  equal(newState.hasLoadedHistory, true)
})

test('resets hasLoadedHistory to false when CHECK_MIGRATION_SUCCESS returns an end state', () => {
  const newState = reduce(actions.checkMigrationSuccess(MigrationStates.states.completed))
  equal(newState.hasLoadedHistory, false)
})

test('sets isLoadingHistory to true on LOAD_HISTORY_START', () => {
  const newState = reduce(actions.loadHistoryStart())
  equal(newState.isLoadingHistory, true)
})

test('sets isLoadingHistory to false on LOAD_HISTORY_SUCCESS', () => {
  const newState = reduce(actions.loadHistorySuccess({}))
  equal(newState.isLoadingHistory, false)
})

test('sets isLoadingHistory to false on LOAD_HISTORY_FAIL', () => {
  const newState = reduce(actions.loadHistoryFail())
  equal(newState.isLoadingHistory, false)
})

test('sets isLoadingUnynchedChanges to true on LOAD_UNSYNCED_CHANGES_START', () => {
  const newState = reduce(actions.loadUnsyncedChangesStart())
  equal(newState.isLoadingUnsyncedChanges, true)
})
test('sets isLoadingUnynchedChanges to false on LOAD_UNSYNCED_CHANGES_SUCCESS', () => {
  const newState = reduce(actions.loadUnsyncedChangesSuccess({}))
  equal(newState.isLoadingUnsyncedChanges, false)
})
test('sets isLoadingUnynchedChanges to alse on LOAD_UNSYNCED_CHANGES_FAIL', () => {
  const newState = reduce(actions.loadUnsyncedChangesFail())
  equal(newState.isLoadingUnsyncedChanges, false)
})

test('sets hasLoadedUnsyncedChanges to false on LOAD_UNSYNCED_CHANGES_START', () => {
  const newState = reduce(actions.loadUnsyncedChangesStart())
  equal(newState.hasLoadedUnsyncedChanges, false)
})
test('sets hasLoadedUnsyncedChanges to true on LOAD_UNSYNCED_CHANGES_SUCCESS', () => {
  const newState = reduce(actions.loadUnsyncedChangesSuccess({}))
  equal(newState.hasLoadedUnsyncedChanges, true)
})

test('sets unsyncedChanges on LOAD_UNSYNCED_CHANGES_SUCCESS', () => {
  const newState = reduce(actions.loadUnsyncedChangesSuccess(sampleData.unsyncedChanges))
  deepEqual(newState.unsyncedChanges, sampleData.unsyncedChanges)
})

test('sets willSendNotification on ENABLE_SEND_NOTIFICATION', () => {
  let newState = reduce(actions.enableSendNotification(true))
  equal(newState.willSendNotification, true)
  newState = reduce(actions.enableSendNotification(false))
  equal(newState.willSendNotification, false)
})

test('creates empty change log entry on SELECT_CHANGE_LOG', () => {
  const newState = reduce(actions.realSelectChangeLog({ changeId: '5' }))
  deepEqual(newState.changeLogs, { 5: {
    changeId: '5',
    status: LoadStates.states.not_loaded,
    data: null,
  } })
})

test('sets change log status to loading on LOAD_CHANGE_START', () => {
  const newState = reduce(actions.loadChangeStart({ changeId: '5' }))
  deepEqual(newState.changeLogs, { 5: {
    changeId: '5',
    status: LoadStates.states.loading,
    data: null,
  } })
})

test('sets change log data and status to loaded on LOAD_CHANGE_SUCCESS', () => {
  const newState = reduce(actions.loadChangeSuccess({ changeId: '5', changes: ['1', '2'] }))
  deepEqual(newState.changeLogs, { 5: {
    changeId: '5',
    status: LoadStates.states.loaded,
    data: { changeId: '5', changes: ['1', '2'] },
  } })
})

test('sets change log status to not loaded on LOAD_CHANGE_FAILED', () => {
  const newState = reduce(actions.loadChangeFail({ changeId: '5' }))
  deepEqual(newState.changeLogs, { 5: {
    changeId: '5',
    status: LoadStates.states.not_loaded,
    data: null,
  } })
})
