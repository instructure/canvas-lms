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
import Layout from 'jsx/assignments/GradeSummary/components/Layout'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

QUnit.module('GradeSummary Layout', suiteHooks => {
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
        graderId: 'admin',
        id: '1100'
      },
      finalGrader: {
        graderId: 'teach',
        id: '1105'
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ]
    }

    sinon
      .stub(StudentActions, 'loadStudents')
      .returns(StudentActions.setLoadStudentsStatus(StudentActions.STARTED))
    sinon
      .stub(GradeActions, 'selectFinalGrade')
      .callsFake(gradeInfo => GradeActions.setSelectedProvisionalGrade(gradeInfo))
  })

  suiteHooks.afterEach(() => {
    GradeActions.selectFinalGrade.restore()
    StudentActions.loadStudents.restore()
    wrapper.unmount()
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    wrapper = mount(
      <Provider store={store}>
        <Layout />
      </Provider>
    )
  }

  test('includes the Header', () => {
    mountComponent()
    strictEqual(wrapper.find('Header').length, 1)
  })

  test('loads students upon mounting', () => {
    mountComponent()
    strictEqual(StudentActions.loadStudents.callCount, 1)
  })

  test('does not load students when there are not graders', () => {
    storeEnv.graders = []
    mountComponent()
    strictEqual(StudentActions.loadStudents.callCount, 0)
  })

  QUnit.module('when students have not yet loaded', () => {
    test('displays a spinner', () => {
      mountComponent()
      strictEqual(wrapper.find('Spinner').length, 1)
    })
  })

  QUnit.module('when some students have loaded', hooks => {
    let students

    hooks.beforeEach(() => {
      students = [{id: '1111', displayName: 'Adam Jones'}, {id: '1112', displayName: 'Betty Ford'}]
    })

    test('renders the GradesGrid', () => {
      mountComponent()
      store.dispatch(StudentActions.addStudents(students))
      strictEqual(wrapper.find('GradesGrid').length, 1)
    })

    test('does not display a spinner', () => {
      mountComponent()
      store.dispatch(StudentActions.addStudents(students))
      strictEqual(wrapper.find('Spinner').length, 0)
    })
  })

  QUnit.module('GradesGrid', () => {
    let grades

    function mountAndInitialize() {
      mountComponent()
      const students = [
        {id: '1111', displayName: 'Adam Jones'},
        {id: '1112', displayName: 'Betty Ford'}
      ]
      store.dispatch(StudentActions.addStudents(students))
      grades = [
        {grade: 'A', graderId: '1101', id: '4601', score: 10, selected: false, studentId: '1111'}
      ]
      store.dispatch(GradeActions.addProvisionalGrades(grades))
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

    QUnit.module('when grades have not been published', () => {
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

    QUnit.module('when grades have been published', contextHooks => {
      contextHooks.beforeEach(() => {
        storeEnv.assignment.gradesPublished = true
      })

      test('onGradeSelect prop is null when grades have been published', () => {
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
