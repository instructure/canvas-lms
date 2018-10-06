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

import React from 'react'
import {mount} from 'enzyme'
import {Provider} from 'react-redux'

import * as GradeActions from 'jsx/assignments/GradeSummary/grades/GradeActions'
import * as StudentActions from 'jsx/assignments/GradeSummary/students/StudentActions'
import GradersTable from 'jsx/assignments/GradeSummary/components/GradersTable'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

QUnit.module('GradeSummary GradersTable', suiteHooks => {
  let provisionalGrades
  let store
  let storeEnv
  let wrapper

  suiteHooks.beforeEach(() => {
    storeEnv = {
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment'
      },
      currentUser: {
        graderId: 'teach',
        id: '1105'
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'},
        {graderId: '1103', graderName: 'Mrs. Krabappel'},
        {graderId: '1104', graderName: 'Mr. Feeny'}
      ]
    }

    provisionalGrades = [
      {
        grade: 'A',
        graderId: '1101',
        id: '4601',
        score: 9.5,
        selected: false,
        studentId: '1111'
      },
      {
        grade: 'B',
        graderId: '1102',
        id: '4602',
        score: 8.4,
        selected: false,
        studentId: '1112'
      },
      {
        grade: 'C',
        graderId: '1103',
        id: '4603',
        score: 7.6,
        selected: false,
        studentId: '1113'
      },
      {
        grade: 'B+',
        graderId: '1104',
        id: '4604',
        score: 8.9,
        selected: false,
        studentId: '1114'
      }
    ]
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    wrapper = mount(
      <Provider store={store}>
        <GradersTable />
      </Provider>
    )
  }

  function mountAndFinishLoading() {
    mountComponent()
    store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
    store.dispatch(StudentActions.setLoadStudentsStatus(StudentActions.SUCCESS))
    wrapper.update()
  }

  function getGraderRow(graderId) {
    const {graderName} = storeEnv.graders.find(grader => grader.graderId === graderId)
    const rows = wrapper
      .find('tbody tr')
      .filterWhere(row => row.find('th').text() === graderName)
    return rows.at(0)
  }

  test('renders a table', () => {
    mountComponent()
    strictEqual(wrapper.find('table').length, 1)
  })

  test('includes a row for each grader', () => {
    mountComponent()
    strictEqual(wrapper.find('tbody tr th').length, 4)
  })

  test('displays grader names in the row headers', () => {
    mountComponent()
    const rowHeaders = wrapper.find('tbody tr th')
    deepEqual(
      rowHeaders.map(header => header.text()),
      storeEnv.graders.map(grader => grader.graderName)
    )
  })

  QUnit.module('"Accept Grades" column', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
    })

    test('is not displayed when grades have not started loading', () => {
      const columnHeaders = wrapper.find('thead tr th')
      strictEqual(columnHeaders.filterWhere(header => header.text() === 'Accept Grades').length, 0)
    })

    test('is not displayed when grades have started loading', () => {
      store.dispatch(StudentActions.setLoadStudentsStatus(StudentActions.STARTED))
      const columnHeaders = wrapper.find('thead tr th')
      strictEqual(columnHeaders.filterWhere(header => header.text() === 'Accept Grades').length, 0)
    })

    test('is not displayed when not all provisional grades have loaded', () => {
      store.dispatch(StudentActions.setLoadStudentsStatus(StudentActions.STARTED))
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      const columnHeaders = wrapper.find('thead tr th')
      strictEqual(columnHeaders.filterWhere(header => header.text() === 'Accept Grades').length, 0)
    })

    test('is displayed when grades have finished loading and at least one grader can be bulk-selected', () => {
      mountAndFinishLoading()
      const columnHeaders = wrapper.find('thead tr th')
      strictEqual(columnHeaders.filterWhere(header => header.text() === 'Accept Grades').length, 1)
    })

    test('is not displayed when grades have finished loading and no graders can be bulk-selected', () => {
      provisionalGrades.forEach(grade => {
        grade.studentId = '1111' // eslint-disable-line no-param-reassign
      })
      mountAndFinishLoading()
      const columnHeaders = wrapper.find('thead tr th')
      strictEqual(columnHeaders.filterWhere(header => header.text() === 'Accept Grades').length, 0)
    })

    test('is displayed when grades have finished loading and all students have a selected grade', () => {
      provisionalGrades.forEach(grade => {
        grade.selected = true // eslint-disable-line no-param-reassign
      })
      mountAndFinishLoading()
      const columnHeaders = wrapper.find('thead tr th')
      strictEqual(columnHeaders.filterWhere(header => header.text() === 'Accept Grades').length, 1)
    })
  })

  QUnit.module('"Accept Grades" button', () => {
    function getGraderAcceptGradesButton(graderId) {
      return getGraderRow(graderId).find('AcceptGradesButton')
    }

    test('receives the "accept grades" status for the related grader', () => {
      mountAndFinishLoading()
      store.dispatch(
        GradeActions.setBulkSelectProvisionalGradesStatus('1101', GradeActions.STARTED)
      )
      wrapper.update()
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
