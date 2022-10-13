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

import * as StudentActions from 'ui/features/assignment_grade_summary/react/students/StudentActions'
import * as StudentsApi from 'ui/features/assignment_grade_summary/react/students/StudentsApi'
import configureStore from 'ui/features/assignment_grade_summary/react/configureStore'

QUnit.module('GradeSummary StudentActions', suiteHooks => {
  let store

  suiteHooks.beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        id: '2301',
        title: 'Example Assignment',
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}],
    })
  })

  QUnit.module('.loadStudents()', hooks => {
    let args
    let provisionalGrades
    let students

    hooks.beforeEach(() => {
      sinon.stub(StudentsApi, 'loadStudents').callsFake((courseId, assignmentId, callbacks) => {
        args = {courseId, assignmentId, callbacks}
      })

      provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          studentId: '1111',
        },
        {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 9,
          studentId: '1112',
        },
      ]

      students = [
        {id: '1111', displayName: 'Adam Jones'},
        {id: '1112', displayName: 'Betty Ford'},
      ]
    })

    hooks.afterEach(() => {
      args = null
      StudentsApi.loadStudents.restore()
    })

    test('sets the "load students" status to "started"', () => {
      store.dispatch(StudentActions.loadStudents())
      const {loadStudentsStatus} = store.getState().students
      equal(loadStudentsStatus, StudentActions.STARTED)
    })

    test('loads students through the api', () => {
      store.dispatch(StudentActions.loadStudents())
      strictEqual(StudentsApi.loadStudents.callCount, 1)
    })

    test('includes the course id when loading students through the api', () => {
      store.dispatch(StudentActions.loadStudents())
      strictEqual(args.courseId, '1201')
    })

    test('includes the assignment id when loading students through the api', () => {
      store.dispatch(StudentActions.loadStudents())
      strictEqual(args.assignmentId, '2301')
    })

    test('adds students to the store when a page of students is loaded', () => {
      store.dispatch(StudentActions.loadStudents())
      args.callbacks.onPageLoaded({provisionalGrades, students})
      const storedStudents = store.getState().students.list
      deepEqual(storedStudents, students)
    })

    test('adds provisional grades to the store when a page of students is loaded', () => {
      store.dispatch(StudentActions.loadStudents())
      args.callbacks.onPageLoaded({provisionalGrades, students})
      const grades = store.getState().grades.provisionalGrades
      deepEqual(grades[1112][1102], provisionalGrades[1])
    })

    test('sets the "load students" status to "success" when all pages have loaded', () => {
      store.dispatch(StudentActions.loadStudents())
      args.callbacks.onAllPagesLoaded()
      const {loadStudentsStatus} = store.getState().students
      equal(loadStudentsStatus, StudentActions.SUCCESS)
    })

    test('sets the "load students" status to "failure" when a failure occurs', () => {
      store.dispatch(StudentActions.loadStudents())
      args.callbacks.onFailure()
      const {loadStudentsStatus} = store.getState().students
      equal(loadStudentsStatus, StudentActions.FAILURE)
    })
  })
})
