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

import sinon from 'sinon'

import FakeServer, {paramsFromRequest} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {RequestDispatch} from '@canvas/network'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper.js'
import * as FinalGradeOverrideApi from '@canvas/grading/FinalGradeOverrideApi'
import StudentContentDataLoader from 'ui/features/gradebook/react/default_gradebook/DataLoader/StudentContentDataLoader.js'
import PerformanceControls from 'ui/features/gradebook/react/default_gradebook/PerformanceControls.js'

QUnit.module('Gradebook > DataLoader > StudentContentDataLoader', suiteHooks => {
  const exampleData = {
    finalGradeOverrides: {
      1101: {
        courseGrade: {
          percentage: 91.23
        }
      }
    },

    studentIds: ['1101', '1102', '1103'],
    students: [{id: '1101'}, {id: '1102'}, {id: '1103'}],
    submissions: [{id: '2501'}, {id: '2502'}, {id: '2503'}]
  }

  const urls = {
    students: '/api/v1/courses/1201/users',
    submissions: '/api/v1/courses/1201/students/submissions'
  }

  let dispatch
  let gradebook
  let performanceControls
  let server

  function latchPromise() {
    const latch = {}
    latch.promise = new Promise(resolve => {
      latch.resolve = () => {
        resolve()
      }
    })
    return latch
  }

  suiteHooks.beforeEach(() => {
    server = new FakeServer()

    server
      .for(urls.students, {user_ids: exampleData.studentIds.slice(0, 2)})
      .respond({status: 200, body: exampleData.students.slice(0, 2)})
    server
      .for(urls.students, {user_ids: exampleData.studentIds.slice(2, 3)})
      .respond({status: 200, body: exampleData.students.slice(2, 3)})

    server
      .for(urls.submissions, {student_ids: exampleData.studentIds.slice(0, 2)})
      .respond([{status: 200, body: exampleData.submissions.slice(0, 1)}])
    server
      .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
      .respond([{status: 200, body: exampleData.submissions.slice(1, 3)}])

    sandbox
      .stub(FinalGradeOverrideApi, 'getFinalGradeOverrides')
      .returns(Promise.resolve({finalGradeOverrides: exampleData.finalGradeOverrides}))

    gradebook = createGradebook({
      context_id: '1201',

      course_settings: {
        allow_final_grade_override: true,
        filter_speed_grader_by_student_group: false
      },

      final_grade_override_enabled: true
    })

    sinon.stub(gradebook, 'gotChunkOfStudents')
    sinon.stub(gradebook, 'gotSubmissionsChunk')
    sinon.stub(gradebook, 'updateStudentsLoaded')
    sinon.stub(gradebook, 'updateSubmissionsLoaded')
    sinon.stub(gradebook.finalGradeOverrides, 'setGrades')

    dispatch = new RequestDispatch()
    performanceControls = new PerformanceControls({
      studentsChunkSize: 2,
      submissionsChunkSize: 2
    })
  })

  suiteHooks.afterEach(() => {
    server.teardown()
  })

  QUnit.module('.load()', () => {
    async function load(studentIds) {
      const dataLoader = new StudentContentDataLoader({dispatch, gradebook, performanceControls})
      await dataLoader.load(studentIds || exampleData.studentIds)
    }

    QUnit.module('loading students', contextHooks => {
      contextHooks.beforeEach(() => {
        server.unsetResponses(urls.students)
      })

      function setStudentsResponse(ids, students) {
        server.for(urls.students, {user_ids: ids}).respond({status: 200, body: students})
      }

      test('requests students using the given student ids', async () => {
        setStudentsResponse(exampleData.studentIds, exampleData.students)
        performanceControls = new PerformanceControls({
          studentsChunkSize: 50,
          submissionsChunkSize: 2
        })
        await load()
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        deepEqual(params.user_ids, exampleData.studentIds)
      })

      test('chunks students when per page limit is less than count of student ids', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await load()
        const requests = server.filterRequests(urls.students)
        strictEqual(requests.length, 2)
      })

      test('updates the gradebook with each chunk of loaded students', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await load()
        strictEqual(gradebook.gotChunkOfStudents.callCount, 2)
      })

      test('includes loaded students when updating the gradebook', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        const loadedStudents = []
        gradebook.gotChunkOfStudents = students => {
          loadedStudents.push(...students)
        }
        await load()
        deepEqual(loadedStudents, exampleData.students)
      })

      QUnit.module('when no students needed to be loaded', () => {
        test('does not request students', async () => {
          await load([])
          const requests = server.filterRequests(urls.students)
          strictEqual(requests.length, 0)
        })

        test('does not request submissions', async () => {
          await load([])
          const requests = server.filterRequests(urls.submissions)
          strictEqual(requests.length, 0)
        })

        test('updates the "students loaded" status', async () => {
          await load([])
          strictEqual(gradebook.updateStudentsLoaded.callCount, 1)
        })

        test('sets the students as loaded', async () => {
          await load([])
          const [loaded] = gradebook.updateStudentsLoaded.lastCall.args
          strictEqual(loaded, true)
        })

        test('updates the "submissions loaded" status', async () => {
          await load([])
          strictEqual(gradebook.updateSubmissionsLoaded.callCount, 1)
        })

        test('sets the submissions as loaded', async () => {
          await load([])
          const [loaded] = gradebook.updateSubmissionsLoaded.lastCall.args
          strictEqual(loaded, true)
        })
      })
    })

    QUnit.module('loading submissions', () => {
      test('requests submissions for each page of students', async () => {
        await load()
        const requests = server.filterRequests(urls.submissions)
        strictEqual(requests.length, 2)
      })

      test('includes "points_deducted" in response fields', async () => {
        await load()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        ok(params.response_fields.includes('points_deducted'))
      })

      test('includes "cached_due_date" in response fields', async () => {
        await load()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        ok(params.response_fields.includes('cached_due_date'))
      })

      test('includes "posted_at" in response fields', async () => {
        await load()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        ok(params.response_fields.includes('posted_at'))
      })

      test('sets the `per_page` parameter to the configured per page maximum', async () => {
        performanceControls = new PerformanceControls({
          studentsChunkSize: 2,
          submissionsPerPage: 45
        })
        await load()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        strictEqual(params.per_page, '45')
      })

      test('updates the gradebook with each chunk of submissions', async () => {
        const submissionChunks = []
        gradebook.gotSubmissionsChunk = submissionChunks.push.bind(submissionChunks)
        await load()
        strictEqual(submissionChunks.length, 2)
      })

      test('includes the loaded submissions when updating the gradebook', async () => {
        const submissionChunks = []
        gradebook.gotSubmissionsChunk = submissionChunks.push.bind(submissionChunks)
        await load()
        deepEqual(submissionChunks, [
          exampleData.submissions.slice(0, 1),
          exampleData.submissions.slice(1, 3)
        ])
      })

      test('does not call submissions chunk callback until related student callback is called', async () => {
        const submissionChunks = []
        gradebook.gotSubmissionsChunk = submissionChunks.push.bind(submissionChunks)
        await load()
        const requests = server.filterRequests(urls.submissions)
        strictEqual(requests.length, 2)
      })

      test('does not request submissions when given an empty list of student ids', async () => {
        await load([])
        const requests = server.filterRequests(urls.submissions)
        strictEqual(requests.length, 0)
      })
    })

    QUnit.module('loading final grade overrides', () => {
      test('optionally requests final grade overrides', async () => {
        await load()
        strictEqual(FinalGradeOverrideApi.getFinalGradeOverrides.callCount, 1)
      })

      test('optionally does not request final grade overrides', async () => {
        gradebook.courseSettings.setAllowFinalGradeOverride(false)
        await load()
        strictEqual(FinalGradeOverrideApi.getFinalGradeOverrides.callCount, 0)
      })

      test('uses the given course id when loading final grade overrides', async () => {
        await load()
        const [courseId] = FinalGradeOverrideApi.getFinalGradeOverrides.lastCall.args
        strictEqual(courseId, '1201')
      })

      test('updates Gradebook when the final grade overrides have loaded', async () => {
        await load()
        strictEqual(gradebook.finalGradeOverrides.setGrades.callCount, 1)
      })

      test('updates Gradebook with the loaded final grade overrides', async () => {
        await load()
        const [finalGradeOverrides] = gradebook.finalGradeOverrides.setGrades.lastCall.args
        deepEqual(finalGradeOverrides, exampleData.finalGradeOverrides)
      })
    })

    QUnit.module('when submissions return before related students', contextHooks => {
      let events

      function joinIds(records) {
        return records.map(record => record.id).join(',')
      }

      function joinRequestIds(request, param) {
        return paramsFromRequest(request)[param].join(',')
      }

      function eventLogger(eventName) {
        return records => {
          events.push(`${eventName}:${joinIds(records)}`)
        }
      }

      contextHooks.beforeEach(() => {
        const submissionPromises = [latchPromise(), latchPromise()]
        events = []

        gradebook.gotChunkOfStudents = eventLogger('gotChunkOfStudents')
        gradebook.gotSubmissionsChunk = eventLogger('gotSubmissionsChunk')

        server.unsetResponses(urls.students)
        server.unsetResponses(urls.submissions)

        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(0, 2)})
          .beforeRespond(async request => {
            events.push(`request students:${joinRequestIds(request, 'user_ids')}`)
            await submissionPromises[0].promise
          })
          .respond({status: 200, body: exampleData.students.slice(0, 2)})
        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(2, 3)})
          .beforeRespond(async request => {
            events.push(`request students:${joinRequestIds(request, 'user_ids')}`)
            await submissionPromises[1].promise
          })
          .respond({status: 200, body: exampleData.students.slice(2, 3)})

        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(0, 2)})
          .beforeRespond(request => {
            events.push(`request submissions:${joinRequestIds(request, 'student_ids')}`)
          })
          .afterRespond(submissionPromises[0].resolve)
          .respond([{status: 200, body: exampleData.submissions.slice(0, 1)}])
        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
          .beforeRespond(request => {
            events.push(`request submissions:${joinRequestIds(request, 'student_ids')}`)
          })
          .afterRespond(submissionPromises[1].resolve)
          .respond([{status: 200, body: exampleData.submissions.slice(1, 3)}])
      })

      test('requests submissions before additional chunks of students', async () => {
        await load()
        const submissionRequest1Index = events.indexOf('request submissions:1101,1102')
        const studentRequest2Index = events.indexOf('request students:1103')
        ok(submissionRequest1Index < studentRequest2Index)
      })

      test('requests submissions before related students have returned', async () => {
        await load()
        const submissionRequest1Index = events.indexOf('request submissions:1101,1102')
        const studentChunkIndex = events.indexOf('gotChunkOfStudents:1101,1102')
        ok(submissionRequest1Index < studentChunkIndex)
      })

      test('calls student callback before submission callback on first load', async () => {
        await load()
        const studentChunkIndex = events.indexOf('gotChunkOfStudents:1101,1102')
        const submissionChunkIndex = events.indexOf('gotSubmissionsChunk:2501')
        ok(studentChunkIndex < submissionChunkIndex)
      })

      test('calls student callback before submission callback on subsequent loads', async () => {
        await load()
        const studentChunkIndex = events.indexOf('gotChunkOfStudents:1103')
        const submissionChunkIndex = events.indexOf('gotSubmissionsChunk:2502,2503')
        ok(studentChunkIndex < submissionChunkIndex)
      })
    })

    QUnit.module('when a submission request returns multiple pages', contextHooks => {
      let events

      function joinIds(records) {
        return records.map(record => record.id).join(',')
      }

      function joinRequestIds(request, param) {
        return paramsFromRequest(request)[param].join(',')
      }

      function getPage(request) {
        return paramsFromRequest(request).page || 1
      }

      function eventLogger(eventName) {
        return records => {
          events.push(`${eventName}:${joinIds(records)}`)
        }
      }

      contextHooks.beforeEach(() => {
        const submissionPromises = [latchPromise(), latchPromise()]
        events = []

        gradebook.gotChunkOfStudents = eventLogger('gotChunkOfStudents')
        gradebook.gotSubmissionsChunk = eventLogger('gotSubmissionsChunk')

        server.unsetResponses(urls.students)
        server.unsetResponses(urls.submissions)

        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(0, 2)})
          .beforeRespond(async request => {
            events.push(`request students:${joinRequestIds(request, 'user_ids')}`)
            await submissionPromises[0].promise
          })
          .respond({status: 200, body: exampleData.students.slice(0, 2)})
        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(2, 3)})
          .beforeRespond(async request => {
            events.push(`request students:${joinRequestIds(request, 'user_ids')}`)
            await submissionPromises[1].promise
          })
          .respond({status: 200, body: exampleData.students.slice(2, 3)})

        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(0, 2)})
          .beforeRespond(request => {
            events.push(`request submissions page ${getPage(request)}`)
          })
          .afterRespond(submissionPromises[0].resolve)
          .respond([
            {status: 200, body: exampleData.submissions.slice(0, 1)},
            {status: 200, body: exampleData.submissions.slice(1, 2)},
            {status: 200, body: exampleData.submissions.slice(2, 3)}
          ])
        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
          .beforeRespond(request => {
            events.push(`request submissions:${joinRequestIds(request, 'student_ids')}`)
          })
          .afterRespond(submissionPromises[1].resolve)
          .respond([{status: 200, body: []}])
      })

      test('requests all pages of submissions before additional chunks of students', async () => {
        await load()
        const submissionRequestIndices = [
          events.indexOf('request submissions page 1'),
          events.indexOf('request submissions page 2'),
          events.indexOf('request submissions page 3')
        ]
        const studentRequest2Index = events.indexOf('request students:1103')
        ok(Math.max(...submissionRequestIndices) < studentRequest2Index)
      })
    })

    QUnit.module('when all students have finished loading', loadingHooks => {
      loadingHooks.beforeEach(() => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
      })

      function setStudentsResponse(ids, students) {
        server.for(urls.students, {user_ids: ids}).respond({status: 200, body: students})
      }

      test('updates the "students loaded" status', async () => {
        await load()
        strictEqual(gradebook.updateStudentsLoaded.callCount, 1)
      })

      test('sets the students as loaded', async () => {
        await load()
        const [loaded] = gradebook.updateStudentsLoaded.lastCall.args
        strictEqual(loaded, true)
      })

      test('updates the status after storing loaded students', async () => {
        gradebook.updateStudentsLoaded.callsFake(() => {
          strictEqual(gradebook.gotChunkOfStudents.callCount, 2)
        })
        await load()
      })
    })

    QUnit.module('when all submissions have finished loading', () => {
      test('updates the "submissions loaded" status', async () => {
        await load()
        strictEqual(gradebook.updateSubmissionsLoaded.callCount, 1)
      })

      test('sets the submissions as loaded', async () => {
        await load()
        const [loaded] = gradebook.updateSubmissionsLoaded.lastCall.args
        strictEqual(loaded, true)
      })

      test('updates the status after storing loaded submissions', async () => {
        gradebook.updateSubmissionsLoaded.callsFake(() => {
          strictEqual(gradebook.gotSubmissionsChunk.callCount, 2)
        })
        await load()
      })
    })

    QUnit.module('when a student request fails', contextHooks => {
      contextHooks.beforeEach(() => {
        server.unsetResponses(urls.students)
        server.unsetResponses(urls.submissions)

        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(0, 2)})
          .respond({status: 500, body: exampleData.students.slice(0, 2)})
        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(2, 3)})
          .respond({status: 200, body: exampleData.students.slice(2, 3)})

        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(0, 2)})
          .respond([{status: 200, body: exampleData.submissions.slice(0, 1)}])
        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
          .respond([{status: 200, body: exampleData.submissions.slice(1, 3)}])

        sandbox.stub(FlashAlert, 'showFlashAlert')
      })

      test('does not call gotChunkOfStudents for the failed students', async () => {
        const loadedStudents = []
        gradebook.gotChunkOfStudents = students => {
          loadedStudents.push(...students)
        }
        await load()
        deepEqual(loadedStudents, exampleData.students.slice(2, 3))
      })

      test('does not call gotSubmissionsChunk for related submissions', async () => {
        const loadedSubmissions = []
        gradebook.gotSubmissionsChunk = submissions => {
          loadedSubmissions.push(...submissions)
        }
        await load()
        deepEqual(loadedSubmissions, exampleData.submissions.slice(1, 3))
      })

      test('shows a flash alert', async () => {
        await load()
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('flashes an error', async () => {
        await load()
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })
    })

    QUnit.module('when an initial submission request fails', contextHooks => {
      contextHooks.beforeEach(() => {
        server.unsetResponses(urls.students)
        server.unsetResponses(urls.submissions)

        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(0, 2)})
          .respond({status: 200, body: exampleData.students.slice(0, 2)})
        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(2, 3)})
          .respond({status: 200, body: exampleData.students.slice(2, 3)})

        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(0, 2)})
          .respond([{status: 500, body: exampleData.submissions.slice(0, 1)}])
        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
          .respond([{status: 200, body: exampleData.submissions.slice(1, 3)}])

        sandbox.stub(FlashAlert, 'showFlashAlert')
      })

      test('calls gotChunkOfStudents for related students', async () => {
        const loadedStudents = []
        gradebook.gotChunkOfStudents = students => {
          loadedStudents.push(...students)
        }
        await load()
        deepEqual(loadedStudents, exampleData.students)
      })

      test('does not call gotSubmissionsChunk for the failed submissions', async () => {
        const loadedSubmissions = []
        gradebook.gotSubmissionsChunk = submissions => {
          loadedSubmissions.push(...submissions)
        }
        await load()
        deepEqual(loadedSubmissions, exampleData.submissions.slice(1, 3))
      })

      test('shows a flash alert', async () => {
        await load()
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('flashes an error', async () => {
        await load()
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })
    })

    QUnit.module('when a subsequent submission page request fails', contextHooks => {
      contextHooks.beforeEach(() => {
        server.unsetResponses(urls.students)
        server.unsetResponses(urls.submissions)

        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(0, 2)})
          .respond({status: 200, body: exampleData.students.slice(0, 2)})
        server
          .for(urls.students, {user_ids: exampleData.studentIds.slice(2, 3)})
          .respond({status: 200, body: exampleData.students.slice(2, 3)})

        server.for(urls.submissions, {student_ids: exampleData.studentIds.slice(0, 2)}).respond([
          {status: 200, body: exampleData.submissions.slice(0, 1)},
          {status: 500, body: exampleData.submissions.slice(1, 2)}
        ])
        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
          .respond([{status: 200, body: exampleData.submissions.slice(2, 3)}])

        sandbox.stub(FlashAlert, 'showFlashAlert')
      })

      test('calls gotChunkOfStudents for related students', async () => {
        const loadedStudents = []
        gradebook.gotChunkOfStudents = students => {
          loadedStudents.push(...students)
        }
        await load()
        deepEqual(loadedStudents, exampleData.students)
      })

      test('does not call gotSubmissionsChunk for the failed submissions', async () => {
        const loadedSubmissions = []
        gradebook.gotSubmissionsChunk = submissions => {
          loadedSubmissions.push(...submissions)
        }
        await load()
        deepEqual(loadedSubmissions, exampleData.submissions.slice(2, 3))
      })

      test('shows a flash alert', async () => {
        await load()
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('flashes an error', async () => {
        await load()
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })
    })
  })
})
