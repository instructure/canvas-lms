/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import LoadStates from '../loadStates'
import MigrationStates from '../migrationStates'

describe('Blueprint Course redux actions', () => {
  describe('notifications', () => {
    it('creates info notification with correct type and message', () => {
      const action = actions.notifyInfo({message: 'test message'})
      expect(action).toEqual({
        type: 'NOTIFY_INFO',
        payload: {type: 'info', message: 'test message'},
      })
    })

    it('creates error notification with correct type and message', () => {
      const action = actions.notifyError({message: 'error message'})
      expect(action).toEqual({
        type: 'NOTIFY_ERROR',
        payload: {type: 'error', message: 'error message'},
      })
    })
  })

  describe('association actions', () => {
    it('creates action to add course associations', () => {
      const courseIds = ['1', '2']
      const action = actions.addCourseAssociations(courseIds)
      expect(action).toEqual({
        type: 'ADD_COURSE_ASSOCIATIONS',
        payload: courseIds,
      })
    })

    it('creates action to remove course associations', () => {
      const courseIds = ['1', '2']
      const action = actions.removeCourseAssociations(courseIds)
      expect(action).toEqual({
        type: 'REMOVE_COURSE_ASSOCIATIONS',
        payload: courseIds,
      })
    })

    it('creates action to undo add course associations', () => {
      const courseIds = ['1', '2']
      const action = actions.undoAddCourseAssociations(courseIds)
      expect(action).toEqual({
        type: 'UNDO_ADD_COURSE_ASSOCIATIONS',
        payload: courseIds,
      })
    })

    it('creates action to undo remove course associations', () => {
      const courseIds = ['1', '2']
      const action = actions.undoRemoveCourseAssociations(courseIds)
      expect(action).toEqual({
        type: 'UNDO_REMOVE_COURSE_ASSOCIATIONS',
        payload: courseIds,
      })
    })
  })

  describe('migration actions', () => {
    it('creates action to start migration', () => {
      const action = actions.beginMigrationStart()
      expect(action).toEqual({type: 'BEGIN_MIGRATION_START'})
    })

    it('creates action for successful migration', () => {
      const migrationData = {workflow_state: MigrationStates.states.completed}
      const action = actions.beginMigrationSuccess(migrationData)
      expect(action).toEqual({
        type: 'BEGIN_MIGRATION_SUCCESS',
        payload: migrationData,
      })
    })

    it('creates action for migration failure', () => {
      const error = {message: 'Migration failed'}
      const action = actions.beginMigrationFail(error)
      expect(action).toEqual({
        type: 'BEGIN_MIGRATION_FAIL',
        payload: error,
      })
    })
  })

  describe('change log actions', () => {
    it('creates action to start loading change', () => {
      const params = {changeId: '123'}
      const action = actions.loadChangeStart(params)
      expect(action).toEqual({
        type: 'LOAD_CHANGE_START',
        payload: params,
      })
    })

    it('creates action for successful change load', () => {
      const changeData = {id: '123', changes: []}
      const action = actions.loadChangeSuccess(changeData)
      expect(action).toEqual({
        type: 'LOAD_CHANGE_SUCCESS',
        payload: changeData,
      })
    })

    it('creates action for change load failure', () => {
      const error = {message: 'Failed to load change'}
      const action = actions.loadChangeFail(error)
      expect(action).toEqual({
        type: 'LOAD_CHANGE_FAIL',
        payload: error,
      })
    })
  })

  describe('history actions', () => {
    it('creates action to start loading history', () => {
      const action = actions.loadHistoryStart()
      expect(action).toEqual({type: 'LOAD_HISTORY_START'})
    })

    it('creates action for successful history load', () => {
      const historyData = {changes: []}
      const action = actions.loadHistorySuccess(historyData)
      expect(action).toEqual({
        type: 'LOAD_HISTORY_SUCCESS',
        payload: historyData,
      })
    })

    it('creates action for history load failure', () => {
      const error = {message: 'Failed to load history'}
      const action = actions.loadHistoryFail(error)
      expect(action).toEqual({
        type: 'LOAD_HISTORY_FAIL',
        payload: error,
      })
    })
  })

  describe('courses actions', () => {
    it('creates action to start loading courses', () => {
      const action = actions.loadCoursesStart()
      expect(action).toEqual({type: 'LOAD_COURSES_START'})
    })

    it('creates action for successful courses load', () => {
      const coursesData = {data: [{id: '1', name: 'Course 1'}]}
      const action = actions.loadCoursesSuccess(coursesData)
      expect(action).toEqual({
        type: 'LOAD_COURSES_SUCCESS',
        payload: coursesData,
      })
    })

    it('creates action for courses load failure', () => {
      const error = {message: 'Failed to load courses'}
      const action = actions.loadCoursesFail(error)
      expect(action).toEqual({
        type: 'LOAD_COURSES_FAIL',
        payload: error,
      })
    })
  })

  describe('unsynced changes actions', () => {
    it('creates action to start loading unsynced changes', () => {
      const action = actions.loadUnsyncedChangesStart()
      expect(action).toEqual({type: 'LOAD_UNSYNCED_CHANGES_START'})
    })

    it('creates action for successful unsynced changes load', () => {
      const changesData = {data: [{id: '1', changes: []}]}
      const action = actions.loadUnsyncedChangesSuccess(changesData)
      expect(action).toEqual({
        type: 'LOAD_UNSYNCED_CHANGES_SUCCESS',
        payload: changesData,
      })
    })

    it('creates action for unsynced changes load failure', () => {
      const error = {message: 'Failed to load unsynced changes'}
      const action = actions.loadUnsyncedChangesFail(error)
      expect(action).toEqual({
        type: 'LOAD_UNSYNCED_CHANGES_FAIL',
        payload: error,
      })
    })
  })

  describe('associations actions', () => {
    it('creates action to start loading associations', () => {
      const action = actions.loadAssociationsStart()
      expect(action).toEqual({type: 'LOAD_ASSOCIATIONS_START'})
    })

    it('creates action for successful associations load', () => {
      const associationsData = {data: [{id: '1', term_name: 'Term 1'}]}
      const action = actions.loadAssociationsSuccess(associationsData)
      expect(action).toEqual({
        type: 'LOAD_ASSOCIATIONS_SUCCESS',
        payload: associationsData,
      })
    })

    it('creates action for associations load failure', () => {
      const error = {message: 'Failed to load associations'}
      const action = actions.loadAssociationsFail(error)
      expect(action).toEqual({
        type: 'LOAD_ASSOCIATIONS_FAIL',
        payload: error,
      })
    })
  })

  describe('save associations actions', () => {
    it('creates action to start saving associations', () => {
      const action = actions.saveAssociationsStart()
      expect(action).toEqual({type: 'SAVE_ASSOCIATIONS_START'})
    })

    it('creates action for successful associations save', () => {
      const associationsData = {data: [{id: '1', term_name: 'Term 1'}]}
      const action = actions.saveAssociationsSuccess(associationsData)
      expect(action).toEqual({
        type: 'SAVE_ASSOCIATIONS_SUCCESS',
        payload: associationsData,
      })
    })

    it('creates action for associations save failure', () => {
      const error = {message: 'Failed to save associations'}
      const action = actions.saveAssociationsFail(error)
      expect(action).toEqual({
        type: 'SAVE_ASSOCIATIONS_FAIL',
        payload: error,
      })
    })
  })

  describe('check migration actions', () => {
    it('creates action to start checking migration', () => {
      const action = actions.checkMigrationStart()
      expect(action).toEqual({type: 'CHECK_MIGRATION_START'})
    })

    it('creates action for successful migration check', () => {
      const migrationData = {workflow_state: MigrationStates.states.completed}
      const action = actions.checkMigrationSuccess(migrationData)
      expect(action).toEqual({
        type: 'CHECK_MIGRATION_SUCCESS',
        payload: migrationData,
      })
    })

    it('creates action for migration check failure', () => {
      const error = {message: 'Failed to check migration'}
      const action = actions.checkMigrationFail(error)
      expect(action).toEqual({
        type: 'CHECK_MIGRATION_FAIL',
        payload: error,
      })
    })
  })
})
