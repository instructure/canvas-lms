/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute test and/or modify test under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that test will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import sinon from 'sinon'

import waitForCondition from '@canvas/network/NetworkFake/waitForCondition'
import FakeServer, {
  paramsFromRequest,
  pathFromRequest
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper.js'
import * as FinalGradeOverrideApi from '@canvas/grading/FinalGradeOverrideApi'

QUnit.module('Gradebook > OldDataLoader', suiteHooks => {
  const urls = {
    customColumnData: columnId => `/api/v1/courses/1201/custom_gradebook_columns/${columnId}/data`,
    gradingPeriodAssignments: '/courses/1201/gradebook/grading_period_assignments',
    students: '/api/v1/courses/1201/users',
    submissions: '/api/v1/courses/1201/students/submissions',
    userIds: '/courses/1201/gradebook/user_ids'
  }

  let dataLoader
  let exampleData
  let gradebook
  let server

  suiteHooks.beforeEach(() => {
    exampleData = {
      customColumnData: [{id: '2801'}, {id: '2802'}, {id: '2803'}],

      finalGradeOverrides: {
        1101: {
          courseGrade: {
            percentage: 91.23
          }
        }
      },

      gradingPeriodAssignments: {1401: ['2301']},
      studentIds: ['1101', '1102', '1103'],

      students: [
        {
          id: '1101',
          name: 'Adam Jones',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1101'},
              type: 'StudentEnrollment'
            }
          ]
        },

        {
          id: '1102',
          name: 'Betty Ford',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1102'},
              type: 'StudentEnrollment'
            }
          ]
        },

        {
          id: '1103',
          name: 'Chuck Long',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1103'},
              type: 'StudentEnrollment'
            }
          ]
        }
      ],

      submissions: [
        {
          assignment_id: '2301',
          assignment_visible: true,
          cached_due_date: '2015-10-15T12:00:00Z',
          id: '2501',
          score: 10,
          user_id: '1101'
        },

        {
          assignment_id: '2302',
          assignment_visible: true,
          cached_due_date: '2015-12-15T12:00:00Z',
          id: '2502',
          score: 9,
          user_id: '1101'
        },

        {
          assignment_id: '2301',
          assignment_visible: true,
          cached_due_date: '2015-10-16T12:00:00Z',
          id: '2503',
          score: 10,
          user_id: '1102'
        }
      ]
    }
  })

  QUnit.module('#reloadStudentDataForEnrollmentFilterChange()', hooks => {
    hooks.beforeEach(() => {
      server = new FakeServer()
      server.for(urls.userIds).respond({status: 200, body: {user_ids: exampleData.studentIds}})

      server.for(urls.gradingPeriodAssignments).respond({
        status: 200,
        body: {grading_period_assignments: exampleData.gradingPeriodAssignments}
      })

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

      gradebook = createGradebook({
        api_max_per_page: 2, // students per page
        context_id: '1201',

        course_settings: {
          allow_final_grade_override: true,
          filter_speed_grader_by_student_group: false
        },

        dataloader_improvements: false,
        final_grade_override_enabled: true,
        grading_period_set: {
          id: '1501',
          grading_periods: [
            {id: '701', title: 'Grading Period 1', startDate: new Date(1)},
            {id: '702', title: 'Grading Period 2', startDate: new Date(2)}
          ]
        }
      })

      sinon.stub(gradebook.finalGradeOverrides, 'setGrades')

      dataLoader = gradebook.dataLoader

      sinon.stub(gradebook, 'updateGradingPeriodAssignments')
      sinon.stub(gradebook, 'updateAssignmentGroups')
      sinon.stub(gradebook, 'updateContextModules')
      sinon.stub(gradebook, 'updateSubmissionsLoaded')
      sinon.stub(gradebook, 'updateStudentsLoaded')
      sinon.stub(gradebook, 'gotCustomColumns')
      sinon.stub(gradebook, 'gotChunkOfStudents')
      sinon.stub(gradebook, 'gotSubmissionsChunk')
    })

    hooks.afterEach(() => {
      FinalGradeOverrideApi.getFinalGradeOverrides.restore()
      server.teardown()
    })

    async function reloadData() {
      dataLoader.reloadStudentDataForEnrollmentFilterChange()

      await waitForCondition(() =>
        server.receivedRequests.every(request => Boolean(request.status))
      )
    }

    test('updates the "students loaded" status in the gradebook', async () => {
      await reloadData()
      notEqual(gradebook.updateStudentsLoaded.callCount, 0)
    })

    test('sets the students as not loaded', async () => {
      await reloadData()
      const [loaded] = gradebook.updateStudentsLoaded.firstCall.args
      strictEqual(loaded, false)
    })

    test('updates the "students loaded" status before sending requests', async () => {
      gradebook.updateStudentsLoaded.onFirstCall().callsFake(() => {
        strictEqual(server.receivedRequests.length, 0)
      })
      await reloadData()
    })

    test('updates the "submissions loaded" status in the gradebook', async () => {
      await reloadData()
      notEqual(gradebook.updateSubmissionsLoaded.callCount, 0)
    })

    test('sets the submissions as not loaded', async () => {
      await reloadData()
      const [loaded] = gradebook.updateSubmissionsLoaded.firstCall.args
      strictEqual(loaded, false)
    })

    test('updates the "submissions loaded" status before sending requests', async () => {
      gradebook.updateSubmissionsLoaded.onFirstCall().callsFake(() => {
        strictEqual(server.receivedRequests.length, 0)
      })
      await reloadData()
    })

    QUnit.module('loading student ids', () => {
      test('sends the request using the given course id', async () => {
        await reloadData()
        const requests = server.filterRequests(urls.userIds)
        strictEqual(requests.length, 1)
      })

      test('stores the loaded student ids in the gradebook', async () => {
        await reloadData()
        const loadedStudentIds = gradebook.courseContent.students.listStudentIds()
        deepEqual(loadedStudentIds, exampleData.studentIds)
      })
    })

    QUnit.module('loading grading period assignments', () => {
      QUnit.module('when the course uses a grading period set', () => {
        test('sends the request using the given course id', async () => {
          await reloadData()
          const requests = server.filterRequests(urls.gradingPeriodAssignments)
          strictEqual(requests.length, 1)
        })

        test('updates the grading period assignments in the gradebook', async () => {
          await reloadData()
          strictEqual(gradebook.updateGradingPeriodAssignments.callCount, 1)
        })

        test('includes the loaded grading period assignments when updating the gradebook', async () => {
          await reloadData()
          const [gradingPeriodAssignments] = gradebook.updateGradingPeriodAssignments.lastCall.args
          deepEqual(gradingPeriodAssignments, exampleData.gradingPeriodAssignments)
        })
      })

      QUnit.module('when the course does not use a grading period set', () => {
        test('does not request grading period assignments', async () => {
          gradebook.gradingPeriodSet = null
          await reloadData()
          const requests = server.filterRequests(urls.gradingPeriodAssignments)
          strictEqual(requests.length, 0)
        })
      })
    })

    QUnit.module('loading students', contextHooks => {
      contextHooks.beforeEach(() => {
        server.unsetResponses(urls.students)
        gradebook.options.api_max_per_page = 50
      })

      function setStudentsResponse(ids, students) {
        server.for(urls.students, {user_ids: ids}).respond({status: 200, body: students})
      }

      function setSubmissionsResponse(ids, submissions) {
        server.unsetResponses(urls.submissions)
        server.for(urls.submissions, {student_ids: ids}).respond([{status: 200, body: submissions}])
      }

      test('requests students using the retrieved student ids', async () => {
        setStudentsResponse(exampleData.studentIds, exampleData.students)
        setSubmissionsResponse(exampleData.studentIds, exampleData.submissions)
        await reloadData()
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        deepEqual(params.user_ids, exampleData.studentIds)
      })

      test('does not request students already loaded', async () => {
        // This will not be sufficient when interruptable reloads are implemented
        gradebook.updateStudentIds(['1101', '1103'])
        setStudentsResponse(['1102'], [{id: '1102'}])
        setSubmissionsResponse(['1102'], [{id: '2502'}])
        await reloadData()
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        deepEqual(params.user_ids, ['1102'])
      })

      test('chunks students when per page limit is less than count of student ids', async () => {
        gradebook.options.api_max_per_page = 2
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await reloadData()
        const studentsRequests = server.filterRequests(urls.students)
        strictEqual(studentsRequests.length, 2)
      })

      test('updates the gradebook with each chunk of loaded students', async () => {
        gradebook.options.api_max_per_page = 2
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await reloadData()
        strictEqual(gradebook.gotChunkOfStudents.callCount, 2)
      })

      test('includes loaded students when updating the gradebook', async () => {
        gradebook.options.api_max_per_page = 2
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await reloadData()
        const loadedStudentIds = []
        gradebook.gotChunkOfStudents.getCalls().forEach(call => {
          loadedStudentIds.push(...call.args[0].map(student => student.id))
        })
        deepEqual(
          loadedStudentIds,
          exampleData.students.map(student => student.id)
        )
      })

      QUnit.module('when all students have finished loading', loadingHooks => {
        loadingHooks.beforeEach(() => {
          gradebook.options.api_max_per_page = 2
          setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
          setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        })

        test('updates the "students loaded" status', async () => {
          await reloadData()
          strictEqual(gradebook.updateStudentsLoaded.callCount, 2)
        })

        test('sets the students as loaded', async () => {
          await reloadData()
          const [loaded] = gradebook.updateStudentsLoaded.lastCall.args
          strictEqual(loaded, true)
        })

        test('updates the status after storing loaded students', async () => {
          gradebook.updateStudentsLoaded.onSecondCall().callsFake(() => {
            strictEqual(gradebook.gotChunkOfStudents.callCount, 2)
          })
          await reloadData()
        })
      })
    })

    QUnit.module('loading submissions', () => {
      test('requests submissions for each page of students', async () => {
        await reloadData()
        const submissionsRequests = server.filterRequests(urls.submissions)
        strictEqual(submissionsRequests.length, 2)
      })

      test('includes "points_deducted" in response fields', async () => {
        await reloadData()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        ok(params.response_fields.includes('points_deducted'))
      })

      test('includes "cached_due_date" in response fields', async () => {
        await reloadData()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        ok(params.response_fields.includes('cached_due_date'))
      })

      test('updates the gradebook with each page of submissions', async () => {
        await reloadData()
        strictEqual(gradebook.gotSubmissionsChunk.callCount, 2)
      })

      test('includes the loaded submissions when updating the gradebook', async () => {
        await reloadData()
        const loadedSubmissionIds = []
        gradebook.gotSubmissionsChunk.getCalls().forEach(call => {
          loadedSubmissionIds.push(...call.args[0].map(submission => submission.id))
        })
        deepEqual(
          loadedSubmissionIds,
          exampleData.submissions.map(submission => submission.id)
        )
      })

      QUnit.module('when all submissions have finished loading', () => {
        test('updates the "submissions loaded" status', async () => {
          await reloadData()
          strictEqual(gradebook.updateSubmissionsLoaded.callCount, 2)
        })

        test('sets the submissions as loaded', async () => {
          await reloadData()
          const [loaded] = gradebook.updateSubmissionsLoaded.lastCall.args
          strictEqual(loaded, true)
        })

        test('updates the status after storing loaded submissions', async () => {
          gradebook.updateSubmissionsLoaded.onSecondCall().callsFake(() => {
            strictEqual(gradebook.gotSubmissionsChunk.callCount, 2)
          })
          await reloadData()
        })
      })
    })

    QUnit.module('loading final grade overrides', () => {
      test('requests overrides when "allow final grade overrides" is enabled', async () => {
        await reloadData()
        strictEqual(FinalGradeOverrideApi.getFinalGradeOverrides.callCount, 1)
      })

      test('does not request overrides when "allow final grade overrides" is disabled', async () => {
        gradebook.courseSettings.setAllowFinalGradeOverride(false)
        await reloadData()
        strictEqual(FinalGradeOverrideApi.getFinalGradeOverrides.callCount, 0)
      })

      test('uses the given course id when loading final grade overrides', async () => {
        await reloadData()
        const [courseId] = FinalGradeOverrideApi.getFinalGradeOverrides.lastCall.args
        strictEqual(courseId, '1201')
      })

      test('updates Gradebook when the final grade overrides have loaded', async () => {
        await reloadData()
        strictEqual(gradebook.finalGradeOverrides.setGrades.callCount, 1)
      })

      test('updates Gradebook with the loaded final grade overrides', async () => {
        await reloadData()
        const [finalGradeOverrides] = gradebook.finalGradeOverrides.setGrades.lastCall.args
        deepEqual(finalGradeOverrides, exampleData.finalGradeOverrides)
      })
    })

    QUnit.module('loading custom column data', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.gradebookContent.customColumns = [{id: '2401'}, {id: '2402'}, {id: '2403'}]
      })

      test('waits while students are still loading', async () => {
        await reloadData()
        const indexOfLastStudentRequest = server.findLastIndex(urls.students)
        const indexOfFirstDataRequest = server.findFirstIndex(urls.customColumnData('.*'))
        ok(indexOfFirstDataRequest > indexOfLastStudentRequest)
      })

      test('waits while submissions are still loading', async () => {
        await reloadData()
        const indexOfLastStudentRequest = server.findLastIndex(urls.submissions)
        const indexOfFirstDataRequest = server.findFirstIndex(urls.customColumnData('.*'))
        ok(indexOfFirstDataRequest > indexOfLastStudentRequest)
      })

      QUnit.module('when submissions have finished loading', () => {
        test('requests custom column data for each loaded custom column', async () => {
          await reloadData()
          const requests = server.filterRequests(urls.customColumnData('.*'))
          strictEqual(requests.length, 3)
        })

        test('requests custom column data using the custom column ids', async () => {
          await reloadData()
          const requestUrls = server
            .filterRequests(urls.customColumnData('.*'))
            .map(pathFromRequest)
          const expectedUrls = [
            urls.customColumnData('2401'),
            urls.customColumnData('2402'),
            urls.customColumnData('2403')
          ]
          deepEqual(requestUrls, expectedUrls)
        })

        test('includes custom column data parameters with each request', async () => {
          await reloadData()
          const parameterValues = server
            .filterRequests(urls.customColumnData('.*'))
            .map(request => paramsFromRequest(request).include_hidden)
          deepEqual(parameterValues, ['true', 'true', 'true'])
        })
      })
    })
  })
})
