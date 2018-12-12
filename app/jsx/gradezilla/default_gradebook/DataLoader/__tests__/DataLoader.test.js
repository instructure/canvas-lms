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

import FakeServer, {paramsFromRequest, pathFromRequest} from '../../../../__tests__/FakeServer'
import DataLoader from '../../../DataLoader'
import * as FinalGradeOverrideApi from '../../FinalGradeOverrides/FinalGradeOverrideApi'

describe('Gradebook DataLoader', () => {
  const exampleData = {
    assignmentGroups: [{id: '2201'}, {id: '2202'}, {id: '2203'}],
    contextModules: [{id: '2601'}, {id: '2602 '}, {id: '2603'}],
    customColumnData: [{id: '2801'}, {id: '2802'}, {id: '2803'}],
    customColumns: [{id: '2401'}, {id: '2402'}, {id: '2403'}],

    finalGradeOverrides: {
      1101: {
        courseGrade: {
          percentage: 91.23
        }
      }
    },

    gradingPeriodAssignments: {1401: ['2301']},
    studentIds: ['1101', '1102', '1103'],
    students: [{id: '1101'}, {id: '1102'}, {id: '1103'}],
    submissions: [{id: '2501'}, {id: '2502'}, {id: '2503'}]
  }

  const urls = {
    assignmentGroups: '/assignment-groups',
    contextModules: '/context-modules',
    customColumns: '/custom-columns',
    customColumnData: columnId => `/custom-columns/${columnId}/data`,
    gradingPeriodAssignments: '/courses/1201/gradebook/grading_period_assignments',
    students: '/students',
    submissions: '/submissions',
    userIds: '/courses/1201/gradebook/user_ids'
  }

  let dataLoader
  let gradebook
  let server

  beforeEach(() => {
    server = new FakeServer()
    server.for(urls.userIds).respond({status: 200, body: {user_ids: exampleData.studentIds}})

    server
      .for(urls.assignmentGroups)
      .respond([
        {status: 200, body: exampleData.assignmentGroups.slice(0, 2)},
        {status: 200, body: exampleData.assignmentGroups.slice(2, 3)}
      ])

    server
      .for(urls.contextModules)
      .respond([
        {status: 200, body: exampleData.contextModules.slice(0, 2)},
        {status: 200, body: exampleData.contextModules.slice(2, 3)}
      ])

    server
      .for(urls.gradingPeriodAssignments)
      .respond({status: 200, body: exampleData.gradingPeriodAssignments})

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

    server
      .for(urls.customColumns)
      .respond([
        {status: 200, body: exampleData.customColumns.slice(0, 2)},
        {status: 200, body: exampleData.customColumns.slice(2, 3)}
      ])

    server
      .for(urls.customColumnData('2401'))
      .respond([{status: 200, body: exampleData.customColumnData.slice(0, 2)}])
    server
      .for(urls.customColumnData('2402'))
      .respond([{status: 200, body: exampleData.customColumnData.slice(2, 3)}])
    server
      .for(urls.customColumnData('2403'))
      .respond([{status: 200, body: exampleData.customColumnData.slice(3, 4)}])

    sinon
      .stub(FinalGradeOverrideApi, 'getFinalGradeOverrides')
      .returns(Promise.resolve({finalGradeOverrides: exampleData.finalGradeOverrides}))

    gradebook = {
      finalGradeOverrides: {
        setGrades: sinon.stub()
      }
    }
  })

  afterEach(() => {
    FinalGradeOverrideApi.getFinalGradeOverrides.restore()
    server.teardown()
  })

  describe('.loadGradebookData()', () => {
    async function loadGradebookData(options = {}) {
      dataLoader = DataLoader.loadGradebookData({
        assignmentGroupsParams: {include: ['module_ids']},
        assignmentGroupsURL: urls.assignmentGroups,
        contextModulesURL: urls.contextModules,
        courseId: '1201',
        customColumnDataPageCb() {},
        customColumnDataParams: {},
        customColumnDataURL: urls.customColumnData(':id'),
        customColumnsURL: urls.customColumns,
        getFinalGradeOverrides: false,
        gradebook,
        perPage: 2,
        studentsPageCb() {},
        studentsParams: {enrollment_state: ['active']},
        studentsURL: urls.students,
        submissionsChunkCb() {},
        submissionsChunkSize: 2,
        submissionsURL: urls.submissions,
        ...options
      })

      await new Promise((resolve, reject) => {
        const timeoutId = setTimeout(() => {
          const pendingPromises = []
          Object.keys(dataLoader).forEach(key => {
            if (dataLoader[key] && dataLoader[key].state() === 'pending') {
              pendingPromises.push(key)
            }
          })
          reject(new Error(`unresolved promises: ${pendingPromises.join(', ')}`))
        }, 2000)

        Promise.all(Object.values(dataLoader)).then(() => {
          clearTimeout(timeoutId)
          resolve()
        })
      })
    }

    describe('loading student ids', () => {
      it('sends the request using the given course id', async () => {
        await loadGradebookData()
        const requests = server.filterRequests(urls.userIds)
        expect(requests).toHaveLength(1)
      })

      it('resolves .gotStudentIds with the user ids', async () => {
        let loadedStudentIds
        await loadGradebookData()
        dataLoader.gotStudentIds.then(studentIds => (loadedStudentIds = studentIds))
        expect(loadedStudentIds).toEqual({user_ids: exampleData.studentIds})
      })
    })

    describe('loading grading period assignments', () => {
      it('sends the request using the given course id', async () => {
        await loadGradebookData({getGradingPeriodAssignments: true})
        const requests = server.filterRequests(urls.gradingPeriodAssignments)
        expect(requests).toHaveLength(1)
      })

      it('resolves .gotGradingPeriodAssignments with the grading period assignments', async () => {
        let loadedData
        await loadGradebookData({getGradingPeriodAssignments: true})
        dataLoader.gotGradingPeriodAssignments.then(data => (loadedData = data))
        expect(loadedData).toEqual(exampleData.gradingPeriodAssignments)
      })

      it('optionally does not request grading period assignments', async () => {
        await loadGradebookData()
        expect(dataLoader.gotGradingPeriodAssignments).toBeUndefined()
      })
    })

    describe('loading assignment groups', () => {
      it('resolves .gotAssignmentGroups when all pages have returned', async () => {
        await loadGradebookData()
        const requests = server.filterRequests(urls.assignmentGroups)
        expect(requests).toHaveLength(2)
      })

      it('resolves .gotAssignmentGroups with assignment groups from all pages', async () => {
        let loadedAssignmentGroups
        await loadGradebookData()
        dataLoader.gotAssignmentGroups.then(
          assignmentGroups => (loadedAssignmentGroups = assignmentGroups)
        )
        expect(loadedAssignmentGroups).toEqual(exampleData.assignmentGroups)
      })
    })

    describe('loading context modules', () => {
      it('resolves .gotContextModules when all pages have returned', async () => {
        await loadGradebookData()
        const requests = server.filterRequests(urls.contextModules)
        expect(requests).toHaveLength(2)
      })

      it('resolves .gotContextModules with context modules from all pages', async () => {
        let loadedModules
        await loadGradebookData()
        dataLoader.gotContextModules.then(modules => (loadedModules = modules))
        expect(loadedModules).toEqual(exampleData.contextModules)
      })
    })

    describe('loading custom columns', () => {
      it('resolves .gotCustomColumns when all pages have returned', async () => {
        await loadGradebookData()
        const requests = server.filterRequests(urls.customColumns)
        expect(requests).toHaveLength(2)
      })

      it('includes hidden custom columns', async () => {
        await loadGradebookData()
        const requests = server.filterRequests(urls.customColumns)
        const includeHidden = requests.map(request => paramsFromRequest(request).include_hidden)
        expect(includeHidden).toEqual(['true', 'true'])
      })

      it('resolves .gotCustomColumns with custom columns from all pages', async () => {
        let loadedColumns
        await loadGradebookData()
        dataLoader.gotCustomColumns.then(columns => (loadedColumns = columns))
        expect(loadedColumns).toEqual(exampleData.customColumns)
      })
    })

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

      it('requests students using the retrieved student ids', async () => {
        setStudentsResponse(exampleData.studentIds, exampleData.students)
        await loadGradebookData({perPage: 50})
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        expect(params.user_ids).toEqual(exampleData.studentIds)
      })

      it('does not request students already loaded', async () => {
        setStudentsResponse(['1102'], [{id: '1102'}])
        setSubmissionsResponse(['1102'], [{id: '2502'}])
        await loadGradebookData({loadedStudentIds: ['1101', '1103'], perPage: 50})
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        expect(params.user_ids).toEqual(['1102'])
      })

      it('chunks students when per page limit is less than count of student ids', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await loadGradebookData({perPage: 2})
        const studentsRequests = server.filterRequests(urls.students)
        expect(studentsRequests).toHaveLength(2)
      })

      it('calls the students page callback when each students page request resolves', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        const callCounter = sinon.spy()
        await loadGradebookData({studentsPageCb: callCounter})
        expect(callCounter.callCount).toEqual(2)
      })

      it('includes loaded students with each callback', async () => {
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        const loadedStudents = []
        function saveStudents(students) {
          loadedStudents.push(...students)
        }
        await loadGradebookData({studentsPageCb: saveStudents})
        expect(loadedStudents).toEqual(exampleData.students)
      })
    })

    describe('loading submissions', () => {
      // requests submissions using the retrieved student ids

      it('requests submissions for each page of students', async () => {
        await loadGradebookData()
        const submissionsRequests = server.filterRequests(urls.submissions)
        expect(submissionsRequests).toHaveLength(2)
      })

      it('includes "points_deducted" in response fields', async () => {
        await loadGradebookData()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        expect(params.response_fields).toContain('points_deducted')
      })

      it('includes "cached_due_date" in response fields', async () => {
        await loadGradebookData()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        expect(params.response_fields).toContain('cached_due_date')
      })

      it('calls the submissions chunk callback for each chunk of submissions', async () => {
        const submissionChunks = []
        const submissionsChunkCb = submissionChunks.push.bind(submissionChunks)
        await loadGradebookData({submissionsChunkCb})
        expect(submissionChunks).toHaveLength(2)
      })

      it('includes loaded submissions with each callback', async () => {
        const submissionChunks = []
        const submissionsChunkCb = submissionChunks.push.bind(submissionChunks)
        await loadGradebookData({submissionsChunkCb})
        expect(submissionChunks).toEqual([
          exampleData.submissions.slice(0, 1),
          exampleData.submissions.slice(1, 3)
        ])
      })
    })

    describe('loading final grade overrides', () => {
      it('optionally requests final grade overrides', async () => {
        await loadGradebookData({getFinalGradeOverrides: true})
        expect(FinalGradeOverrideApi.getFinalGradeOverrides.callCount).toEqual(1)
      })

      it('optionally does not request final grade overrides', async () => {
        await loadGradebookData({getFinalGradeOverrides: false})
        expect(FinalGradeOverrideApi.getFinalGradeOverrides.callCount).toEqual(0)
      })

      it('uses the given course id when loading final grade overrides', async () => {
        await loadGradebookData({getFinalGradeOverrides: true})
        const [courseId] = FinalGradeOverrideApi.getFinalGradeOverrides.lastCall.args
        expect(courseId).toEqual('1201')
      })

      it('updates Gradebook when the final grade overrides have loaded', async () => {
        await loadGradebookData({getFinalGradeOverrides: true})
        expect(gradebook.finalGradeOverrides.setGrades.callCount).toEqual(1)
      })

      it('updates Gradebook with the loaded final grade overrides', async () => {
        await loadGradebookData({getFinalGradeOverrides: true})
        const [finalGradeOverrides] = gradebook.finalGradeOverrides.setGrades.lastCall.args
        expect(finalGradeOverrides).toEqual(exampleData.finalGradeOverrides)
      })
    })

    describe('loading custom column data', () => {
      it('waits while students are still loading', async () => {
        await loadGradebookData()
        const indexOfLastStudentRequest = server.findLastIndex(urls.students)
        const indexOfFirstDataRequest = server.findFirstIndex(urls.customColumnData('.*'))
        expect(indexOfFirstDataRequest).toBeGreaterThan(indexOfLastStudentRequest)
      })

      it('waits while submissions are still loading', async () => {
        await loadGradebookData()
        const indexOfLastStudentRequest = server.findLastIndex(urls.submissions)
        const indexOfFirstDataRequest = server.findFirstIndex(urls.customColumnData('.*'))
        expect(indexOfFirstDataRequest).toBeGreaterThan(indexOfLastStudentRequest)
      })

      describe('when submissions have finished loading', () => {
        it('requests custom column data for each custom column', async () => {
          await loadGradebookData()
          const requests = server.filterRequests(urls.customColumnData('.*'))
          expect(requests).toHaveLength(3)
        })

        it('requests custom column data using the custom column ids', async () => {
          await loadGradebookData()
          const requestUrls = server
            .filterRequests(urls.customColumnData('.*'))
            .map(pathFromRequest)
          const expectedUrls = [
            '/custom-columns/2401/data',
            '/custom-columns/2402/data',
            '/custom-columns/2403/data'
          ]
          expect(requestUrls).toEqual(expectedUrls)
        })

        it('includes custom column data parameters with each request', async () => {
          await loadGradebookData({customColumnDataParams: {parameter: 'example'}})
          const parameterValues = server
            .filterRequests(urls.customColumnData('.*'))
            .map(request => paramsFromRequest(request).parameter)
          expect(parameterValues).toEqual(['example', 'example', 'example'])
        })
      })
    })
  })
})
