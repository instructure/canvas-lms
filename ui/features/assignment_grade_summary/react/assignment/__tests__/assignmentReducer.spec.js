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

import * as AssignmentActions from '../AssignmentActions'
import configureStore from '../../configureStore'

describe('GradeSummary assignmentReducer()', () => {
  let store

  beforeEach(() => {
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

  describe('when handling "UPDATE_ASSIGNMENT"', () => {
    test('updates the assignment in the store', () => {
      store.dispatch(AssignmentActions.updateAssignment({gradesPublished: true}))
      expect(getAssignment().gradesPublished).toBe(true)
    })

    test('replaces the instance of the assignment', () => {
      const assignment = getAssignment()
      store.dispatch(AssignmentActions.updateAssignment({gradesPublished: true}))
      expect(getAssignment()).not.toBe(assignment)
    })
  })

  describe('when handling "SET_RELEASE_GRADES_STATUS"', () => {
    function setReleaseGradesStatus(status) {
      store.dispatch(AssignmentActions.setReleaseGradesStatus(status))
    }

    function getReleaseGradesStatus() {
      return store.getState().assignment.releaseGradesStatus
    }

    test('optionally sets the "release grades" status to "failure"', () => {
      setReleaseGradesStatus(AssignmentActions.FAILURE)
      expect(getReleaseGradesStatus()).toBe('FAILURE')
    })

    test('optionally sets the "release grades" status to "started"', () => {
      setReleaseGradesStatus(AssignmentActions.STARTED)
      expect(getReleaseGradesStatus()).toBe('STARTED')
    })

    test('optionally sets the "release grades" status to "success"', () => {
      setReleaseGradesStatus(AssignmentActions.SUCCESS)
      expect(getReleaseGradesStatus()).toBe('SUCCESS')
    })

    test('optionally sets the "release grades" status to "already released"', () => {
      setReleaseGradesStatus(AssignmentActions.GRADES_ALREADY_RELEASED)
      expect(getReleaseGradesStatus()).toBe('GRADES_ALREADY_RELEASED')
    })

    test('optionally sets the "release grades" status to "not all selected"', () => {
      setReleaseGradesStatus(AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE)
      expect(getReleaseGradesStatus()).toBe('NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE')
    })

    test('optionally sets the "release grades" status to "selected grades from unavailable graders"', () => {
      setReleaseGradesStatus(AssignmentActions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS)
      expect(getReleaseGradesStatus()).toBe('SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS')
    })
  })

  describe('when handling "SET_UNMUTE_ASSIGNMENT_STATUS"', () => {
    function setUnmuteAssignmentStatus(status) {
      store.dispatch(AssignmentActions.setUnmuteAssignmentStatus(status))
    }

    function getUnmuteAssignmentStatus() {
      return store.getState().assignment.unmuteAssignmentStatus
    }

    test('optionally sets the "unmute assignment" status to "failure"', () => {
      setUnmuteAssignmentStatus(AssignmentActions.FAILURE)
      expect(getUnmuteAssignmentStatus()).toBe('FAILURE')
    })

    test('optionally sets the "unmute assignment" status to "started"', () => {
      setUnmuteAssignmentStatus(AssignmentActions.STARTED)
      expect(getUnmuteAssignmentStatus()).toBe('STARTED')
    })

    test('optionally sets the "unmute assignment" status to "success"', () => {
      setUnmuteAssignmentStatus(AssignmentActions.SUCCESS)
      expect(getUnmuteAssignmentStatus()).toBe('SUCCESS')
    })
  })
})
