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

import * as AssignmentActions from 'jsx/assignments/GradeSummary/assignment/AssignmentActions'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

QUnit.module('GradeSummary assignmentReducer()', suiteHooks => {
  let store

  suiteHooks.beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment'
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ]
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

  QUnit.module('when handling "SET_PUBLISH_GRADES_STATUS"', () => {
    function setPublishGradesStatus(status) {
      store.dispatch(AssignmentActions.setPublishGradesStatus(status))
    }

    function getPublishGradesStatus() {
      return store.getState().assignment.publishGradesStatus
    }

    test('optionally sets the "publish grades" status to "failure"', () => {
      setPublishGradesStatus(AssignmentActions.FAILURE)
      equal(getPublishGradesStatus(), 'FAILURE')
    })

    test('optionally sets the "publish grades" status to "started"', () => {
      setPublishGradesStatus(AssignmentActions.STARTED)
      equal(getPublishGradesStatus(), 'STARTED')
    })

    test('optionally sets the "publish grades" status to "success"', () => {
      setPublishGradesStatus(AssignmentActions.SUCCESS)
      equal(getPublishGradesStatus(), 'SUCCESS')
    })

    test('optionally sets the "publish grades" status to "already published"', () => {
      setPublishGradesStatus(AssignmentActions.GRADES_ALREADY_PUBLISHED)
      equal(getPublishGradesStatus(), 'GRADES_ALREADY_PUBLISHED')
    })

    test('optionally sets the "publish grades" status to "not all selected"', () => {
      setPublishGradesStatus(AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE)
      equal(getPublishGradesStatus(), 'NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE')
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
