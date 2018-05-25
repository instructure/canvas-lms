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

import * as GradeActions from 'jsx/assignments/GradeSummary/grades/GradeActions'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

QUnit.module('GradeSummary gradesReducer()', suiteHooks => {
  let store
  let provisionalGrades

  suiteHooks.beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        id: '2301',
        title: 'Example Assignment'
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ]
    })

    provisionalGrades = [
      {
        grade: 'A',
        graderId: '1101',
        id: '4601',
        score: 10,
        selected: true,
        studentId: '1111'
      },
      {
        grade: 'B',
        graderId: '1102',
        id: '4602',
        score: 9,
        selected: false,
        studentId: '1112'
      },
      {
        grade: 'C',
        graderId: '1102',
        id: '4603',
        score: 8,
        selected: false,
        studentId: '1111'
      }
    ]
  })

  function getProvisionalGrades() {
    return store.getState().grades.provisionalGrades
  }

  QUnit.module('when handling "ADD_PROVISIONAL_GRADES"', () => {
    test('adds a key for each student among the provisional grades', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      deepEqual(Object.keys(getProvisionalGrades()).sort(), ['1111', '1112'])
    })

    test('adds a key to a student for each grader who graded that student', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      deepEqual(Object.keys(getProvisionalGrades()[1111]).sort(), ['1101', '1102'])
    })

    test('does not add a key to a student for a grader who has not graded that student', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      deepEqual(Object.keys(getProvisionalGrades()[1112]), ['1102'])
    })

    test('keys a grade to the grader id within the student map', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      deepEqual(getProvisionalGrades()[1112][1102], provisionalGrades[1])
    })
  })

  QUnit.module('when handling "SET_SELECTED_PROVISIONAL_GRADE"', hooks => {
    hooks.beforeEach(() => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
    })

    test('sets the given provisional grade as selected', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      strictEqual(getProvisionalGrades()[1111][1102].selected, true)
    })

    test('sets the previously-selected provisional grade as not selected', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      strictEqual(getProvisionalGrades()[1111][1101].selected, false)
    })

    test('replaces the instance of the given provisional grade', () => {
      const grade = getProvisionalGrades()[1111][1102]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(grade))
      notEqual(getProvisionalGrades()[1111][1102], grade)
    })

    test('replaces the instance of the de-selected provisional grade', () => {
      const grade = getProvisionalGrades()[1111][1101]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      notEqual(getProvisionalGrades()[1111][1101], grade)
    })

    test('does not replace instances of related grades not previously selected', () => {
      const grade = getProvisionalGrades()[1111][1101]
      grade.selected = false
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      strictEqual(getProvisionalGrades()[1111][1101], grade)
    })

    test('replaces the instance of student grades collection', () => {
      const grades = getProvisionalGrades()[1111]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      notEqual(getProvisionalGrades()[1111], grades)
    })

    test('does not replace instances of unrelated student grades collections', () => {
      const grades = getProvisionalGrades()[1112]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      strictEqual(getProvisionalGrades()[1112], grades)
    })

    test('replaces the provisional grades instance', () => {
      const grades = getProvisionalGrades()
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      notEqual(getProvisionalGrades(), grades)
    })
  })

  QUnit.module('when handling "SET_SELECT_PROVISIONAL_GRADE_STATUS"', () => {
    function setSelectProvisionalGradeStatus(gradeInfo, status) {
      store.dispatch(GradeActions.setSelectProvisionalGradeStatus(gradeInfo, status))
    }

    function getSelectProvisionalGradeStatus(studentId) {
      return store.getState().grades.selectProvisionalGradeStatuses[studentId]
    }

    test('optionally sets the "select provisional grade" status to "failure" for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.FAILURE)
      equal(getSelectProvisionalGradeStatus(1111), GradeActions.FAILURE)
    })

    test('optionally sets the "select provisional grade" status to "started" for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.STARTED)
      equal(getSelectProvisionalGradeStatus(1111), GradeActions.STARTED)
    })

    test('optionally sets the "select provisional grade" status to "success" for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.SUCCESS)
      equal(getSelectProvisionalGradeStatus(1111), GradeActions.SUCCESS)
    })

    test('replaces the previous status for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.STARTED)
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.SUCCESS)
      equal(getSelectProvisionalGradeStatus(1111), GradeActions.SUCCESS)
    })

    test('does not affect unrelated students', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[1], GradeActions.STARTED)
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.SUCCESS)
      equal(getSelectProvisionalGradeStatus(1112), GradeActions.STARTED)
    })
  })
})
