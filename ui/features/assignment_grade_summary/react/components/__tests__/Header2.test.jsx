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

// Mock the API module to prevent real network calls
vi.mock('../../assignment/AssignmentApi', () => ({
  releaseGrades: vi.fn().mockResolvedValue({}),
  unmuteAssignment: vi.fn().mockResolvedValue({}),
  speedGraderUrl: vi.fn().mockReturnValue('/speed_grader'),
}))

vi.mock('../../assignment/AssignmentActions', () => ({
  releaseGrades: vi.fn().mockImplementation(() => ({
    type: 'SET_RELEASE_GRADES_STATUS',
    payload: {status: 'STARTED'},
  })),
  setReleaseGradesStatus: vi.fn().mockImplementation(status => ({
    type: 'SET_RELEASE_GRADES_STATUS',
    payload: {status},
  })),
  unmuteAssignment: vi.fn().mockImplementation(() => ({
    type: 'SET_UNMUTE_ASSIGNMENT_STATUS',
    payload: {status: 'STARTED'},
  })),
  setUnmuteAssignmentStatus: vi.fn().mockImplementation(status => ({
    type: 'SET_UNMUTE_ASSIGNMENT_STATUS',
    payload: {status},
  })),
  updateAssignment: vi.fn().mockImplementation(assignment => ({
    type: 'UPDATE_ASSIGNMENT',
    payload: {assignment},
  })),
  STARTED: 'STARTED',
  SUCCESS: 'SUCCESS',
  FAILURE: 'FAILURE',
  GRADES_ALREADY_RELEASED: 'GRADES_ALREADY_RELEASED',
  NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE: 'NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE',
  SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS: 'SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS',
  SET_RELEASE_GRADES_STATUS: 'SET_RELEASE_GRADES_STATUS',
  UPDATE_ASSIGNMENT: 'UPDATE_ASSIGNMENT',
  SET_UNMUTE_ASSIGNMENT_STATUS: 'SET_UNMUTE_ASSIGNMENT_STATUS',
}))

import {vi} from 'vitest'
import React from 'react'
import {render, act, waitFor} from '@testing-library/react'
import {screen} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import {Provider} from 'react-redux'
import fakeENV from '@canvas/test-utils/fakeENV'
import {windowConfirm} from '@canvas/util/globalUtils'

import * as StudentActions from '../../students/StudentActions'
import * as GradeActions from '../../grades/GradeActions'
import * as AssignmentActions from '../../assignment/AssignmentActions'

import Header from '../Header'
import configureStore from '../../configureStore'

vi.mock('@canvas/util/globalUtils', () => ({
  windowConfirm: vi.fn(() => true),
}))

describe('GradeSummary Header', () => {
  let students
  let grades
  let store
  let storeEnv
  let _wrapper

  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
    fakeENV.teardown()
    document.body.innerHTML = ''
    vi.clearAllMocks()
  })

  beforeEach(() => {
    students = [
      {id: '1', displayName: 'Adam Jones'},
      {id: '2', displayName: 'Larry Brown'},
    ]
    grades = [
      {grade: '4', graderId: '1103', id: '34', score: 4, selected: true, studentId: '1'},
      {grade: '6', graderId: '1102', id: '35', score: 8, selected: false, studentId: '1'},
      {grade: '8', graderId: '1103', id: '36', score: 3, selected: true, studentId: '2'},
      {grade: '10', graderId: '1102', id: '37', score: 9, selected: false, studentId: '2'},
    ]
    fakeENV.setup({
      GRADERS: [
        {
          grader_name: 'Charlie Xi',
          id: '4502',
          user_id: '1103',
          grader_selectable: true,
          graderId: '4502',
        },
        {
          grader_name: 'Betty Ford',
          id: '4501',
          user_id: '1102',
          grader_selectable: false,
          graderId: '4501',
        },
      ],
    })
    storeEnv = {
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment',
      },
      currentUser: {
        graderId: 'teach',
        id: '1105',
      },
      graders: [
        {
          grader_name: 'Charlie Xi',
          id: '4502',
          user_id: '1103',
          grader_selectable: true,
          graderId: '4502',
        },
        {
          grader_name: 'Betty Ford',
          id: '4501',
          user_id: '1102',
          grader_selectable: false,
          graderId: '4501',
        },
      ],
    }
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    _wrapper = null
    render(
      <Provider store={store}>
        <Header />
      </Provider>,
    )
    return store
  }

  beforeEach(() => {
    windowConfirm.mockImplementation(() => true)
  })

  function mountAndInitialize() {
    mountComponent()
    act(() => {
      store.dispatch(StudentActions.addStudents(students))
    })
    act(() => {
      store.dispatch(GradeActions.addProvisionalGrades(grades))
    })
  }

  describe('"Release Grades" button', () => {
    beforeEach(() => {
      window.confirm = () => true
    })

    it('is always displayed', () => {
      storeEnv.graders = []
      mountComponent()
      expect(screen.getByRole('button', {name: /release grades/i})).toBeInTheDocument()
    })

    it('receives the assignment gradesPublished property as a prop', () => {
      storeEnv.assignment.gradesPublished = true

      mountComponent()

      expect(screen.queryByRole('button', {name: /grades released/i})).toBeInTheDocument()
    })

    // fickle
    it.skip('receives the releaseGradesStatus as a prop', () => {
      mountComponent()
      act(() => {
        store.dispatch(AssignmentActions.setReleaseGradesStatus(AssignmentActions.STARTED))
      })
      const button = screen.getByRole('button', {name: /release grades/i})
      expect(button).toHaveAttribute('aria-readonly', 'true')
    })

    it('displays a confirmation dialog when clicked', async () => {
      const user = userEvent.setup({delay: null})
      mountComponent()
      await user.click(screen.getByRole('button', {name: /release grades/i}))
      waitFor(() => {
        expect(windowConfirm).toHaveBeenCalledTimes(1)
      })
    })

    it.skip('releases grades when dialog is confirmed', async () => {
      const user = userEvent.setup({delay: null})
      windowConfirm.mockImplementation(() => true)
      mountComponent()
      await user.click(screen.getByRole('button', {name: /release grades/i}))
      vi.advanceTimersByTime(100)
      expect(vi.mocked(AssignmentActions.releaseGrades)).toHaveBeenCalled()
    })

    it('does not release grades when dialog is dismissed', async () => {
      windowConfirm.mockImplementation(() => false)
      const user = userEvent.setup({delay: null})

      mountComponent()
      await user.click(screen.getByRole('button', {name: /release grades/i}))
      waitFor(() => {
        expect(store.getState().assignment.releaseGradesStatus).toBe(null)
      })
    })

    it('enables onClick when there are no grades', async () => {
      grades = []
      mountAndInitialize()
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton.disabled).toBe(false)
    })

    it('enables button when there are no grades selected', () => {
      grades.forEach(grade => (grade.selected = false))
      mountAndInitialize()
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton.disabled).toBe(false)
    })

    // fickle
    it('disables onClick when there is at least one grade with a not selectable grader', () => {
      // Select a grade from a non-selectable grader (Betty Ford, id: 1102)
      grades[0].selected = false
      grades[1].selected = true // This grade is from Betty Ford who is not selectable
      grades[2].selected = false
      grades[3].selected = false
      mountAndInitialize()
      act(() => {
        store.dispatch(
          AssignmentActions.setReleaseGradesStatus(
            AssignmentActions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
          ),
        )
      })
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton).toHaveAttribute('aria-readonly', 'true')
    })

    it('enables onClick when all the grades have a selectable grader', () => {
      mountAndInitialize()
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton.disabled).toBe(false)
    })
  })

  describe('"Post to Students" button', () => {
    beforeEach(() => {
      storeEnv.assignment.gradesPublished = true
    })

    it('is always displayed', () => {
      storeEnv.graders = []
      mountComponent()
      expect(screen.getByRole('button', {name: /post to students/i})).toBeInTheDocument()
    })

    it('receives the assignment as a prop', () => {
      storeEnv.assignment.muted = false
      storeEnv.assignment.gradesPublished = false

      mountComponent()

      expect(screen.queryByRole('button', {name: /grades posted to students/i})).toBeDisabled()
    })

    it('receives the unmuteAssignmentStatus as a prop', () => {
      mountComponent()
      act(() => {
        store.dispatch(AssignmentActions.setUnmuteAssignmentStatus(AssignmentActions.STARTED))
      })
      expect(screen.getByRole('button', {name: /posting to students/i})).toBeInTheDocument()
    })

    it('displays a confirmation dialog when clicked', async () => {
      const user = userEvent.setup({delay: null})
      mountComponent()
      const button = screen.getByRole('button', {name: /post to students/i})
      await user.click(button)
      vi.advanceTimersByTime(100)
      expect(windowConfirm).toHaveBeenCalledTimes(1)
    })

    it.skip('unmutes the assignment when dialog is confirmed', async () => {
      const user = userEvent.setup({delay: null})
      windowConfirm.mockImplementation(() => true)
      mountComponent()
      await user.click(screen.getByRole('button', {name: /post to students/i}))
      vi.advanceTimersByTime(100)
      expect(vi.mocked(AssignmentActions.unmuteAssignment)).toHaveBeenCalled()
    })

    it.skip('does not unmute the assignment when dialog is dismissed', async () => {
      windowConfirm.mockImplementation(() => false)
      const user = userEvent.setup({delay: null})
      mountComponent()
      await user.click(screen.getByRole('button', {name: /post to students/i}))
      vi.advanceTimersByTime(100)
      expect(vi.mocked(AssignmentActions.unmuteAssignment)).not.toHaveBeenCalled()
    })
  })
})
