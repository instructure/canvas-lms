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
})
