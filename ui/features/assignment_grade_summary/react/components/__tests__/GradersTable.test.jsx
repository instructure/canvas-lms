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
import {render, act} from '@testing-library/react'
import {Provider} from 'react-redux'

import * as GradeActions from '../../grades/GradeActions'
import * as StudentActions from '../../students/StudentActions'
import GradersTable from '../GradersTable/index'
import configureStore from '../../configureStore'

describe('GradeSummary GradersTable', () => {
  let provisionalGrades
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
        graderId: 'teach',
        id: '1105',
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'},
        {graderId: '1103', graderName: 'Mrs. Krabappel'},
        {graderId: '1104', graderName: 'Mr. Feeny'},
      ],
    }

    provisionalGrades = [
      {
        grade: 'A',
        graderId: '1101',
        id: '4601',
        score: 9.5,
        selected: false,
        studentId: '1111',
      },
      {
        grade: 'B',
        graderId: '1102',
        id: '4602',
        score: 8.4,
        selected: false,
        studentId: '1112',
      },
      {
        grade: 'C',
        graderId: '1103',
        id: '4603',
        score: 7.6,
        selected: false,
        studentId: '1113',
      },
      {
        grade: 'B+',
        graderId: '1104',
        id: '4604',
        score: 8.9,
        selected: false,
        studentId: '1114',
      },
    ]
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    wrapper = render(
      <Provider store={store}>
        <GradersTable />
      </Provider>
    )
  }

  function mountAndFinishLoading() {
    mountComponent()

    act(() => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
    })
    act(() => {
      store.dispatch(StudentActions.setLoadStudentsStatus(StudentActions.SUCCESS))
    })
  }

  function getGraderRow(graderId) {
    const {graderName} = storeEnv.graders.find(grader => grader.graderId === graderId)
    const rows = [...wrapper.container.querySelectorAll('.grader-label')].filter(row =>
      row.textContent.includes(graderName)
    )[0]
    return rows
  }

  function getAcceptGradesColumnHeader() {
    return [...wrapper.container.querySelectorAll('div')].find(el =>
      el.textContent.includes('Accept Grades')
    )
  }

  test('includes a row for each grader', () => {
    mountComponent()
    expect(wrapper.container.querySelectorAll('.grader-label').length).toBe(4)
  })

  test('displays grader names in the row headers', () => {
    mountComponent()
    const rowHeaders = wrapper.container.querySelectorAll('.grader-label')
    expect([...rowHeaders].map(header => header.textContent)).toEqual(
      storeEnv.graders.map(grader => grader.graderName)
    )
  })

  describe('"Accept Grades" column', hooks => {
    beforeEach(() => {
      mountComponent()
    })

    test('is not displayed when grades have not started loading', () => {
      expect(getAcceptGradesColumnHeader()).toBeUndefined()
    })

    test('is not displayed when grades have started loading', () => {
      act(() => {
        store.dispatch(StudentActions.setLoadStudentsStatus(StudentActions.STARTED))
      })
      expect(getAcceptGradesColumnHeader()).toBeUndefined()
    })

    test('is not displayed when not all provisional grades have loaded', () => {
      act(() => {
        store.dispatch(StudentActions.setLoadStudentsStatus(StudentActions.STARTED))
      })
      act(() => {
        store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      })
      expect(getAcceptGradesColumnHeader()).toBeUndefined()
    })

    test('is displayed when grades have finished loading and at least one grader can be bulk-selected', () => {
      mountAndFinishLoading()
      expect(getAcceptGradesColumnHeader()).toBeInTheDocument()
    })

    test('is not displayed when grades have finished loading and no graders can be bulk-selected', () => {
      provisionalGrades.forEach(grade => {
        grade.studentId = '1111'
      })
      mountAndFinishLoading()
      expect(getAcceptGradesColumnHeader()).toBeUndefined()
    })

    test('is displayed when grades have finished loading and all students have a selected grade', () => {
      provisionalGrades.forEach(grade => {
        grade.selected = true
      })
      mountAndFinishLoading()
      expect(getAcceptGradesColumnHeader()).toBeInTheDocument()
    })
  })

  describe.skip('"Accept Grades" button', () => {
    function getGraderAcceptGradesButton(graderId) {
      return getGraderRow(graderId).find('AcceptGradesButton')
    }

    test('receives the "accept grades" status for the related grader', () => {
      mountAndFinishLoading()
      act(() => {
        store.dispatch(
          GradeActions.setBulkSelectProvisionalGradesStatus('1101', GradeActions.STARTED)
        )
      })
      const button = getGraderAcceptGradesButton('1101')
      equal(button.prop('acceptGradesStatus'), GradeActions.STARTED)
    })

    test('accepts grades for the related grader when clicked', () => {
      sandbox
        .stub(GradeActions, 'acceptGraderGrades')
        .callsFake(graderId =>
          GradeActions.setBulkSelectProvisionalGradesStatus(graderId, GradeActions.STARTED)
        )
      mountAndFinishLoading()
      const button = getGraderAcceptGradesButton('1101')
      button.prop('onClick')()
      equal(store.getState().grades.bulkSelectProvisionalGradeStatuses[1101], GradeActions.STARTED)
    })

    test('receives the grade selection details for the related grader', () => {
      mountAndFinishLoading()
      const button = getGraderAcceptGradesButton('1103')
      deepEqual(button.prop('selectionDetails').provisionalGradeIds, ['4603'])
    })
  })
})
