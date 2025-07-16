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

import * as StudentsApi from '../StudentsApi'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('GradeSummary StudentsApi', () => {
  const server = setupServer()
  let capturedRequests = []

  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    capturedRequests = []
  })
  afterAll(() => server.close())

  describe('.loadStudents()', () => {
    const url = '/api/v1/courses/1201/assignments/2301/gradeable_students'

    let loadedProvisionalGrades
    let loadedStudents
    let provisionalGradesData
    let studentsData

    beforeEach(() => {
      provisionalGradesData = [
        {
          grade: 'A',
          provisional_grade_id: '4601',
          score: 10,
          scorer_id: '1101',
        },
        {
          grade: 'B',
          provisional_grade_id: '4602',
          score: 9,
          scorer_id: '1102',
        },
        {
          grade: 'C',
          provisional_grade_id: '4603',
          score: 8,
          scorer_id: '1101',
        },
        {
          grade: 'B-',
          provisional_grade_id: '4604',
          score: 8.9,
          scorer_id: '1102',
        },
      ]

      studentsData = [
        {display_name: 'Adam Jones', id: '1111', provisional_grades: [provisionalGradesData[0]]},
        {
          display_name: 'Betty Ford',
          id: '1112',
          provisional_grades: provisionalGradesData.slice(1, 3),
          selected_provisional_grade_id: '4603',
        },
        {display_name: 'Charlie Xi', id: '1113', provisional_grades: []},
        {display_name: 'Dana Smith', id: '1114', provisional_grades: [provisionalGradesData[3]]},
      ]

      loadedProvisionalGrades = []
      loadedStudents = []
    })

    function setupPaginatedResponse() {
      let requestCount = 0
      server.use(
        http.get(url, async ({request}) => {
          const requestUrl = new URL(request.url)
          capturedRequests.push({
            url: request.url,
            method: request.method,
            searchParams: requestUrl.searchParams,
          })

          requestCount++
          if (requestCount === 1) {
            return new HttpResponse(JSON.stringify([studentsData[0]]), {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
                link: `<http://localhost${url}?page=2>; rel="next"`,
              },
            })
          } else if (requestCount === 2) {
            return new HttpResponse(JSON.stringify([studentsData[1]]), {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
                link: `<http://localhost${url}?page=3>; rel="next"`,
              },
            })
          } else {
            return new HttpResponse(JSON.stringify(studentsData.slice(2)), {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
              },
            })
          }
        }),
      )
    }

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
        },
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
      setupPaginatedResponse()
      await loadStudents()
      const request = capturedRequests[0]
      expect(new URL(request.url).pathname).toBe(
        '/api/v1/courses/1201/assignments/2301/gradeable_students',
      )
    })

    test('includes provisional grades', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const request = capturedRequests[0]
      expect(request.searchParams.getAll('include[]')).toEqual(['provisional_grades'])
    })

    test('includes allow_new_anonymous_id', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const request = capturedRequests[0]
      expect(request.searchParams.get('allow_new_anonymous_id')).toBe('true')
    })

    test('requests 50 students per page', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const request = capturedRequests[0]
      expect(request.searchParams.get('per_page')).toBe('50')
    })

    test('sends additional requests while additional pages are available', async () => {
      setupPaginatedResponse()
      await loadStudents()
      expect(capturedRequests).toHaveLength(3)
    })

    test('calls onPageLoaded for each successful request', async () => {
      setupPaginatedResponse()
      await loadStudents()
      expect(loadedStudents).toHaveLength(3)
    })

    test('includes students when calling onPageLoaded', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const studentCountPerPage = loadedStudents.map(pageStudents => pageStudents.length)
      expect(studentCountPerPage).toEqual([1, 1, 2])
    })

    test('normalizes student names', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const names = flatten(loadedStudents).map(student => student.displayName)
      expect(names.sort()).toEqual(['Adam Jones', 'Betty Ford', 'Charlie Xi', 'Dana Smith'])
    })

    test('includes ids on students', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const ids = flatten(loadedStudents).map(student => student.id)
      expect(ids.sort()).toEqual(['1111', '1112', '1113', '1114'])
    })

    test('uses anonymous ids for ids when students are anonymous', async () => {
      for (let i = 0; i < studentsData.length; i++) {
        delete studentsData[i].id
        studentsData[i].anonymous_id = `abcd${i + 1}`
      }
      setupPaginatedResponse()
      await loadStudents()
      const ids = flatten(loadedStudents).map(student => student.id)
      expect(ids.sort()).toEqual(['abcd1', 'abcd2', 'abcd3', 'abcd4'])
    })

    test('sets student names to null when anonymous', async () => {
      for (let i = 0; i < studentsData.length; i++) {
        delete studentsData[i].display_name
      }
      setupPaginatedResponse()
      await loadStudents()
      const names = flatten(loadedStudents).map(student => student.displayName)
      expect(names).toEqual([null, null, null, null])
    })

    test('includes provisional grades when calling onPageLoaded', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const gradeCountPerPage = loadedProvisionalGrades.map(pageGrades => pageGrades.length)
      expect(gradeCountPerPage).toEqual([1, 2, 1])
    })

    test('normalizes provisional grade grader ids', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.graderId)).toEqual(['1101', '1102', '1101', '1102'])
    })

    test('uses anonymous grader id for provisional grades when graders are anonymous', async () => {
      for (let i = 0; i < provisionalGradesData.length; i++) {
        delete provisionalGradesData[i].scorer_id
        provisionalGradesData[i].anonymous_grader_id = `abcd${i + 1}`
      }
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.graderId)).toEqual(['abcd1', 'abcd2', 'abcd3', 'abcd4'])
    })

    test('includes provisional grade ids', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.grade)).toEqual(['A', 'B', 'C', 'B-'])
    })

    test('includes provisional grade grades', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.grade)).toEqual(['A', 'B', 'C', 'B-'])
    })

    test('includes provisional grade scores', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.score)).toEqual([10, 9, 8, 8.9])
    })

    test('sets selection state on provisional grades', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.selected)).toEqual([false, false, true, false])
    })

    test('includes associated student id', async () => {
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.studentId)).toEqual(['1111', '1112', '1112', '1114'])
    })

    test('uses anonymous id for associated students when anonymous', async () => {
      for (let i = 0; i < studentsData.length; i++) {
        delete studentsData[i].id
        studentsData[i].anonymous_id = `abcd${i + 1}`
      }
      setupPaginatedResponse()
      await loadStudents()
      const grades = sortBy(flatten(loadedProvisionalGrades), 'id')
      expect(grades.map(grade => grade.studentId)).toEqual(['abcd1', 'abcd2', 'abcd2', 'abcd4'])
    })

    test('calls onFailure when a request fails', async () => {
      server.resetHandlers()
      let requestCount = 0
      server.use(
        http.get(url, () => {
          requestCount++
          if (requestCount === 1) {
            return new HttpResponse(JSON.stringify([studentsData[0]]), {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
                link: `<http://localhost${url}?page=2>; rel="next"`,
              },
            })
          } else {
            return HttpResponse.json({error: 'server error'}, {status: 500})
          }
        }),
      )

      try {
        await loadStudents()
      } catch (e) {
        expect(e.message).toMatch(/500/)
      }
    })

    test('does not send additional requests when one fails', async () => {
      server.resetHandlers()
      capturedRequests = []
      let requestCount = 0
      server.use(
        http.get(url, async ({request}) => {
          const requestUrl = new URL(request.url)
          capturedRequests.push({
            url: request.url,
            method: request.method,
            searchParams: requestUrl.searchParams,
          })
          requestCount++
          if (requestCount === 1) {
            return new HttpResponse(JSON.stringify([studentsData[0]]), {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
                link: `<http://localhost${url}?page=2>; rel="next"`,
              },
            })
          } else {
            return HttpResponse.json({error: 'server error'}, {status: 500})
          }
        }),
      )

      try {
        await loadStudents()
      } catch (e) {
        expect(capturedRequests).toHaveLength(2)
      }
    })
  })
})
