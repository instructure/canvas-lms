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

import {
  FAILURE,
  STARTED,
  SUCCESS,
  addStudents,
  setLoadStudentsStatus,
} from 'ui/features/assignment_grade_summary/react/students/StudentActions'
import configureStore from 'ui/features/assignment_grade_summary/react/configureStore'

QUnit.module('GradeSummary studentsReducer()', suiteHooks => {
  let store
  let students

  suiteHooks.beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        id: '2301',
        title: 'Example Assignment',
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}],
    })

    students = [
      {id: '1111', displayName: 'Adam Jones'},
      {id: '1112', displayName: 'Betty Ford'},
      {id: '1113', displayName: 'Charlie Xi'},
      {id: '1114', displayName: 'Dana Young'},
    ]
  })

  QUnit.module('when handling "ADD_STUDENTS"', () => {
    test('adds students to the store', () => {
      store.dispatch(addStudents(students))
      const storedStudents = store.getState().students.list
      deepEqual(storedStudents, students)
    })

    test('appends students to the end of the current list of students', () => {
      store.dispatch(addStudents(students.slice(0, 2)))
      store.dispatch(addStudents(students.slice(2)))
      const storedStudents = store.getState().students.list
      deepEqual(storedStudents, students)
    })

    test('preserves the order of students as they are added', () => {
      store.dispatch(addStudents(students.slice(2)))
      store.dispatch(addStudents(students.slice(0, 2)))
      const storedStudents = store.getState().students.list
      deepEqual(
        storedStudents.map(student => student.id),
        ['1113', '1114', '1111', '1112']
      )
    })
  })

  QUnit.module('when handling "SET_LOAD_STUDENTS_STATUS"', () => {
    function getLoadStudentsStatus() {
      return store.getState().students.loadStudentsStatus
    }

    test('optionally sets the "load students" status to "failure"', () => {
      store.dispatch(setLoadStudentsStatus(FAILURE))
      equal(getLoadStudentsStatus(), FAILURE)
    })

    test('optionally sets the "load students" status to "started"', () => {
      store.dispatch(setLoadStudentsStatus(STARTED))
      equal(getLoadStudentsStatus(), STARTED)
    })

    test('optionally sets the "load students" status to "success"', () => {
      store.dispatch(setLoadStudentsStatus(SUCCESS))
      equal(getLoadStudentsStatus(), SUCCESS)
    })
  })
})
