/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import apiClient from 'jsx/blueprint_courses/apiClient'
import LoadStates from 'jsx/blueprint_courses/loadStates'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'

let sandbox = null

const mockApiClient = (method, res) => {
  sandbox = sinon.sandbox.create()
  sandbox.stub(apiClient, method).returns(res)
}

const mockSuccess = (method, data = {}) => mockApiClient(method, Promise.resolve(data))
const mockFail = (method, err = new Error('Request Failed')) => mockApiClient(method, Promise.reject(err))

QUnit.module('Blueprint Course redux actions', {
  teardown () {
    if (sandbox) sandbox.restore()
    sandbox = null
  }
})

test('notifyInfo dispatches NOTIFY_INFO with type "info" and payload', () => {
  const action = actions.notifyInfo({ message: 'test' })
  deepEqual(action, { type: 'NOTIFY_INFO', payload: { type: 'info', message: 'test' } })
})

test('notifyInfo dispatches NOTIFY_ERROR with type "error" and payload', () => {
  const action = actions.notifyError({ message: 'test' })
  deepEqual(action, { type: 'NOTIFY_ERROR', payload: { type: 'error', message: 'test' } })
})

test('loadChange dispatches LOAD_CHANGE_START if not already loading', () => {
  const changeId = '2'
  const getState = () => ({ changeLogs: { [changeId]: { status: LoadStates.states.not_loaded } } })
  const dispatchSpy = sinon.spy()

  mockSuccess('getFullMigration')
  actions.loadChange({ changeId })(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'LOAD_CHANGE_START', payload: { changeId } }])
})

test('loadChange does not dispatch LOAD_CHANGE_START if change is already loading', () => {
  const changeId = '2'
  const getState = () => ({ changeLogs: { [changeId]: { status: LoadStates.states.loading } } })
  const dispatchSpy = sinon.spy()

  mockSuccess('getFullMigration')
  actions.loadChange({ changeId })(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 0)
})

test('loadChange dispatches LOAD_CHANGE_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()
  const changeId = '2'
  const getState = () => ({ changeLogs: { [changeId]: { status: LoadStates.states.not_loaded } } })
  const dispatchSpy = sinon.spy()

  mockSuccess('getFullMigration', { foo: 'bar' })
  actions.loadChange({ changeId })(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'LOAD_CHANGE_SUCCESS', payload: { foo: 'bar' } }])
    done()
  }, 1)
})

test('loadChange dispatches LOAD_CHANGE_FAIL if API returns error', (assert) => {
  const done = assert.async()

  const changeId = '2'
  const getState = () => ({ changeLogs: { [changeId]: { status: LoadStates.states.not_loaded } } })
  const dispatchSpy = sinon.spy()

  mockFail('getFullMigration')
  actions.loadChange({ changeId })(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    equal(dispatchSpy.secondCall.args[0].type, 'LOAD_CHANGE_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('selectChangeLog dispatches SELECT_CHANGE_LOG with changeId', () => {
  const changeId = '2'
  const getState = () => ({ changeLogs: {} })
  const dispatchSpy = sinon.spy()

  mockSuccess('getFullMigration')
  actions.selectChangeLog({ changeId })(dispatchSpy, getState)

  deepEqual(dispatchSpy.firstCall.args, [{ type: 'SELECT_CHANGE_LOG', payload: { changeId } }])
})

test('selectChangeLog dispatches LOAD_CHANGE_START if change not already loaded', () => {
  const changeId = '2'
  const getState = () => ({ changeLogs: { [changeId]: { status: LoadStates.states.not_loaded } } })
  const dispatchSpy = sinon.spy()

  mockSuccess('getFullMigration')
  actions.selectChangeLog({ changeId })(dispatchSpy, getState)

  deepEqual(dispatchSpy.secondCall.args, [{ type: 'LOAD_CHANGE_START', payload: { changeId } }])
})

test('selectChangeLog does not dispatch LOAD_CHANGE_START if change already loaded', () => {
  const changeId = '2'
  const getState = () => ({ changeLogs: { [changeId]: { status: LoadStates.states.loaded } } })
  const dispatchSpy = sinon.spy()

  mockSuccess('getFullMigration')
  actions.selectChangeLog({ changeId })(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'SELECT_CHANGE_LOG', payload: { changeId } }])
})

test('selectChangeLog does not dispatch LOAD_CHANGE_START if changeId is null', () => {
  const getState = () => ({ changeLogs: {} })
  const dispatchSpy = sinon.spy()

  mockSuccess('getFullMigration')
  actions.selectChangeLog(null)(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ payload: null, type: 'SELECT_CHANGE_LOG' }])
})

test('loadHistory dispatches LOAD_HISTORY_START', () => {
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('getSyncHistory')
  actions.loadHistory()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'LOAD_HISTORY_START' }])
})

test('loadHistory dispatches LOAD_HISTORY_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('getSyncHistory', { foo: 'bar' })
  actions.loadHistory()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'LOAD_HISTORY_SUCCESS', payload: { foo: 'bar' } }])
    done()
  }, 1)
})

test('loadHistory dispatches LOAD_HISTORY_FAIL if API returns error', (assert) => {
  const done = assert.async()
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockFail('getSyncHistory')
  actions.loadHistory()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    equal(dispatchSpy.secondCall.args[0].type, 'LOAD_HISTORY_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('loadCourses dispatches LOAD_COURSES_START', () => {
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('getCourses')
  actions.loadCourses()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'LOAD_COURSES_START' }])
})

test('loadCourses dispatches LOAD_COURSES_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('getCourses', { data: [{ foo: 'bar' }] })
  actions.loadCourses()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'LOAD_COURSES_SUCCESS', payload: [{ foo: 'bar' }] }])
    done()
  }, 1)
})

test('loadCourses dispatches LOAD_COURSES_FAIL if API returns error', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockFail('getCourses')
  actions.loadCourses()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    equal(dispatchSpy.secondCall.args[0].type, 'LOAD_COURSES_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('loadUnsyncedChanges dispatches LOAD_UNSYNCED_CHANGES_START', () => {
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('loadUnsyncedChanges')
  actions.loadUnsyncedChanges()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'LOAD_UNSYNCED_CHANGES_START' }])
})

test('loadUnsyncedChanges dispatches LOAD_UNSYNCED_CHANGES_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('loadUnsyncedChanges', { data: [{ foo: 'bar' }] })
  actions.loadUnsyncedChanges()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'LOAD_UNSYNCED_CHANGES_SUCCESS', payload: [{ foo: 'bar' }] }])
    done()
  }, 1)
})

test('loadUnsyncedChanges dispatches LOAD_UNSYNCED_CHANGES_FAIL if API returns error', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockFail('loadUnsyncedChanges')
  actions.loadUnsyncedChanges()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    equal(dispatchSpy.secondCall.args[0].type, 'LOAD_UNSYNCED_CHANGES_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('loadAssociations dispatches LOAD_ASSOCIATIONS_START if not already in progress', () => {
  const getState = () => ({ isLoadingAssociations: false })
  const dispatchSpy = sinon.spy()

  mockSuccess('getAssociations')
  actions.loadAssociations()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'LOAD_ASSOCIATIONS_START' }])
})

test('loadAssociations does not dispatch LOAD_ASSOCIATIONS_START if already in progress', () => {
  const getState = () => ({ isLoadingAssociations: true })
  const dispatchSpy = sinon.spy()

  mockSuccess('getAssociations')
  actions.loadAssociations()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 0)
})

test('loadAssociations dispatches LOAD_ASSOCIATIONS_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('getAssociations', { data: [{ foo: 'bar', term_name: 'Foo Term' }] })
  actions.loadAssociations()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'LOAD_ASSOCIATIONS_SUCCESS', payload: [{ foo: 'bar', term: { id: '0', name: 'Foo Term' } }] }])
    done()
  }, 1)
})

test('loadAssociations dispatches LOAD_ASSOCIATIONS_FAIL if API returns error', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockFail('getAssociations')
  actions.loadAssociations()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    equal(dispatchSpy.secondCall.args[0].type, 'LOAD_ASSOCIATIONS_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('saveAssociations dispatches SAVE_ASSOCIATIONS_START', () => {
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('saveAssociations')
  actions.saveAssociations()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'SAVE_ASSOCIATIONS_START' }])
})

test('saveAssociations dispatches SAVE_ASSOCIATIONS_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()

  const getState = () => ({ addedAssociations: ['2'], removedAssociations: ['1'] })
  const dispatchSpy = sinon.spy()

  mockSuccess('saveAssociations', { data: [{ foo: 'bar', term_name: 'Foo Term' }] })
  actions.saveAssociations()(dispatchSpy, getState)

  setTimeout(() => {
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'SAVE_ASSOCIATIONS_SUCCESS', payload: { added: ['2'], removed: ['1'] } }])
    done()
  }, 1)
})

test('saveAssociations dispatches NOTIFY_INFO if API returns successfully', (assert) => {
  const done = assert.async()

  const getState = () => ({ addedAssociations: ['2'], removedAssociations: ['1'] })
  const dispatchSpy = sinon.spy()

  mockSuccess('saveAssociations', { data: [{ foo: 'bar', term_name: 'Foo Term' }] })
  actions.saveAssociations()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.thirdCall.args[0].type, 'NOTIFY_INFO')
    done()
  }, 1)
})

test('saveAssociations calls beginMigration if API returns successfully and there were added associations', (assert) => {
  const done = assert.async()

  const getState = () => ({ addedAssociations: ['2'], removedAssociations: ['1'] })
  const dispatchSpy = sinon.spy()
  const beginMigrationSpy = sinon.spy(actions, 'beginMigration')

  mockSuccess('saveAssociations', { data: [{ foo: 'bar', term_name: 'Foo Term' }] })
  actions.saveAssociations()(dispatchSpy, getState)

  setTimeout(() => {
    equal(beginMigrationSpy.callCount, 1)
    beginMigrationSpy.restore()
    done()
  }, 1)
})

test('saveAssociations does not call beginMigration if API returns successfully and there were no added associations', (assert) => {
  const done = assert.async()

  const getState = () => ({ addedAssociations: [], removedAssociations: ['1'] })
  const dispatchSpy = sinon.spy()
  const beginMigrationSpy = sinon.spy(actions, 'beginMigration')

  mockSuccess('saveAssociations', { data: [{ foo: 'bar', term_name: 'Foo Term' }] })
  actions.saveAssociations()(dispatchSpy, getState)

  setTimeout(() => {
    equal(beginMigrationSpy.callCount, 0)
    beginMigrationSpy.restore()
    done()
  }, 1)
})

test('saveAssociations dispatches SAVE_ASSOCIATIONS_FAIL if API returns error', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockFail('saveAssociations')
  actions.saveAssociations()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    equal(dispatchSpy.secondCall.args[0].type, 'SAVE_ASSOCIATIONS_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('beginMigration dispatches BEGIN_MIGRATION_START', () => {
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('beginMigration')
  actions.beginMigration()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'BEGIN_MIGRATION_START' }])
})

test('beginMigration dispatches BEGIN_MIGRATION_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('beginMigration', { data: { workflow_state: MigrationStates.states.queued } })
  actions.beginMigration()(dispatchSpy, getState)

  setTimeout(() => {
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'BEGIN_MIGRATION_SUCCESS', payload: { workflow_state: MigrationStates.states.queued } }])
    done()
  }, 1)
})

test('beginMigration dispatches BEGIN_MIGRATION_FAIL if API returns error', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockFail('beginMigration')
  actions.beginMigration()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'BEGIN_MIGRATION_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('beginMigration calls startMigrationStatusPoll if API returns successfully and the new migration is in a loading state', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()
  const startPollSpy = sinon.spy(actions, 'startMigrationStatusPoll')

  mockSuccess('beginMigration', { data: { workflow_state: MigrationStates.states.queued } })
  actions.beginMigration()(dispatchSpy, getState)

  setTimeout(() => {
    equal(startPollSpy.callCount, 1)
    startPollSpy.restore()
    done()
  }, 1)
})

test('beginMigration does not call startMigrationStatusPoll if API returns successfully and new migration is not in  aloading state', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const startPollSpy = sinon.spy(actions, 'startMigrationStatusPoll')

  mockSuccess('beginMigration', { data: { workflow_state: MigrationStates.states.completed } })
  actions.beginMigration()(() => {}, getState)

  setTimeout(() => {
    equal(startPollSpy.callCount, 0)
    startPollSpy.restore()
    done()
  }, 1)
})

test('startMigrationStatusPoll calls pollMigrationStatus on an interval', (assert) => {
  const done = assert.async()

  const realTime = actions.constants.MIGRATION_POLL_TIME
  actions.constants.MIGRATION_POLL_TIME = 1

  const getState = () => ({})
  const pollMigrationSpy = sinon.spy(actions, 'pollMigrationStatus')

  mockSuccess('checkMigration', { data: { workflow_state: MigrationStates.states.completed } })
  actions.startMigrationStatusPoll()(() => {}, getState)

  setTimeout(() => {
    ok(pollMigrationSpy.callCount >= 1)
    actions.stopMigrationStatusPoll()()
    actions.constants.MIGRATION_POLL_TIME = realTime
    pollMigrationSpy.restore()
    done()
  }, 10)
})

test('checkMigration dispatches CHECK_MIGRATION_START if not already in progress', () => {
  const getState = () => ({ isCheckingMigration: false })
  const dispatchSpy = sinon.spy()

  mockSuccess('checkMigration')
  actions.checkMigration()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'CHECK_MIGRATION_START' }])
})

test('checkMigration does not dispatch CHECK_MIGRATION_START if already in progress', () => {
  const getState = () => ({ isCheckingMigration: true })
  const dispatchSpy = sinon.spy()

  mockSuccess('checkMigration')
  actions.checkMigration()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 0)
})

test('checkMigration dispatches CHECK_MIGRATION_SUCCESS if API returns successfully', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('checkMigration', { data: { workflow_state: MigrationStates.states.completed } })
  actions.checkMigration()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'CHECK_MIGRATION_SUCCESS', payload: { workflow_state: MigrationStates.states.completed } }])
    done()
  }, 1)
})

test('checkMigration dispatches CHECK_MIGRATION_FAIL if API returns error', (assert) => {
  const done = assert.async()

  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockFail('checkMigration')
  actions.checkMigration()(dispatchSpy, getState)

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    equal(dispatchSpy.secondCall.args[0].type, 'CHECK_MIGRATION_FAIL')
    ok(dispatchSpy.secondCall.args[0].payload.err instanceof Error)
    done()
  }, 1)
})

test('addAssociations dispatches ADD_COURSE_ASSOCIATIONS when added associations are new', () => {
  const getState = () => ({
    courses: [
      { id: '1', name: 'First Course' },
      { id: '2', name: 'Second Course' },
    ],
    existingAssociations: [],
  })
  const dispatchSpy = sinon.spy()
  actions.addAssociations(['1'])(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'ADD_COURSE_ASSOCIATIONS', payload: [{ id: '1', name: 'First Course' }] }])
})

test('addAssociations dispatches UNDO_REMOVE_COURSE_ASSOCIATIONS when added associations are existing', () => {
  const getState = () => ({
    courses: [
      { id: '1', name: 'First Course' },
      { id: '2', name: 'Second Course' },
    ],
    existingAssociations: [{ id: '1', name: 'First Course' }],
  })
  const dispatchSpy = sinon.spy()
  actions.addAssociations(['1'])(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'UNDO_REMOVE_COURSE_ASSOCIATIONS', payload: ['1'] }])
})

test('removeAssociations dispatches REMOVE_COURSE_ASSOCIATIONS when removed associations are existing', () => {
  const getState = () => ({
    courses: [
      { id: '1', name: 'First Course' },
      { id: '2', name: 'Second Course' },
    ],
    existingAssociations: [{ id: '1', name: 'First Course' }],
  })
  const dispatchSpy = sinon.spy()
  actions.removeAssociations(['1'])(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'REMOVE_COURSE_ASSOCIATIONS', payload: [{ id: '1', name: 'First Course'}] }])
})

test('removeAssociations dispatches UNDO_ADD_COURSE_ASSOCIATIONS when removed associations are new', () => {
  const getState = () => ({
    courses: [
      { id: '1', name: 'First Course' },
      { id: '2', name: 'Second Course' },
    ],
    existingAssociations: [],
  })
  const dispatchSpy = sinon.spy()
  actions.removeAssociations(['1'])(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'UNDO_ADD_COURSE_ASSOCIATIONS', payload: ['1'] }])
})

test('startMigrationStatusPoll calls checkMigration if interval is not already in progress', () => {
  const getState = () => ({})
  const dispatchSpy = sinon.spy()

  mockSuccess('checkMigration')
  actions.startMigrationStatusPoll()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'CHECK_MIGRATION_START' }])
  actions.stopMigrationStatusPoll()()
})

test('startMigrationStatusPoll does not call checkMigration if interval is already in progress', () => {
  const getState = () => ({})
  const dispatchSpy = sinon.spy()
  mockSuccess('checkMigration')

  // call a poll so that its in progress
  actions.startMigrationStatusPoll()(() => {}, getState)

  // call a second one that we spy on. this one should not dispatch
  // anything because we have a poll already in progress
  actions.startMigrationStatusPoll()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 0)
  actions.stopMigrationStatusPoll()()
})

test('pollMigrationStatus calls checkMigration if is not checking migration and last migration is in a loading state', () => {
  const checkMigrationSpy = sinon.spy(actions, 'checkMigration')
  const getState = () => ({
    isCheckingMigration: false,
    migrationStatus: MigrationStates.states.queued,
  })

  mockSuccess('checkMigration', { data: { workflow_state: MigrationStates.states.completed } })
  actions.pollMigrationStatus()(() => {}, getState)

  equal(checkMigrationSpy.callCount, 1)
  actions.checkMigration.restore()
})

test('pollMigrationStatus does not call checkMigration if is not checking migration and last migration is not in a loading state', () => {
  const checkMigrationSpy = sinon.spy(actions, 'checkMigration')
  const getState = () => ({
    isCheckingMigration: false,
    migrationStatus: MigrationStates.states.unknown,
  })

  mockSuccess('checkMigration', { data: { workflow_state: MigrationStates.states.completed } })
  actions.pollMigrationStatus()(() => {}, getState)

  equal(checkMigrationSpy.callCount, 0)
  actions.checkMigration.restore()
})

test('pollMigrationStatus does not call checkMigration if is checking migration and last migration is in a loading state', () => {
  const checkMigrationSpy = sinon.spy(actions, 'checkMigration')
  const getState = () => ({
    isCheckingMigration: true,
    migrationStatus: MigrationStates.states.unknown,
  })

  mockSuccess('checkMigration', { data: { workflow_state: MigrationStates.states.completed } })
  actions.pollMigrationStatus()(() => {}, getState)

  equal(checkMigrationSpy.callCount, 0)
  actions.checkMigration.restore()
})

test('pollMigrationStatus calls stopMigrationStatusPoll if last migration is in an end state', () => {
  const stopMigrationSpy = sinon.spy(actions, 'stopMigrationStatusPoll')
  const getState = () => ({
    isCheckingMigration: false,
    migrationStatus: MigrationStates.states.completed,
  })
  actions.pollMigrationStatus()(() => {}, getState)

  equal(stopMigrationSpy.callCount, 1)
  actions.stopMigrationStatusPoll.restore()
})

test('pollMigrationStatus dispatched NOTIFY_INFO if last migration state is completed', () => {
  const dispatchSpy = sinon.spy()
  const getState = () => ({
    isCheckingMigration: false,
    migrationStatus: MigrationStates.states.completed,
  })
  actions.pollMigrationStatus()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  equal(dispatchSpy.firstCall.args[0].type, 'NOTIFY_INFO')
})

test('pollMigrationStatus dispatched NOTIFY_ERROR if last migration state is exports_failed', () => {
  const dispatchSpy = sinon.spy()
  const getState = () => ({
    isCheckingMigration: false,
    migrationStatus: MigrationStates.states.exports_failed,
  })
  actions.pollMigrationStatus()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  equal(dispatchSpy.firstCall.args[0].type, 'NOTIFY_ERROR')
})

test('pollMigrationStatus dispatched NOTIFY_ERROR if last migration state is imports_failed', () => {
  const dispatchSpy = sinon.spy()
  const getState = () => ({
    isCheckingMigration: false,
    migrationStatus: MigrationStates.states.imports_failed,
  })
  actions.pollMigrationStatus()(dispatchSpy, getState)

  equal(dispatchSpy.callCount, 1)
  equal(dispatchSpy.firstCall.args[0].type, 'NOTIFY_ERROR')
})
