/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import ModerationActions from 'jsx/assignments/actions/ModerationActions'

QUnit.module('ModerationActions - Action Creators')

test('creates the SORT_MARK1_COLUMN action', () => {
  const action = ModerationActions.sortMark1Column()
  const expected = {type: 'SORT_MARK1_COLUMN'}
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the SORT_MARK2_COLUMN action', () => {
  const action = ModerationActions.sortMark2Column()
  const expected = {type: 'SORT_MARK2_COLUMN'}
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the SORT_MARK3_COLUMN action', () => {
  const action = ModerationActions.sortMark3Column()
  const expected = {type: 'SORT_MARK3_COLUMN'}
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the SELECT_STUDENT action', () => {
  const action = ModerationActions.selectStudent(1)
  const expected = {
    type: ModerationActions.SELECT_STUDENT,
    payload: {studentId: 1}
  }
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the UNSELECT_STUDENT action', () => {
  const action = ModerationActions.unselectStudent(1)
  const expected = {
    type: ModerationActions.UNSELECT_STUDENT,
    payload: {studentId: 1}
  }
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the UPDATED_MODERATION_SET action', () => {
  const action = ModerationActions.moderationSetUpdated([{a: 1}, {b: 2}])
  const expected = {
    type: ModerationActions.UPDATED_MODERATION_SET,
    payload: {
      message: 'Reviewers successfully added',
      students: [{a: 1}, {b: 2}],
      time: Date.now()
    }
  }
  equal(action.type, expected.type, 'type matches')
  equal(action.payload.message, expected.payload.message, 'message matches')
  ok(
    expected.payload.time - action.payload.time < 10,
    `time within 10 seconds expected:${expected.payload.time} action: ${action.payload.time}`
  )
})

test('creates the UPDATE_MODERATION_SET_FAILED action', () => {
  const action = ModerationActions.moderationSetUpdateFailed()
  const expected = {
    type: ModerationActions.UPDATE_MODERATION_SET_FAILED,
    payload: {
      message: 'A problem occurred adding reviewers.',
      time: Date.now()
    }
  }
  equal(action.type, expected.type, 'type matches')
  equal(action.payload.message, expected.payload.message, 'message matches')
  ok(expected.payload.time - action.payload.time < 5, 'time within 5 seconds')
})

test('creates the GOT_STUDENTS action', () => {
  const action = ModerationActions.gotStudents([1, 2, 3])
  const expected = {
    type: ModerationActions.GOT_STUDENTS,
    payload: {
      students: [1, 2, 3]
    }
  }
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the PUBLISHED_GRADES action', () => {
  const action = ModerationActions.publishedGrades('test')
  const expected = {
    type: ModerationActions.PUBLISHED_GRADES,
    payload: {
      message: 'test',
      time: Date.now()
    }
  }
  equal(action.type, expected.type, 'type matches')
  equal(action.payload.message, expected.payload.message, 'message matches')
  ok(expected.payload.time - action.payload.time < 5, 'time within 5 seconds')
})

test('creates the PUBLISHED_GRADES_FAILED action', () => {
  const action = ModerationActions.publishGradesFailed('test')
  const expected = {
    type: ModerationActions.PUBLISHED_GRADES_FAILED,
    payload: {
      message: 'test',
      time: Date.now()
    },
    error: true
  }
  equal(action.type, expected.type, 'type matches')
  equal(action.payload.message, expected.payload.message, 'message matches')
  ok(action.error, 'error flag is set')
  ok(expected.payload.time - action.payload.time < 5, 'time within 5 seconds')
})

test('creates the SELECT_ALL_STUDENTS action', () => {
  const action = ModerationActions.selectAllStudents([{id: 1}, {id: 2}])
  const expected = {
    type: ModerationActions.SELECT_ALL_STUDENTS,
    payload: {
      students: [{id: 1}, {id: 2}]
    }
  }
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the UNSELECT_ALL_STUDENTS action', () => {
  const action = ModerationActions.unselectAllStudents()
  const expected = {type: ModerationActions.UNSELECT_ALL_STUDENTS}
  deepEqual(action, expected, 'creates the action successfully')
})

test('creates the SELECT_MARK action', () => {
  const action = ModerationActions.selectedProvisionalGrade(1, 2)
  const expected = {
    type: ModerationActions.SELECT_MARK,
    payload: {
      studentId: 1,
      selectedProvisionalId: 2
    }
  }
  deepEqual(action, expected, 'creates the action successfully')
})

QUnit.module('ModerationActions#apiGetStudents', {
  setup() {
    this.client = {
      get() {
        return new Promise(resolve => setTimeout(() => resolve('test'), 100))
      }
    }
  }
})

test('returns a function', () => ok(typeof ModerationActions.apiGetStudents() === 'function'))

test('dispatches gotStudents action', function(assert) {
  const start = assert.async()
  const getState = () => ({
    urls: {list_gradeable_students: 'some_url'},
    students: []
  })
  const fakeResponse = {data: ['test']}
  const gotStudentsAction = {
    type: ModerationActions.GOT_STUDENTS,
    payload: {students: ['test']}
  }
  this.stub(this.client, 'get').returns(Promise.resolve(fakeResponse))
  return ModerationActions.apiGetStudents(this.client)(action => {
    deepEqual(action, gotStudentsAction)
    return start()
  }, getState)
})

test('calls itself again if headers indicate more pages', function(assert) {
  const start = assert.async()
  const getState = () => ({
    urls: {list_gradeable_students: 'some_url'},
    students: []
  })
  const fakeHeaders = {
    link:
      '<http://some_url/>; rel="current",<http://some_url/?page=2>; rel="next",<http://some_url>; rel="first",<http://some_url>; rel="last"'
  }
  const fakeResponse = {
    data: ['test'],
    headers: fakeHeaders
  }
  let callCount = 0
  this.stub(this.client, 'get').returns(Promise.resolve(fakeResponse))
  return ModerationActions.apiGetStudents(this.client)(action => {
    callCount++
    if (callCount >= 2) {
      ok(callCount === 2)
      return start()
    }
  }, getState)
})

QUnit.module('ModerationActions#publishGrades', {
  setup() {
    this.client = {
      post() {
        return new Promise(resolve => setTimeout(() => resolve('test'), 100))
      }
    }
  }
})

test('returns a function', () => ok(typeof ModerationActions.publishGrades() === 'function'))

test('dispatches publishGrades action on success', function(assert) {
  const start = assert.async()
  const getState = () => ({urls: {publish_grades_url: 'some_url'}})
  const fakeResponse = {status: 200}
  const publishGradesAction = {
    type: ModerationActions.PUBLISHED_GRADES,
    payload: {message: 'Success! Grades were published to the grade book.'}
  }
  this.stub(this.client, 'post').returns(Promise.resolve(fakeResponse))
  return ModerationActions.publishGrades(this.client)(action => {
    equal(action.type, publishGradesAction.type, 'type matches')
    equal(action.payload.message, publishGradesAction.payload.message, 'has proper message')
    return start()
  }, getState)
})

test('dispatches publishGradesFailed action with already published message on 400 failure', function(assert) {
  const start = assert.async()
  const getState = () => ({urls: {publish_grades_url: 'some_url'}})
  const fakeResponse = {status: 400}
  const publishGradesAction = {
    type: ModerationActions.PUBLISHED_GRADES_FAILED,
    payload: {message: 'Assignment grades have already been published.'}
  }
  this.stub(this.client, 'post').returns(Promise.reject(fakeResponse))
  return ModerationActions.publishGrades(this.client)(action => {
    equal(action.type, publishGradesAction.type, 'type matches')
    equal(action.payload.message, publishGradesAction.payload.message, 'has proper message')
    return start()
  }, getState)
})

test('dispatches publishGradesFailed action with selected grades message on 422 failure', function(assert) {
  const start = assert.async()
  const getState = () => ({urls: {publish_grades_url: 'some_url'}})
  const fakeResponse = {status: 422}
  const publishGradesAction = {
    type: ModerationActions.PUBLISHED_GRADES_FAILED,
    payload: {message: 'All submissions must have a selected grade.'}
  }
  this.stub(this.client, 'post').returns(Promise.reject(fakeResponse))
  return ModerationActions.publishGrades(this.client)(action => {
    equal(action.type, publishGradesAction.type, 'type matches')
    equal(action.payload.message, publishGradesAction.payload.message, 'has proper message')
    return start()
  }, getState)
})

test('dispatches publishGradesFailed action with generic error message on non-400 error', function(assert) {
  assert.expect(2)
  const start = assert.async()
  const getState = () => ({urls: {publish_grades_url: 'some_url'}})
  const fakeResponse = {status: 500}
  const publishGradesAction = {
    type: ModerationActions.PUBLISHED_GRADES_FAILED,
    payload: {message: 'An error occurred publishing grades.'}
  }
  this.stub(this.client, 'post').returns(Promise.reject(fakeResponse))
  return ModerationActions.publishGrades(this.client)(action => {
    equal(action.type, publishGradesAction.type, 'type matches')
    equal(action.payload.message, publishGradesAction.payload.message, 'has proper message')
    return start()
  }, getState)
})

QUnit.module('ModerationActions#addStudentToModerationSet', {
  setup() {
    this.client = {
      post() {
        return new Promise(resolve => setTimeout(() => resolve('test'), 100))
      }
    }
  }
})

test('returns a function', () =>
  ok(typeof ModerationActions.addStudentToModerationSet() === 'function'))

test('dispatches moderationSetUpdated on success', function(assert) {
  const start = assert.async()
  const fakeUrl = 'some_url'
  const getState = () => ({
    urls: {add_moderated_students: fakeUrl},
    studentList: {
      students: [
        {
          id: 1,
          on_moderation_stage: true
        },
        {
          id: 2,
          on_moderation_stage: true
        }
      ]
    }
  })
  const fakeResponse = {
    status: 200,
    students: [{id: 1}, {id: 2}]
  }
  const moderationSetUpdatedAction = {
    type: ModerationActions.UPDATED_MODERATION_SET,
    payload: {message: 'Reviewers successfully added'}
  }
  const fakePost = this.stub(this.client, 'post').returns(Promise.resolve(fakeResponse))
  return ModerationActions.addStudentToModerationSet(this.client)(action => {
    ok(
      fakePost.calledWith(fakeUrl, {
        student_ids: [1, 2]
      }),
      'called with the correct params'
    )
    equal(action.type, moderationSetUpdatedAction.type, 'type matches')
    equal(action.payload.message, moderationSetUpdatedAction.payload.message, 'has proper message')
    return start()
  }, getState)
})

test('dispatches moderationSetUpdateFailed on failure', function(assert) {
  const start = assert.async()
  const getState = () => ({
    urls: {add_moderated_students: 'some_url'},
    studentList: {
      students: [
        {
          id: 1,
          on_moderation_stage: true
        },
        {
          id: 2,
          on_moderation_stage: true
        }
      ]
    }
  })
  const fakeResponse = {status: 500}
  const moderationSetUpdateFailedAction = {
    type: ModerationActions.UPDATE_MODERATION_SET_FAILED,
    payload: {message: 'A problem occurred adding reviewers.'}
  }
  this.stub(this.client, 'post').returns(Promise.reject(fakeResponse))
  return ModerationActions.addStudentToModerationSet(this.client)(action => {
    equal(action.type, moderationSetUpdateFailedAction.type, 'type matches')
    equal(
      action.payload.message,
      moderationSetUpdateFailedAction.payload.message,
      'has proper message'
    )
    return start()
  }, getState)
})

QUnit.module('ModerationActions#selectProvisionalGrade', {
  setup() {
    this.client = {
      put() {
        return new Promise(resolve => setTimeout(() => resolve('test'), 100))
      }
    }
  }
})

test('returns a function', () =>
  ok(typeof ModerationActions.selectProvisionalGrade(1) === 'function'))

test('dispatches selectProvisionalGrade on success', function(assert) {
  const start = assert.async()
  const fakeUrl = 'base_url'
  const getState = () => ({
    urls: {provisional_grades_base_url: fakeUrl},
    studentList: {
      students: [
        {
          id: 1,
          provisional_grades: [{provisional_grade_id: 42}],
          selected_provisional_grade_id: undefined
        }
      ]
    }
  })
  const fakeResponse = {
    status: 200,
    data: {
      student_id: 1,
      selected_provisional_grade_id: 42
    }
  }
  const fakePost = this.stub(this.client, 'put').returns(Promise.resolve(fakeResponse))
  return ModerationActions.selectProvisionalGrade(42, this.client)(action => {
    ok(fakePost.calledWith(`${fakeUrl}/` + `42` + `/select`), 'called with the correct params')
    equal(action.type, ModerationActions.SELECT_MARK, 'type matches')
    equal(action.payload.studentId, 1, 'has correct payload')
    equal(action.payload.selectedProvisionalId, 42, 'has correct payload')
    return start()
  }, getState)
})

test('dispatches displayErrorMessage on failure', function(assert) {
  const start = assert.async()
  const fakeUrl = 'base_url'
  const getState = () => ({
    urls: {provisional_grades_base_url: fakeUrl},
    studentList: {
      students: [
        {
          id: 1,
          provisional_grades: [{provisional_grade_id: 42}],
          selected_provisional_grade_id: undefined
        }
      ]
    }
  })
  const fakeResponse = {status: 404}
  const fakePost = this.stub(this.client, 'put').returns(Promise.resolve(fakeResponse))
  return ModerationActions.selectProvisionalGrade(42, this.client)(action => {
    ok(fakePost.calledWith(`${fakeUrl}/` + `42` + `/select`), 'called with the correct params')
    equal(action.type, ModerationActions.SELECTING_PROVISIONAL_GRADES_FAILED, 'type matches')
    equal(
      action.payload.message,
      'An error occurred selecting provisional grades',
      'has correct payload'
    )
    ok(action.payload instanceof Error, 'is an error object')
    equal(action.error, true, 'has correct payload')
    return start()
  }, getState)
})
