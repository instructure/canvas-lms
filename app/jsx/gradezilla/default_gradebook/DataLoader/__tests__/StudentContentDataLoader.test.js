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

import FakeServer, {paramsFromRequest} from '../../../../__tests__/FakeServer'
import * as FlashAlert from '../../../../shared/FlashAlert'
import * as FinalGradeOverrideApi from '../../FinalGradeOverrides/FinalGradeOverrideApi'
import FinalGradeOverrides from '../../FinalGradeOverrides'
import StudentContentDataLoader from '../StudentContentDataLoader'

describe('Gradebook StudentContentDataLoader', () => {
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
    students: '/students',
    submissions: '/submissions'
  }

  let dataLoader
  let gradebook
  let options
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

  beforeEach(() => {
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

    sinon
      .stub(FinalGradeOverrideApi, 'getFinalGradeOverrides')
      .returns(Promise.resolve({finalGradeOverrides: exampleData.finalGradeOverrides}))

    gradebook = {
      finalGradeOverrides: new FinalGradeOverrides({})
    }
    sinon.stub(gradebook.finalGradeOverrides, 'setGrades')

    options = {
      courseId: '1201',
      gradebook,
      onStudentsChunkLoaded() {},
      onSubmissionsChunkLoaded() {},
      studentsChunkSize: 2,
      studentsParams: {enrollment_state: ['active']},
      studentsUrl: urls.students,
      submissionsChunkSize: 2,
      submissionsUrl: urls.submissions
    }
  })

  afterEach(() => {
    FinalGradeOverrideApi.getFinalGradeOverrides.restore()
    server.teardown()
  })

  describe('.load()', () => {
    async function load(studentIds) {
      dataLoader = new StudentContentDataLoader(options)
      await dataLoader.load(studentIds || exampleData.studentIds)
    }

    describe('loading students', () => {
      beforeEach(() => {
        server.unsetResponses(urls.students)
      })

      function setStudentsResponse(ids, students) {
        server.for(urls.students, {user_ids: ids}).respond({status: 200, body: students})
      }

      function setSubmissionsResponse(ids, submissions) {
        server.unsetResponses(urls.submissions)
        server.for(urls.submissions, {student_ids: ids}).respond([{status: 200, body: submissions}])
      }

      it('requests students using the given student ids', async () => {
        setStudentsResponse(exampleData.studentIds, exampleData.students)
        options.studentsChunkSize = 50
        await load()
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        expect(params.user_ids).toEqual(exampleData.studentIds)
      })

      it('does not request students already loaded', async () => {
        setStudentsResponse(['1102'], [{id: '1102'}])
        setSubmissionsResponse(['1102'], [{id: '2502'}])
        options = {...options, loadedStudentIds: ['1101', '1103'], studentsChunkSize: 50}
        await load()
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        expect(params.user_ids).toEqual(['1102'])
      })

      it('chunks students when per page limit is less than count of student ids', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        options.studentsChunkSize = 2
        await load()
        const requests = server.filterRequests(urls.students)
        expect(requests).toHaveLength(2)
      })

      it('calls the students page callback when each students page request resolves', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        options.onStudentsChunkLoaded = sinon.spy()
        await load()
        expect(options.onStudentsChunkLoaded.callCount).toEqual(2)
      })

      it('includes loaded students with each callback', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        const loadedStudents = []
        options.onStudentsChunkLoaded = students => {
          loadedStudents.push(...students)
        }
        await load()
        expect(loadedStudents).toEqual(exampleData.students)
      })

      it('does not request students when given an empty list of student ids', async () => {
        await load([])
        const requests = server.filterRequests(urls.students)
        expect(requests).toHaveLength(0)
      })

      it('does not request students when requested student ids are already loaded', async () => {
        options = {...options, loadedStudentIds: exampleData.studentIds}
        await load(exampleData.studentIds)
        const requests = server.filterRequests(urls.students)
        expect(requests).toHaveLength(0)
      })
    })

    describe('loading submissions', () => {
      it('requests submissions for each page of students', async () => {
        await load()
        const requests = server.filterRequests(urls.submissions)
        expect(requests).toHaveLength(2)
      })

      it('includes "points_deducted" in response fields', async () => {
        await load()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        expect(params.response_fields).toContain('points_deducted')
      })

      it('includes "cached_due_date" in response fields', async () => {
        await load()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        expect(params.response_fields).toContain('cached_due_date')
      })

      it('calls the submissions chunk callback for each chunk of submissions', async () => {
        const submissionChunks = []
        options.onSubmissionsChunkLoaded = submissionChunks.push.bind(submissionChunks)
        await load()
        expect(submissionChunks).toHaveLength(2)
      })

      it('includes loaded submissions with each callback', async () => {
        const submissionChunks = []
        options.onSubmissionsChunkLoaded = submissionChunks.push.bind(submissionChunks)
        await load()
        expect(submissionChunks).toEqual([
          exampleData.submissions.slice(0, 1),
          exampleData.submissions.slice(1, 3)
        ])
      })

      it('does not call submissions chunk callback until related student callback is called', async () => {
        const submissionChunks = []
        options.onSubmissionsChunkLoaded = submissionChunks.push.bind(submissionChunks)
        await load()
        const requests = server.filterRequests(urls.submissions)
        expect(requests).toHaveLength(2)
      })

      it('does not request submissions when given an empty list of student ids', async () => {
        await load([])
        const requests = server.filterRequests(urls.submissions)
        expect(requests).toHaveLength(0)
      })

      it('does not request submissions when requested student ids are already loaded', async () => {
        options = {...options, loadedStudentIds: exampleData.studentIds}
        await load(exampleData.studentIds)
        const requests = server.filterRequests(urls.submissions)
        expect(requests).toHaveLength(0)
      })
    })

    describe('loading final grade overrides', () => {
      beforeEach(() => {
        options.getFinalGradeOverrides = true
      })

      it('optionally requests final grade overrides', async () => {
        await load()
        expect(FinalGradeOverrideApi.getFinalGradeOverrides.callCount).toEqual(1)
      })

      it('optionally does not request final grade overrides', async () => {
        options.getFinalGradeOverrides = false
        await load()
        expect(FinalGradeOverrideApi.getFinalGradeOverrides.callCount).toEqual(0)
      })

      it('uses the given course id when loading final grade overrides', async () => {
        await load()
        const [courseId] = FinalGradeOverrideApi.getFinalGradeOverrides.lastCall.args
        expect(courseId).toEqual('1201')
      })

      it('updates Gradebook when the final grade overrides have loaded', async () => {
        await load()
        expect(gradebook.finalGradeOverrides.setGrades.callCount).toEqual(1)
      })

      it('updates Gradebook with the loaded final grade overrides', async () => {
        await load()
        const [finalGradeOverrides] = gradebook.finalGradeOverrides.setGrades.lastCall.args
        expect(finalGradeOverrides).toEqual(exampleData.finalGradeOverrides)
      })
    })

    describe('when submissions return before related students', () => {
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

      beforeEach(() => {
        const submissionPromises = [latchPromise(), latchPromise()]
        events = []

        options.onStudentsChunkLoaded = eventLogger('onStudentsChunkLoaded')
        options.onSubmissionsChunkLoaded = eventLogger('onSubmissionsChunkLoaded')

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
          .beforeRespond(async request => {
            events.push(`request submissions:${joinRequestIds(request, 'student_ids')}`)
          })
          .afterRespond(submissionPromises[0].resolve)
          .respond([{status: 200, body: exampleData.submissions.slice(0, 1)}])
        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
          .beforeRespond(async request => {
            events.push(`request submissions:${joinRequestIds(request, 'student_ids')}`)
          })
          .afterRespond(submissionPromises[1].resolve)
          .respond([{status: 200, body: exampleData.submissions.slice(1, 3)}])
      })

      it('requests submissions before additional chunks of students', async () => {
        await load()
        const submissionRequest1Index = events.indexOf('request submissions:1101,1102')
        const studentRequest2Index = events.indexOf('request students:1103')
        expect(submissionRequest1Index).toBeLessThan(studentRequest2Index)
      })

      it('requests submissions before related students have returned', async () => {
        await load()
        const submissionRequest1Index = events.indexOf('request submissions:1101,1102')
        const studentChunkIndex = events.indexOf('onStudentsChunkLoaded:1101,1102')
        expect(submissionRequest1Index).toBeLessThan(studentChunkIndex)
      })

      it('calls student callback before submission callback on first load', async () => {
        await load()
        const studentChunkIndex = events.indexOf('onStudentsChunkLoaded:1101,1102')
        const submissionChunkIndex = events.indexOf('onSubmissionsChunkLoaded:2501')
        expect(studentChunkIndex).toBeLessThan(submissionChunkIndex)
      })

      it('calls student callback before submission callback on subsequent loads', async () => {
        await load()
        const studentChunkIndex = events.indexOf('onStudentsChunkLoaded:1103')
        const submissionChunkIndex = events.indexOf('onSubmissionsChunkLoaded:2502,2503')
        expect(studentChunkIndex).toBeLessThan(submissionChunkIndex)
      })
    })

    describe('when a submission request returns multiple pages', () => {
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

      beforeEach(() => {
        const submissionPromises = [latchPromise(), latchPromise()]
        events = []

        options.onStudentsChunkLoaded = eventLogger('onStudentsChunkLoaded')
        options.onSubmissionsChunkLoaded = eventLogger('onSubmissionsChunkLoaded')

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
          .beforeRespond(async request => {
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
          .beforeRespond(async request => {
            events.push(`request submissions:${joinRequestIds(request, 'student_ids')}`)
          })
          .afterRespond(submissionPromises[1].resolve)
          .respond([{status: 200, body: []}])
      })

      it('requests all pages of submissions before additional chunks of students', async () => {
        await load()
        const submissionRequestIndices = [
          events.indexOf('request submissions page 1'),
          events.indexOf('request submissions page 2'),
          events.indexOf('request submissions page 3')
        ]
        const studentRequest2Index = events.indexOf('request students:1103')
        expect(Math.max(...submissionRequestIndices)).toBeLessThan(studentRequest2Index)
      })
    })

    describe('when a student request fails', () => {
      beforeEach(() => {
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

        sinon.stub(FlashAlert, 'showFlashAlert')
      })

      afterEach(() => {
        FlashAlert.showFlashAlert.restore()
      })

      it('does not call onStudentsChunkLoaded for the failed students', async () => {
        const loadedStudents = []
        options.onStudentsChunkLoaded = students => {
          loadedStudents.push(...students)
        }
        await load()
        expect(loadedStudents).toEqual(exampleData.students.slice(2, 3))
      })

      it('does not call onSubmissionsChunkLoaded for related submissions', async () => {
        const loadedSubmissions = []
        options.onSubmissionsChunkLoaded = submissions => {
          loadedSubmissions.push(...submissions)
        }
        await load()
        expect(loadedSubmissions).toEqual(exampleData.submissions.slice(1, 3))
      })

      it('shows a flash alert', async () => {
        await load()
        expect(FlashAlert.showFlashAlert.callCount).toBe(1)
      })

      it('flashes an error', async () => {
        await load()
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        expect(type).toBe('error')
      })
    })

    describe('when an initial submission request fails', () => {
      beforeEach(() => {
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

        sinon.stub(FlashAlert, 'showFlashAlert')
      })

      afterEach(() => {
        FlashAlert.showFlashAlert.restore()
      })

      it('calls onStudentsChunkLoaded for related students', async () => {
        const loadedStudents = []
        options.onStudentsChunkLoaded = students => {
          loadedStudents.push(...students)
        }
        await load()
        expect(loadedStudents).toEqual(exampleData.students)
      })

      it('does not call onSubmissionsChunkLoaded for the failed submissions', async () => {
        const loadedSubmissions = []
        options.onSubmissionsChunkLoaded = submissions => {
          loadedSubmissions.push(...submissions)
        }
        await load()
        expect(loadedSubmissions).toEqual(exampleData.submissions.slice(1, 3))
      })

      it('shows a flash alert', async () => {
        await load()
        expect(FlashAlert.showFlashAlert.callCount).toBe(1)
      })

      it('flashes an error', async () => {
        await load()
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        expect(type).toBe('error')
      })
    })

    describe('when a subsequent submission page request fails', () => {
      beforeEach(() => {
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
          .respond([
            {status: 200, body: exampleData.submissions.slice(0, 1)},
            {status: 500, body: exampleData.submissions.slice(1, 2)}
          ])
        server
          .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
          .respond([{status: 200, body: exampleData.submissions.slice(2, 3)}])

        sinon.stub(FlashAlert, 'showFlashAlert')
      })

      afterEach(() => {
        FlashAlert.showFlashAlert.restore()
      })

      it('calls onStudentsChunkLoaded for related students', async () => {
        const loadedStudents = []
        options.onStudentsChunkLoaded = students => {
          loadedStudents.push(...students)
        }
        await load()
        expect(loadedStudents).toEqual(exampleData.students)
      })

      it('does not call onSubmissionsChunkLoaded for the failed submissions', async () => {
        const loadedSubmissions = []
        options.onSubmissionsChunkLoaded = submissions => {
          loadedSubmissions.push(...submissions)
        }
        await load()
        expect(loadedSubmissions).toEqual(exampleData.submissions.slice(2, 3))
      })

      it('shows a flash alert', async () => {
        await load()
        expect(FlashAlert.showFlashAlert.callCount).toBe(1)
      })

      it('flashes an error', async () => {
        await load()
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        expect(type).toBe('error')
      })
    })
  })
})
