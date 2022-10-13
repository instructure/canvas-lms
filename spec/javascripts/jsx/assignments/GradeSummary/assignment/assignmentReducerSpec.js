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
import configureStore from 'ui/features/assignment_grade_summary/react/configureStore'

QUnit.module('GradeSummary assignmentReducer()', suiteHooks => {
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
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'},
      ],
    })
  })

  function getAssignment() {
    return store.getState().assignment.assignment
  }

  QUnit.module('when handling "UPDATE_ASSIGNMENT"', () => {
    test('updates the assignment in the store', () => {
      store.dispatch(AssignmentActions.updateAssignment({gradesPublished: true}))
      strictEqual(getAssignment().gradesPublished, true)
    })

    test('replaces the instance of the assignment', () => {
      const assignment = getAssignment()
      store.dispatch(AssignmentActions.updateAssignment({gradesPublished: true}))
      notEqual(getAssignment(), assignment)
    })
  })

  QUnit.module('when handling "SET_RELEASE_GRADES_STATUS"', () => {
    function setReleaseGradesStatus(status) {
      store.dispatch(AssignmentActions.setReleaseGradesStatus(status))
    }

    function getReleaseGradesStatus() {
      return store.getState().assignment.releaseGradesStatus
    }

    test('optionally sets the "release grades" status to "failure"', () => {
      setReleaseGradesStatus(AssignmentActions.FAILURE)
      equal(getReleaseGradesStatus(), 'FAILURE')
    })

    test('optionally sets the "release grades" status to "started"', () => {
      setReleaseGradesStatus(AssignmentActions.STARTED)
      equal(getReleaseGradesStatus(), 'STARTED')
    })

    test('optionally sets the "release grades" status to "success"', () => {
      setReleaseGradesStatus(AssignmentActions.SUCCESS)
      equal(getReleaseGradesStatus(), 'SUCCESS')
    })

    test('optionally sets the "release grades" status to "already released"', () => {
      setReleaseGradesStatus(AssignmentActions.GRADES_ALREADY_RELEASED)
      equal(getReleaseGradesStatus(), 'GRADES_ALREADY_RELEASED')
    })

    test('optionally sets the "release grades" status to "not all selected"', () => {
      setReleaseGradesStatus(AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE)
      equal(getReleaseGradesStatus(), 'NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE')
    })

    test('optionally sets the "release grades" status to "selected grades from unavailable graders"', () => {
      setReleaseGradesStatus(AssignmentActions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS)
      equal(getReleaseGradesStatus(), 'SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS')
    })
  })

  QUnit.module('when handling "SET_UNMUTE_ASSIGNMENT_STATUS"', () => {
    function setUnmuteAssignmentStatus(status) {
      store.dispatch(AssignmentActions.setUnmuteAssignmentStatus(status))
    }

    function getUnmuteAssignmentStatus() {
      return store.getState().assignment.unmuteAssignmentStatus
    }

    test('optionally sets the "unmute assignment" status to "failure"', () => {
      setUnmuteAssignmentStatus(AssignmentActions.FAILURE)
      equal(getUnmuteAssignmentStatus(), 'FAILURE')
    })

    test('optionally sets the "unmute assignment" status to "started"', () => {
      setUnmuteAssignmentStatus(AssignmentActions.STARTED)
      equal(getUnmuteAssignmentStatus(), 'STARTED')
    })

    test('optionally sets the "unmute assignment" status to "success"', () => {
      setUnmuteAssignmentStatus(AssignmentActions.SUCCESS)
      equal(getUnmuteAssignmentStatus(), 'SUCCESS')
    })
  })
})
