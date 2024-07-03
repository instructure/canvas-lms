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

import actions from '../actions'
import reducer from '../reducer'
import MigrationStates from '../migrationStates'
import LoadStates from '../loadStates'
import getSampleData from '../../getSampleData'

describe('Blueprint Courses reducer', () => {
  const reduce = (action, state = {}) => reducer(state, action)

  it('sets courses on LOAD_COURSES_SUCCESS', () => {
    const newState = reduce(actions.loadCoursesSuccess(getSampleData().courses))
    expect(newState.courses).toEqual(getSampleData().courses)
  })

  it('sets existingAssociations on LOAD_LISTINGS_SUCCESS', () => {
    const newState = reduce(actions.loadAssociationsSuccess(getSampleData().courses))
    expect(newState.existingAssociations).toEqual(getSampleData().courses)
  })

  it('adds associations to existingAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
    const existing = [getSampleData().courses[0]]
    const added = [getSampleData().courses[1]]
    const newState = reduce(actions.saveAssociationsSuccess({added}), {
      existingAssociations: existing,
    })
    expect(newState.existingAssociations).toEqual(getSampleData().courses)
  })

  it('removes associations from existingAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
    const newState = reduce(actions.saveAssociationsSuccess({removed: [{id: '1'}]}), {
      existingAssociations: getSampleData().courses,
    })
    expect(newState.existingAssociations).toEqual([getSampleData().courses[1]])
  })

  it('resets addedAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
    const newState = reduce(actions.saveAssociationsSuccess({}))
    expect(newState.addedAssociations).toEqual([])
  })

  it('resets addedAssociations on CLEAR_ASSOCIATIONS', () => {
    const newState = reduce(actions.clearAssociations())
    expect(newState.addedAssociations).toEqual([])
  })

  it('adds associations to addedAssociations on ADD_COURSE_ASSOCIATIONS', () => {
    const existing = [getSampleData().courses[0]]
    const added = [getSampleData().courses[1]]
    const newState = reduce(actions.addCourseAssociations(added), {addedAssociations: existing})
    expect(newState.addedAssociations).toEqual(getSampleData().courses)
  })

  it('removes associations from addedAssociations on UNDO_ADD_COURSE_ASSOCIATIONS', () => {
    const newState = reduce(actions.undoAddCourseAssociations(['1']), {
      addedAssociations: getSampleData().courses,
    })
    expect(newState.addedAssociations).toEqual([getSampleData().courses[1]])
  })

  it('resets removedAssociations on CLEAR_ASSOCIATIONS', () => {
    const newState = reduce(actions.clearAssociations())
    expect(newState.removedAssociations).toEqual([])
  })

  it('resets removedAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
    const newState = reduce(actions.saveAssociationsSuccess({}))
    expect(newState.removedAssociations).toEqual([])
  })

  it('adds associations to removedAssociations on REMOVE_COURSE_ASSOCIATIONS', () => {
    const newState = reduce(actions.removeCourseAssociations(['1']), {removedAssociations: ['2']})
    expect(newState.removedAssociations).toEqual(['2', '1'])
  })

  it('removes associations from removedAssociations on UNDO_REMOVE_COURSE_ASSOCIATIONS', () => {
    const newState = reduce(actions.undoRemoveCourseAssociations(['1']), {
      removedAssociations: [{id: '1'}, {id: '2'}],
    })
    expect(newState.removedAssociations).toEqual([{id: '2'}])
  })

  it('sets hasLoadedCourses to true on LOAD_COURSES_SUCCESS', () => {
    const newState = reduce(actions.loadCoursesSuccess({}))
    expect(newState.hasLoadedCourses).toBe(true)
  })

  it('sets isLoadingCourses to true on LOAD_COURSES_START', () => {
    const newState = reduce(actions.loadCoursesStart())
    expect(newState.isLoadingCourses).toBe(true)
  })

  it('sets isLoadingCourses to false on LOAD_COURSES_SUCCESS', () => {
    const newState = reduce(actions.loadCoursesSuccess({}))
    expect(newState.isLoadingCourses).toBe(false)
  })

  it('sets isLoadingCourses to false on LOAD_COURSES_FAIL', () => {
    const newState = reduce(actions.loadCoursesFail())
    expect(newState.isLoadingCourses).toBe(false)
  })

  it('sets hasLoadedAssociations to true on LOAD_ASSOCIATIONS_SUCCESS', () => {
    const newState = reduce(actions.loadAssociationsSuccess([]))
    expect(newState.hasLoadedAssociations).toBe(true)
  })

  it('sets isLoadingAssociations to true on LOAD_ASSOCIATIONS_START', () => {
    const newState = reduce(actions.loadAssociationsStart())
    expect(newState.isLoadingAssociations).toBe(true)
  })

  it('sets isLoadingAssociations to false on LOAD_ASSOCIATIONS_SUCCESS', () => {
    const newState = reduce(actions.loadAssociationsSuccess([]))
    expect(newState.isLoadingAssociations).toBe(false)
  })

  it('sets isLoadingAssociations to false on LOAD_ASSOCIATIONS_FAIL', () => {
    const newState = reduce(actions.loadAssociationsFail())
    expect(newState.isLoadingAssociations).toBe(false)
  })

  it('sets isSavingAssociations to true on SAVE_ASSOCIATIONS_START', () => {
    const newState = reduce(actions.saveAssociationsStart())
    expect(newState.isSavingAssociations).toBe(true)
  })

  it('sets isSavingAssociations to false on SAVE_ASSOCIATIONS_SUCCESS', () => {
    const newState = reduce(actions.saveAssociationsSuccess({}))
    expect(newState.isSavingAssociations).toBe(false)
  })

  it('sets isSavingAssociations to false on SAVE_ASSOCIATIONS_FAIL', () => {
    const newState = reduce(actions.saveAssociationsFail())
    expect(newState.isSavingAssociations).toBe(false)
  })

  it('sets isLoadingBeginMigration to true on BEGIN_MIGRATION_START', () => {
    const newState = reduce(actions.beginMigrationStart())
    expect(newState.isLoadingBeginMigration).toBe(true)
  })

  it('sets isLoadingBeginMigration to false on BEGIN_MIGRATION_SUCCESS', () => {
    const newState = reduce(actions.beginMigrationSuccess({workflow_state: 'queued'}))
    expect(newState.isLoadingBeginMigration).toBe(false)
  })

  it('sets isLoadingBeginMigration to false on BEGIN_MIGRATION_FAIL', () => {
    const newState = reduce(actions.beginMigrationFail())
    expect(newState.isLoadingBeginMigration).toBe(false)
  })

  it('sets hasCheckedMigration to true on CHECK_MIGRATION_SUCCESS', () => {
    const newState = reduce(actions.checkMigrationSuccess('queued'))
    expect(newState.hasCheckedMigration).toBe(true)
  })

  it('sets hasCheckedMigration to true on BEGIN_MIGRATION_SUCCESS', () => {
    const newState = reduce(actions.beginMigrationSuccess({workflow_state: 'queued'}))
    expect(newState.hasCheckedMigration).toBe(true)
  })

  it('sets isCheckingMigration to true on CHECK_MIGRATION_START', () => {
    const newState = reduce(actions.checkMigrationStart())
    expect(newState.isCheckingMigration).toBe(true)
  })

  it('sets isCheckingMigration to false on CHECK_MIGRATION_SUCCESS', () => {
    const newState = reduce(actions.checkMigrationSuccess('queued'))
    expect(newState.isCheckingMigration).toBe(false)
  })

  it('sets isCheckingMigration to false on CHECK_MIGRATION_FAIL', () => {
    const newState = reduce(actions.checkMigrationFail())
    expect(newState.isCheckingMigration).toBe(false)
  })

  it('sets migrationStatus to true on BEGIN_MIGRATION_SUCCESS', () => {
    const newState = reduce(actions.beginMigrationSuccess({workflow_state: 'queued'}))
    expect(newState.migrationStatus).toBe('queued')
  })

  it('sets migrationStatus to true on CHECK_MIGRATION_SUCCESS', () => {
    const newState = reduce(actions.checkMigrationSuccess('queued'))
    expect(newState.migrationStatus).toBe('queued')
  })

  it('sets hasLoadedHistory to true on LOAD_HISTORY_SUCCESS', () => {
    const newState = reduce(actions.loadHistorySuccess({}))
    expect(newState.hasLoadedHistory).toBe(true)
  })

  it('resets hasLoadedHistory to false when CHECK_MIGRATION_SUCCESS returns an end state', () => {
    const newState = reduce(actions.checkMigrationSuccess(MigrationStates.states.completed))
    expect(newState.hasLoadedHistory).toBe(false)
  })

  it('sets isLoadingHistory to true on LOAD_HISTORY_START', () => {
    const newState = reduce(actions.loadHistoryStart())
    expect(newState.isLoadingHistory).toBe(true)
  })

  it('sets isLoadingHistory to false on LOAD_HISTORY_SUCCESS', () => {
    const newState = reduce(actions.loadHistorySuccess({}))
    expect(newState.isLoadingHistory).toBe(false)
  })

  it('sets isLoadingHistory to false on LOAD_HISTORY_FAIL', () => {
    const newState = reduce(actions.loadHistoryFail())
    expect(newState.isLoadingHistory).toBe(false)
  })

  it('sets isLoadingUnynchedChanges to true on LOAD_UNSYNCED_CHANGES_START', () => {
    const newState = reduce(actions.loadUnsyncedChangesStart())
    expect(newState.isLoadingUnsyncedChanges).toBe(true)
  })

  it('sets isLoadingUnynchedChanges to false on LOAD_UNSYNCED_CHANGES_SUCCESS', () => {
    const newState = reduce(actions.loadUnsyncedChangesSuccess({}))
    expect(newState.isLoadingUnsyncedChanges).toBe(false)
  })

  it('sets isLoadingUnynchedChanges to false on LOAD_UNSYNCED_CHANGES_FAIL', () => {
    const newState = reduce(actions.loadUnsyncedChangesFail())
    expect(newState.isLoadingUnsyncedChanges).toBe(false)
  })

  it('sets hasLoadedUnsyncedChanges to false on LOAD_UNSYNCED_CHANGES_START', () => {
    const newState = reduce(actions.loadUnsyncedChangesStart())
    expect(newState.hasLoadedUnsyncedChanges).toBe(false)
  })

  it('sets hasLoadedUnsyncedChanges to true on LOAD_UNSYNCED_CHANGES_SUCCESS', () => {
    const newState = reduce(actions.loadUnsyncedChangesSuccess({}))
    expect(newState.hasLoadedUnsyncedChanges).toBe(true)
  })

  it('sets unsyncedChanges on LOAD_UNSYNCED_CHANGES_SUCCESS', () => {
    const newState = reduce(actions.loadUnsyncedChangesSuccess(getSampleData().unsyncedChanges))
    expect(newState.unsyncedChanges).toEqual(getSampleData().unsyncedChanges)
  })

  it('sets willSendNotification on ENABLE_SEND_NOTIFICATION', () => {
    let newState = reduce(actions.enableSendNotification(true))
    expect(newState.willSendNotification).toBe(true)
    newState = reduce(actions.enableSendNotification(false))
    expect(newState.willSendNotification).toBe(false)
  })

  it('sets willIncludeCourseSettings on INCLUDE_COURSE_SETTINGS', () => {
    let newState = reduce(actions.includeCourseSettings(true))
    expect(newState.willIncludeCourseSettings).toBe(true)
    newState = reduce(actions.includeCourseSettings(false))
    expect(newState.willIncludeCourseSettings).toBe(false)
  })

  it('creates empty change log entry on SELECT_CHANGE_LOG', () => {
    const newState = reduce(actions.realSelectChangeLog({changeId: '5'}))
    expect(newState.changeLogs).toEqual({
      5: {
        changeId: '5',
        status: LoadStates.states.not_loaded,
        data: null,
      },
    })
  })

  it('sets change log status to loading on LOAD_CHANGE_START', () => {
    const newState = reduce(actions.loadChangeStart({changeId: '5'}))
    expect(newState.changeLogs).toEqual({
      5: {
        changeId: '5',
        status: LoadStates.states.loading,
        data: null,
      },
    })
  })

  it('sets change log data and status to loaded on LOAD_CHANGE_SUCCESS', () => {
    const newState = reduce(actions.loadChangeSuccess({changeId: '5', changes: ['1', '2']}))
    expect(newState.changeLogs).toEqual({
      5: {
        changeId: '5',
        status: LoadStates.states.loaded,
        data: {changeId: '5', changes: ['1', '2']},
      },
    })
  })

  it('sets change log status to not loaded on LOAD_CHANGE_FAILED', () => {
    const newState = reduce(actions.loadChangeFail({changeId: '5'}))
    expect(newState.changeLogs).toEqual({
      5: {
        changeId: '5',
        status: LoadStates.states.not_loaded,
        data: null,
      },
    })
  })

  it('catches any action with err and message and treats it as an error notification', () => {
    const newState = reduce({
      type: '_NOT_A_REAL_ACTION_',
      payload: {message: 'hello world', err: 'bad things happened'},
    })
    expect(newState.notifications.length).toBe(1)
    expect(newState.notifications[0].type).toBe('error')
    expect(newState.notifications[0].message).toBe('hello world')
    expect(newState.notifications[0].err).toBe('bad things happened')
  })

  it('adds new info notification on NOTIFY_INFO', () => {
    const newState = reduce(actions.notifyInfo({message: 'hello world'}))
    expect(newState.notifications.length).toBe(1)
    expect(newState.notifications[0].type).toBe('info')
    expect(newState.notifications[0].message).toBe('hello world')
  })

  it('adds new error notification on NOTIFY_ERROR', () => {
    const newState = reduce(
      actions.notifyError({message: 'hello world', err: 'bad things happened'})
    )
    expect(newState.notifications.length).toBe(1)
    expect(newState.notifications[0].type).toBe('error')
    expect(newState.notifications[0].message).toBe('hello world')
    expect(newState.notifications[0].err).toBe('bad things happened')
  })

  it('clear notification on CLEAR_NOTIFICATION', () => {
    const newState = reduce(actions.clearNotification('1'), {
      notifications: [{id: '1', message: 'hello world', type: 'info'}],
    })
    expect(newState.notifications.length).toBe(0)
  })
})
