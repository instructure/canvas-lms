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

const getMockFirstArg = mock => mock.mock.calls[0][0]
const gradesGridMock = jest.fn(() => <div data-testid="grades-grid" />)

jest.mock('../GradesGrid', () => props => gradesGridMock(props))
jest.mock('../FlashMessageHolder', () => () => <div data-testid="flash-message-holder" />)
jest.mock('../Header', () => () => <div data-testid="header" />)
jest.mock('../../students/StudentActions', () => {
  const originalModule = jest.requireActual('../../students/StudentActions')

  return {
    ...originalModule,
    loadStudents: jest.fn().mockImplementation(() => {
      return {
        type: 'SET_LOAD_STUDENTS_STATUS',
        payload: 'STARTED',
      }
    }),
    setLoadStudentsStatus: jest.fn(),
    STARTED: 'STARTED',
  }
})
jest.mock('../../grades/GradeActions', () => {
  const originalModule = jest.requireActual('../../grades/GradeActions')

  return {
    ...originalModule,
    selectFinalGrade: jest.fn(gradeInfo => ({
      type: 'SET_SELECTED_PROVISIONAL_GRADE',
      payload: gradeInfo,
    })),
    setSelectedProvisionalGrade: jest.fn(),
  }
})

describe('GradeSummary Layout', () => {
  let store
  let storeEnv
  let wrapper

  const mountComponent = () => {
    store = configureStore(storeEnv)
    wrapper = render(
      <Provider store={store}>
        <Layout />
      </Provider>
    )
  }

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
        id: '1105',
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
      selectGrade: jest.fn(),
    }

    window.ENV = {
      GRADERS: [
        {grader_name: 'Miss Frizzle', id: '4502', user_id: '1101', grader_selectable: true},
        {grader_name: 'Mr. Keating', id: '4503', user_id: '1102', grader_selectable: true},
      ],
    }
  })

  afterEach(() => {
    wrapper.unmount()
    jest.clearAllMocks()
  })

  it('includes the Header', () => {
    mountComponent()

    expect(screen.getByTestId('header')).toBeInTheDocument()
  })

  it('includes the FlashMessageHolder', () => {
    mountComponent()

    expect(screen.getByTestId('flash-message-holder')).toBeInTheDocument()
  })

  it('loads students upon mounting', () => {
    mountComponent()
    waitFor(() => {
      expect(StudentActions.loadStudents()).toHaveBeenCalledTimes(1)
    })
  })

  describe('when students have not yet loaded', () => {
    it('displays a spinner', () => {
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

    it('renders the GradesGrid', () => {
      mountComponent()

      act(() => {
        store.dispatch(StudentActions.addStudents(students))
      })

      expect(screen.getByTestId('grades-grid')).toBeInTheDocument()
    })

    it('does not display a spinner', () => {
      mountComponent()

      act(() => {
        store.dispatch(StudentActions.addStudents(students))
      })

      expect(screen.queryByRole('img', {name: /students are loading/i})).toBeNull()
    })
  })

  describe('GradesGrid', () => {
    let grades

    const mountAndInitialize = () => {
      const students = [
        {id: '1111', displayName: 'Adam Jones'},
        {id: '1112', displayName: 'Betty Ford'},
      ]

      mountComponent()

      grades = [
        {grade: 'A', graderId: '1101', id: '1101', score: 10, selected: false, studentId: '1111'},
      ]

      act(() => {
        store.dispatch(StudentActions.addStudents(students))
        store.dispatch(GradeActions.addProvisionalGrades(grades))
      })
    }

    it('receives the final grader id from the assignment', () => {
      mountAndInitialize()

      expect(getMockFirstArg(gradesGridMock).finalGrader).toEqual(storeEnv.finalGrader)
    })

    it('receives the selectProvisionalGradeStatuses from state', () => {
      storeEnv.assignment.gradesPublished = true

      mountAndInitialize()

      expect(getMockFirstArg(gradesGridMock).disabledCustomGrade).toEqual(true)
    })

    describe('when grades have not been released', () => {
      it('onGradeSelect prop selects a provisional grade', () => {
        const gradeInfo = {
          gradeInfo: {
            id: '1101',
            studentId: '1111',
            selected: true,
          },
        }
        mountAndInitialize()

        getMockFirstArg(gradesGridMock).onGradeSelect(gradeInfo)

        expect(GradeActions.selectFinalGrade).toHaveBeenCalledWith(gradeInfo)
      })

      it('allows editing custom grades when the current user is the final grader', () => {
        storeEnv.currentUser = {...storeEnv.finalGrader}

        mountAndInitialize()

        expect(getMockFirstArg(gradesGridMock).disabledCustomGrade).toEqual(false)
      })

      it('prevents editing custom grades when the current user is not the final grader', () => {
        mountAndInitialize()

        expect(getMockFirstArg(gradesGridMock).disabledCustomGrade).toEqual(false)
      })

      it('prevents editing custom grades when there is no final grader', () => {
        storeEnv.finalGrader = null

        mountAndInitialize()

        expect(getMockFirstArg(gradesGridMock).disabledCustomGrade).toEqual(true)
      })
    })

    describe('when grades have been released', () => {
      beforeEach(() => {
        storeEnv.assignment.gradesPublished = true
      })

      it('onGradeSelect prop is null when grades have been released', () => {
        mountAndInitialize()

        expect(getMockFirstArg(gradesGridMock).onGradeSelect).toBeFalsy()
      })

      it('prevents editing custom grades when the current user is the final grader', () => {
        storeEnv.currentUser = {...storeEnv.finalGrader}

        mountAndInitialize()

        expect(getMockFirstArg(gradesGridMock).disabledCustomGrade).toEqual(true)
      })

      it('prevents editing custom grades when the current user is not the final grader', () => {
        mountAndInitialize()

        expect(getMockFirstArg(gradesGridMock).disabledCustomGrade).toEqual(true)
      })
    })
  })
})
