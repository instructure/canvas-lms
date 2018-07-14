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

import * as StudentsApi from 'jsx/assignments/GradeSummary/students/StudentsApi'
import FakeServer, {paramsFromRequest, pathFromRequest} from 'jsx/__tests__/FakeServer'

QUnit.module('GradeSummary StudentsApi', suiteHooks => {
  let qunitTimeout
  let server

  suiteHooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 500 // avoid accidental unresolved async
    server = new FakeServer()
  })

  suiteHooks.afterEach(() => {
    server.teardown()
    QUnit.config.testTimeout = qunitTimeout
  })

  QUnit.module('.loadStudents()', hooks => {
    const url = '/api/v1/courses/1201/assignments/2301/gradeable_students'

    let loadedProvisionalGrades
    let loadedStudents
    let provisionalGradesData
    let studentsData

    hooks.beforeEach(() => {
      provisionalGradesData = [
        {
          grade: 'A',
          provisional_grade_id: '4601',
          score: 10,
          scorer_id: '1101'
        },
        {
          grade: 'B',
          provisional_grade_id: '4602',
          score: 9,
          scorer_id: '1102'
        },
        {
          grade: 'C',
          provisional_grade_id: '4603',
          score: 8,
          scorer_id: '1101'
        },
        {
          grade: 'B-',
          provisional_grade_id: '4604',
          score: 8.9,
          scorer_id: '1102'
        }
      ]

      studentsData = [
        {display_name: 'Adam Jones', id: '1111', provisional_grades: [provisionalGradesData[0]]},
        {
          display_name: 'Betty Ford',
          id: '1112',
          provisional_grades: provisionalGradesData.slice(1, 3),
          selected_provisional_grade_id: '4603'
        },
        {display_name: 'Charlie Xi', id: '1113', provisional_grades: []},
        {display_name: 'Dana Smith', id: '1114', provisional_grades: [provisionalGradesData[3]]}
      ]

      server
        .for(url)
        .respond([
          {status: 200, body: [studentsData[0]]},
          {status: 200, body: [studentsData[1]]},
          {status: 200, body: studentsData.slice(2)}
        ])

      loadedProvisionalGrades = []
      loadedStudents = []
    })

    async function loadStudents() {
      let resolvePromise
      let rejectPromise

      const promise = new Promise((resolve, reject) => {
        resolvePromise = resolve
        rejectPromise = reject
      })

      StudentsApi.loadStudents('1201', '2301', {
        onAllPagesLoaded: resolvePromise,
        onFailure: rejectPromise,
        onPageLoaded({provisionalGrades, students}) {
          loadedProvisionalGrades.push(provisionalGrades)
          loadedStudents.push(students)
        }
      })

      await promise
    }

    function flatten(nestedArrays) {
      return [].concat(...nestedArrays)
    }

    function sortBy(array, key) {
      return [].concat(array).sort((a, b) => {
        if (a[key] === b[key]) {
          return 0
        }
        return a[key] < b[key] ? -1 : 1
      })
    }

    test('sends a request for students', async () => {
      await loadStudents()
      const request = server.receivedRequests[0]
      equal(pathFromRequest(request), '/api/v1/courses/1201/assignments/2301/gradeable_students')
    })

    test('includes provisional grades', async () => {
      await loadStudents()
      const request = server.receivedRequests[0]
      deepEqual(paramsFromRequest(request).include, ['provisional_grades'])
    })

    test('includes allow_new_anonymous_id', async () => {
      await loadStudents()
      const request = server.receivedRequests[0]
      equal(paramsFromRequest(request).allow_new_anonymous_id, 'true')
    })

    test('requests 50 students per page', async () => {
      await loadStudents()
      const request = server.receivedRequests[0]
      strictEqual(paramsFromRequest(request).per_page, '50')
    })

    test('sends additional requests while additional pages are available', async () => {
      await loadStudents()
      strictEqual(server.receivedRequests.length, 3)
    })

    test('calls onPageLoaded for each successful request', async () => {
      await loadStudents()
      strictEqual(loadedStudents.length, 3)
    })

    test('includes students when calling onPageLoaded', async () => {
      await loadStudents()
      const studentCountPerPage = loadedStudents.map(pageStudents => pageStudents.length)
      deepEqual(studentCountPerPage, [1, 1, 2])
    })

    test('normalizes student names', async () => {
      await loadStudents()
      const names = flatten(loadedStudents).map(student => student.displayName)
      deepEqual(names.sort(), ['Adam Jones', 'Betty Ford', 'Charlie Xi', 'Dana Smith'])
    })

    test('includes ids on students', async () => {
      await loadStudents()
      const ids = flatten(loadedStudents).map(student => student.id)
      deepEqual(ids.sort(), ['1111', '1112', '1113', '1114'])
    })

    test('uses anonymous ids for ids when students are anonymous', async () => {
      for (let i = 0; i < studentsData.length; i++) {
        delete studentsData[i].id
        studentsData[i].anonymous_id = `abcd${i + 1}`
      }
      await loadStudents()
      const ids = flatten(loadedStudents).map(student => student.id)
      deepEqual(ids.sort(), ['abcd1', 'abcd2', 'abcd3', 'abcd4'])
    })

    test('sets student names to null when anonymous', async () => {
      for (let i = 0; i < studentsData.length; i++) {
        delete studentsData[i].display_name
      }
      await loadStudents()
      const names = flatten(loadedStudents).map(student => student.displayName)
      deepEqual(names, [null, null, null, null])
    })

    test('includes provisional grades when calling onPageLoaded', async () => {
      await loadStudents()
      const gradeCountPerPage = loadedProvisionalGrades.map(pageGrades => pageGrades.length)
      deepEqual(gradeCountPerPage, [1, 2, 1])
    })

    test('normalizes provisional grade grader ids', async () => {
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.graderId), ['1101', '1102', '1101', '1102'])
    })

    test('uses anonymous grader id for provisional grades when graders are anonymous', async () => {
      for (let i = 0; i < provisionalGradesData.length; i++) {
        delete provisionalGradesData[i].scorer_id
        provisionalGradesData[i].anonymous_grader_id = `abcd${i + 1}`
      }
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.graderId), ['abcd1', 'abcd2', 'abcd3', 'abcd4'])
    })

    test('includes provisional grade ids', async () => {
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.grade), ['A', 'B', 'C', 'B-'])
    })

    test('includes provisional grade grades', async () => {
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.grade), ['A', 'B', 'C', 'B-'])
    })

    test('includes provisional grade scores', async () => {
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.score), [10, 9, 8, 8.9])
    })

    test('sets selection state on provisional grades', async () => {
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.selected), [false, false, true, false])
    })

    test('includes associated student id', async () => {
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.studentId), ['1111', '1112', '1112', '1114'])
    })

    test('uses anonymous id for associated students when anonymous', async () => {
      for (let i = 0; i < studentsData.length; i++) {
        delete studentsData[i].id
        studentsData[i].anonymous_id = `abcd${i + 1}`
      }
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      deepEqual(grades.map(grade => grade.studentId), ['abcd1', 'abcd2', 'abcd2', 'abcd4'])
    })

    test('calls onFailure when a request fails', async () => {
      server.unsetResponses(url)
      server
        .for(url)
        .respond([
          {status: 200, body: [studentsData[0]]},
          {status: 500, body: {error: 'server error'}}
        ])

      try {
        await loadStudents()
      } catch (e) {
        ok(e.message.includes('500'))
      }
    })

    test('does not send additional requests when one fails', async () => {
      server.unsetResponses(url)
      server
        .for(url)
        .respond([
          {status: 200, body: [studentsData[0]]},
          {status: 500, body: {error: 'server error'}}
        ])

      try {
        await loadStudents()
      } catch (e) {
        strictEqual(server.receivedRequests.length, 2)
      }
    })
  })
})
