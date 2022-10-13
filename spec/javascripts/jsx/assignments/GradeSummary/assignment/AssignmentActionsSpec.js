/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import * as AssignmentActions from 'ui/features/assignment_grade_summary/react/assignment/AssignmentActions'
import * as AssignmentApi from 'ui/features/assignment_grade_summary/react/assignment/AssignmentApi'
import configureStore from 'ui/features/assignment_grade_summary/react/configureStore'

QUnit.module('GradeSummary AssignmentActions', suiteHooks => {
  let store

  suiteHooks.beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment',
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}],
    })
  })

  QUnit.module('.updateAssignment()', () => {
    test('updates the assignment in the store', () => {
      store.dispatch(AssignmentActions.updateAssignment({gradesPublished: true}))
      const {assignment} = store.getState().assignment
      strictEqual(assignment.gradesPublished, true)
    })
  })

  QUnit.module('.releaseGrades()', hooks => {
    let args
    let rejectPromise
    let resolvePromise

    hooks.beforeEach(() => {
      const fakePromise = {
        then(callback) {
          resolvePromise = callback
          return fakePromise
        },

        catch(callback) {
          rejectPromise = callback
        },
      }

      sinon.stub(AssignmentApi, 'releaseGrades').callsFake((courseId, assignmentId) => {
        args = {courseId, assignmentId}
        return fakePromise
      })

      store.dispatch(AssignmentActions.releaseGrades())
    })

    hooks.afterEach(() => {
      args = null
      AssignmentApi.releaseGrades.restore()
    })

    test('sets the "release grades" status to "started"', () => {
      const {releaseGradesStatus} = store.getState().assignment
      equal(releaseGradesStatus, AssignmentActions.STARTED)
    })

    test('releases grades through the api', () => {
      strictEqual(AssignmentApi.releaseGrades.callCount, 1)
    })

    test('includes the course id when releasing through the api', () => {
      strictEqual(args.courseId, '1201')
    })

    test('includes the assignment id when releasing through the api', () => {
      strictEqual(args.assignmentId, '2301')
    })

    test('updates the assignment in the store when the request succeeds', () => {
      resolvePromise()
      const {assignment} = store.getState().assignment
      strictEqual(assignment.gradesPublished, true)
    })

    test('sets the "release grades" status to "success" when the request succeeds', () => {
      resolvePromise()
      const {releaseGradesStatus} = store.getState().assignment
      equal(releaseGradesStatus, AssignmentActions.SUCCESS)
    })

    test('sets the "release grades" status to "already released" when grades were already released', () => {
      rejectPromise({response: {status: 400}})
      const {releaseGradesStatus} = store.getState().assignment
      equal(releaseGradesStatus, AssignmentActions.GRADES_ALREADY_RELEASED)
    })

    test('sets the "release grades" status to "not all selected" when a submission has no selected grade', () => {
      rejectPromise({response: {status: 422}})
      const {releaseGradesStatus} = store.getState().assignment
      equal(releaseGradesStatus, AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE)
    })

    test('sets the "release grades" status to "failure" when any other failure occurs', () => {
      rejectPromise({response: {status: 500}})
      const {releaseGradesStatus} = store.getState().assignment
      equal(releaseGradesStatus, AssignmentActions.FAILURE)
    })
  })

  QUnit.module('.unmuteAssignment()', hooks => {
    let args
    let rejectPromise
    let resolvePromise

    hooks.beforeEach(() => {
      const fakePromise = {
        then(callback) {
          resolvePromise = callback
          return fakePromise
        },

        catch(callback) {
          rejectPromise = callback
        },
      }

      sinon.stub(AssignmentApi, 'unmuteAssignment').callsFake((courseId, assignmentId) => {
        args = {courseId, assignmentId}
        return fakePromise
      })

      store.dispatch(AssignmentActions.unmuteAssignment())
    })

    hooks.afterEach(() => {
      args = null
      AssignmentApi.unmuteAssignment.restore()
    })

    test('sets the "unmuted assignment" status to "started"', () => {
      const {unmuteAssignmentStatus} = store.getState().assignment
      equal(unmuteAssignmentStatus, AssignmentActions.STARTED)
    })

    test('releases grades through the api', () => {
      strictEqual(AssignmentApi.unmuteAssignment.callCount, 1)
    })

    test('includes the course id when releasing through the api', () => {
      strictEqual(args.courseId, '1201')
    })

    test('includes the assignment id when releasing through the api', () => {
      strictEqual(args.assignmentId, '2301')
    })

    test('updates the assignment in the store when the request succeeds', () => {
      resolvePromise()
      const {assignment} = store.getState().assignment
      strictEqual(assignment.muted, false)
    })

    test('sets the "unmuted assignment" status to "success" when the request succeeds', () => {
      resolvePromise()
      const {unmuteAssignmentStatus} = store.getState().assignment
      equal(unmuteAssignmentStatus, AssignmentActions.SUCCESS)
    })

    test('sets the "unmuted assignment" status to "failure" when the request fails', () => {
      rejectPromise(new Error('server error'))
      const {unmuteAssignmentStatus} = store.getState().assignment
      equal(unmuteAssignmentStatus, AssignmentActions.FAILURE)
    })
  })
})
