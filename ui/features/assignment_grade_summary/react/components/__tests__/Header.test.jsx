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

import React from 'react'
import {render, act, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Provider} from 'react-redux'

import * as StudentActions from '../../students/StudentActions'
import * as GradeActions from '../../grades/GradeActions'
import * as AssignmentActions from '../../assignment/AssignmentActions'

import Header from '../Header'
import configureStore from '../../configureStore'

describe('GradeSummary Header', () => {
  let students
  let grades
  let store
  let storeEnv
  let wrapper

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
    window.ENV = {
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
    }
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
    wrapper = render(
      <Provider store={store}>
        <Header />
      </Provider>
    )
  }

  function mountAndInitialize() {
    mountComponent()
    act(() => {
      store.dispatch(StudentActions.addStudents(students))
    })
    act(() => {
      store.dispatch(GradeActions.addProvisionalGrades(grades))
    })
  }

  test('includes the "Grade Summary" heading', () => {
    mountComponent()
    expect(wrapper.container.querySelector('h1').textContent).toBe('Grade Summary')
  })

  test('includes the assignment title', () => {
    mountComponent()
    const children = wrapper.container.querySelector('header').children
    const childArray = [...children].map(child => child)
    const headingIndex = childArray.findIndex(child => child.textContent === 'Grade Summary')
    expect(childArray[headingIndex + 1].textContent).toBe('Example Assignment')
  })

  test('includes a "grader with inactive enrollments" message when a grader with inactive enrollment was selected', () => {
    mountComponent()
    act(() => {
      store.dispatch(
        AssignmentActions.setReleaseGradesStatus(
          AssignmentActions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS
        )
      )
    })
    expect(screen.getByText('grader with inactive enrollments', {exact: false})).toBeInTheDocument()
  })

  test('includes a "grades released" message when grades have been released', () => {
    storeEnv.assignment.gradesPublished = true
    mountComponent()
    expect(screen.getByText('they have already been released', {exact: false})).toBeInTheDocument()
  })

  test('excludes the "grades released" message when grades have not yet been released', () => {
    mountComponent()
    expect(screen.queryByText('they have already been released', {exact: false})).toBeNull()
  })

  describe('Graders Table', () => {
    test('is not displayed when there are no graders', () => {
      storeEnv.graders = []
      mountComponent()
      expect(screen.queryByTestId('graders-table')).toBeNull()
    })

    test('is displayed when there are graders', () => {
      mountComponent()
      expect(screen.getByTestId('graders-table')).toBeInTheDocument()
    })
  })

  describe('"Release Grades" button', () => {
    beforeEach(() => {
      window.confirm = () => true
      jest.mock('../../assignment/AssignmentActions', () => ({
        releaseGrades: jest.fn().mockImplementation(() => ({
          type: 'SET_RELEASE_GRADES_STATUS',
          payload: 'STARTED',
        })),
        setReleaseGradesStatus: jest.fn(),
        STARTED: 'STARTED',
      }))
    })

    test('is always displayed', () => {
      storeEnv.graders = []
      mountComponent()
      expect(screen.getByRole('button', {name: /release grades/i})).toBeInTheDocument()
    })

    test.skip('receives the assignment gradesPublished property as a prop', () => {
      mountComponent()
      strictEqual(wrapper.find('ReleaseButton').prop('gradesReleased'), false)
    })

    test('receives the unmuteAssignmentStatus as a prop', () => {
      mountComponent()
      act(() => {
        store.dispatch(AssignmentActions.setReleaseGradesStatus(AssignmentActions.STARTED))
      })
      expect(screen.getByRole('button', {name: /releasing grades/i})).toBeInTheDocument()
    })

    test('displays a confirmation dialog when clicked', async () => {
      const user = userEvent.setup({delay: null})
      mountComponent()
      await user.click(screen.getByRole('button', {name: /release grades/i}))
      waitFor(() => {
        expect(window.confirm.callCount).toBe(1)
      })
    })

    test('releases grades when dialog is confirmed', async () => {
      const user = userEvent.setup({delay: null})
      mountComponent()
      await user.click(screen.getByRole('button', {name: /release grades/i}))
      waitFor(() => {
        expect(store.getState().assignment.releaseGradesStatus).toBe(AssignmentActions.STARTED)
      })
    })

    test('does not release grades when dialog is dismissed', async () => {
      window.confirm = () => false
      //   window.confirm.returns(false)
      const user = userEvent.setup({delay: null})

      mountComponent()
      await user.click(screen.getByRole('button', {name: /release grades/i}))
      waitFor(() => {
        expect(store.getState().assignment.releaseGradesStatus).toBe(null)
      })
    })

    test('enables onClick when there are no grades', async () => {
      grades = []
      mountAndInitialize()
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton.disabled).toBe(false)
    })

    test('enables button when there are no grades selected', () => {
      grades.forEach(grade => (grade.selected = false))
      mountAndInitialize()
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton.disabled).toBe(false)
    })

    test('disables onClick when there is at least one grade with a not selectable grader', () => {
      grades[0].selected = false
      grades[1].selected = true
      mountAndInitialize()
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton.disabled).toBe(true)
    })

    test('enables onClick when all the grades have a selectable grader', () => {
      mountAndInitialize()
      const releaseButton = screen.getByRole('button', {name: /release grades/i})
      expect(releaseButton.disabled).toBe(false)
    })
  })

  describe('"Post to Students" button', () => {
    beforeEach(() => {
      storeEnv.assignment.gradesPublished = true
      window.confirm = () => true
      jest.mock('../../assignment/AssignmentActions', () => ({
        releaseGrades: jest.fn().mockImplementation(() => ({
          type: 'SET_RELEASE_GRADES_STATUS',
          payload: 'STARTED',
        })),
        setReleaseGradesStatus: jest.fn(),
        STARTED: 'STARTED',
      }))
    })

    test('is always displayed', () => {
      storeEnv.graders = []
      mountComponent()
      expect(screen.getByRole('button', {name: /post to students/i})).toBeInTheDocument()
    })

    test.skip('receives the assignment as a prop', () => {
      mountComponent()
      const button = wrapper.find('PostToStudentsButton')
      deepEqual(button.prop('assignment'), storeEnv.assignment)
    })

    test('receives the unmuteAssignmentStatus as a prop', () => {
      mountComponent()
      act(() => {
        store.dispatch(AssignmentActions.setUnmuteAssignmentStatus(AssignmentActions.STARTED))
      })
      expect(screen.getByRole('button', {name: /posting to students/i})).toBeInTheDocument()
    })

    test('displays a confirmation dialog when clicked', async () => {
      const user = userEvent.setup({delay: null})
      mountComponent()
      await user.click(screen.getByRole('button', {name: /post to students/i}))
      waitFor(() => {
        expect(window.confirm.callCount).toBe(1)
      })
    })

    test('unmutes the assignment when dialog is confirmed', async () => {
      const user = userEvent.setup({delay: null})
      mountComponent()
      await user.click(screen.getByRole('button', {name: /post to students/i}))
      waitFor(() => {
        expect(store.getState().assignment.unmuteAssignmentStatus).toBe(AssignmentActions.STARTED)
      })
    })

    test('does not unmute the assignment when dialog is dismissed', async () => {
      window.confirm = () => false
      const user = userEvent.setup({delay: null})

      mountComponent()
      await user.click(screen.getByRole('button', {name: /post to students/i}))
      waitFor(() => {
        expect(store.getState().assignment.unmuteAssignmentStatus).toBe(null)
      })
    })
  })
})
