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
import {Provider} from 'react-redux'
import * as GradeActions from '../../grades/GradeActions'
import * as StudentActions from '../../students/StudentActions'
import Layout from '../Layout'
import configureStore from '../../configureStore'

describe('GradeSummary Layout', () => {
  let store
  let storeEnv
  let wrapper

  beforeEach(() => {
    storeEnv = {
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment',
      },
      currentUser: {
        canViewStudentIdentities: true,
        graderId: 'admin',
        id: '1100',
      },
      finalGrader: {
        canViewStudentIdentities: true,
        graderId: 'teach',
        id: '1105',
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'},
      ],
    }

    window.ENV = {
      GRADERS: [
        {grader_name: 'Miss Frizzle', id: '4502', user_id: '1101', grader_selectable: true},
        {grader_name: 'Mr. Keating', id: '4503', user_id: '1102', grader_selectable: true},
      ],
    }

    jest.mock('../../students/StudentActions', () => ({
      loadStudents: jest.fn().mockImplementation(() => {
        return {
          type: 'SET_LOAD_STUDENTS_STATUS',
          payload: 'STARTED',
        }
      }),
      setLoadStudentsStatus: jest.fn(),
      STARTED: 'STARTED',
    }))

    jest.mock('../../grades/GradeActions', () => ({
      selectFinalGrade: jest.fn().mockImplementation(gradeInfo => ({
        type: 'SET_SELECTED_PROVISIONAL_GRADE',
        payload: gradeInfo,
      })),
      setSelectedProvisionalGrade: jest.fn(),
    }))
  })

  afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    wrapper = render(
      <Provider store={store}>
        <Layout />
      </Provider>
    )
  }

  test('includes the Header', () => {
    mountComponent()
    expect(wrapper.container.querySelector('Header')).toBeInTheDocument()
  })

  test('loads students upon mounting', () => {
    mountComponent()
    waitFor(() => {
      expect(StudentActions.loadStudents()).toHaveBeenCalledTimes(1)
    })
  })

  describe('when students have not yet loaded', () => {
    test('displays a spinner', () => {
      mountComponent()
      expect(screen.getByRole('img', {name: /students are loading/i})).toBeInTheDocument()
    })
  })

  describe('when some students have loaded', () => {
    let students
    beforeEach(() => {
      students = [
        {id: '1111', displayName: 'Adam Jones'},
        {id: '1112', displayName: 'Betty Ford'},
      ]
    })

    test('renders the GradesGrid', () => {
      mountComponent()
      console.log(111)
      act(() => {
        store.dispatch(StudentActions.addStudents(students))
      })
      console.log(222)
      expect(screen.getByTestId('grades-grid')).toBeInTheDocument()
    })

    test('does not display a spinner', () => {
      mountComponent()
      act(() => {
        store.dispatch(StudentActions.addStudents(students))
      })
      expect(screen.queryByRole('img', {name: /students are loading/i})).toBeNull()
    })
  })

  describe.skip('GradesGrid', () => {
    let grades

    function mountAndInitialize() {
      mountComponent()
      const students = [
        {id: '1111', displayName: 'Adam Jones'},
        {id: '1112', displayName: 'Betty Ford'},
      ]
      act(() => {
        store.dispatch(StudentActions.addStudents(students))
      })
      grades = [
        {grade: 'A', graderId: '1101', id: '1101', score: 10, selected: false, studentId: '1111'},
      ]
      act(() => {
        store.dispatch(GradeActions.addProvisionalGrades(grades))
      })
    }

    test('receives the final grader id from the assignment', () => {
      mountAndInitialize()
      strictEqual(wrapper.find('GradesGrid').prop('finalGrader'), storeEnv.finalGrader)
    })

    test('receives the selectProvisionalGradeStatuses from state', () => {
      mountAndInitialize()
      const statuses = wrapper.find('GradesGrid').prop('selectProvisionalGradeStatuses')
      strictEqual(statuses, store.getState().grades.selectProvisionalGradeStatuses)
    })

    describe.skip('when grades have not been released', () => {
      test('onGradeSelect prop selects a provisional grade', () => {
        mountAndInitialize()
        const onGradeSelect = wrapper.find('GradesGrid').prop('onGradeSelect')
        onGradeSelect(grades[0])
        const gradeInfo = store.getState().grades.provisionalGrades[1111][1101]
        strictEqual(gradeInfo.selected, true)
      })

      test('allows editing custom grades when the current user is the final grader', () => {
        storeEnv.currentUser = {...storeEnv.finalGrader}
        mountAndInitialize()
        const gradesGrid = wrapper.find('GradesGrid')
        strictEqual(gradesGrid.prop('disabledCustomGrade'), false)
      })

      test('prevents editing custom grades when the current user is not the final grader', () => {
        mountAndInitialize()
        const gradesGrid = wrapper.find('GradesGrid')
        strictEqual(gradesGrid.prop('disabledCustomGrade'), true)
      })

      test('prevents editing custom grades when there is no final grader', () => {
        storeEnv.finalGrader = null
        mountAndInitialize()
        const gradesGrid = wrapper.find('GradesGrid')
        strictEqual(gradesGrid.prop('disabledCustomGrade'), true)
      })
    })

    describe.skip('when grades have been released', () => {
      beforeEach(() => {
        storeEnv.assignment.gradesPublished = true
      })

      test('onGradeSelect prop is null when grades have been released', () => {
        mountAndInitialize()
        const onGradeSelect = wrapper.find('GradesGrid').prop('onGradeSelect')
        strictEqual(onGradeSelect, null)
      })

      test('prevents editing custom grades when the current user is the final grader', () => {
        storeEnv.currentUser = {...storeEnv.finalGrader}
        mountAndInitialize()
        const gradesGrid = wrapper.find('GradesGrid')
        strictEqual(gradesGrid.prop('disabledCustomGrade'), true)
      })

      test('prevents editing custom grades when the current user is not the final grader', () => {
        mountAndInitialize()
        const gradesGrid = wrapper.find('GradesGrid')
        strictEqual(gradesGrid.prop('disabledCustomGrade'), true)
      })
    })
  })
})
