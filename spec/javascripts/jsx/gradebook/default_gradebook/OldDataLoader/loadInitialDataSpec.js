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

import {clearPrefetchedXHRs, getPrefetchedXHR, setPrefetchedXHR} from '@instructure/js-utils'

import waitForCondition from '@canvas/network/NetworkFake/waitForCondition'
import FakeServer, {
  paramsFromRequest,
  pathFromRequest
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper.js'
import * as FinalGradeOverrideApi from '@canvas/grading/FinalGradeOverrideApi'

QUnit.module('Gradebook > OldDataLoader', suiteHooks => {
  const urls = {
    assignmentGroups: '/api/v1/courses/1201/assignment_groups',
    contextModules: '/api/v1/courses/1201/modules',
    customColumns: '/api/v1/courses/1201/custom_gradebook_columns',
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
    const assignments = [
      {
        id: '2301',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: '/courses/1201/assignments/2301',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry']
      },

      {
        id: '2302',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: '/courses/1201/assignments/2302',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry']
      }
    ]

    exampleData = {
      assignmentGroups: [
        {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1)},
        {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2)},
        {id: '2203', position: 3, name: 'Extra Credit', assignments: []}
      ],
      assignments,

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

  QUnit.module('#loadInitialData()', hooks => {
    hooks.beforeEach(() => {
      server = new FakeServer()
      server.for(urls.userIds).respond({status: 200, body: {user_ids: exampleData.studentIds}})

      server.for(urls.assignmentGroups).respond([
        {status: 200, body: exampleData.assignmentGroups.slice(0, 2)},
        {status: 200, body: exampleData.assignmentGroups.slice(2, 3)}
      ])

      server.for(urls.contextModules).respond([
        {status: 200, body: exampleData.contextModules.slice(0, 2)},
        {status: 200, body: exampleData.contextModules.slice(2, 3)}
      ])

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

      server.for(urls.customColumns).respond([
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

    async function loadInitialData() {
      dataLoader.loadInitialData()

      await waitForCondition(() =>
        server.receivedRequests.every(request => Boolean(request.status))
      )
    }

    QUnit.module('loading student ids', () => {
      QUnit.skip('sends the request using the given course id', async () => {
        await loadInitialData()
        const requests = server.filterRequests(urls.userIds)
        strictEqual(requests.length, 1)
      })

      QUnit.skip('stores the loaded student ids in the gradebook', async () => {
        await loadInitialData()
        const loadedStudentIds = gradebook.courseContent.students.listStudentIds()
        deepEqual(loadedStudentIds, exampleData.studentIds)
      })

      QUnit.module('when student ids have been prefetched', contextHooks => {
        contextHooks.beforeEach(() => {
          const jsonString = JSON.stringify({user_ids: exampleData.studentIds})
          const response = new Response(jsonString)
          setPrefetchedXHR('user_ids', Promise.resolve(response))
        })

        contextHooks.afterEach(() => {
          clearPrefetchedXHRs()
        })

        QUnit.skip('does not sends the request using the given course id', async () => {
          await loadInitialData()
          const requests = server.filterRequests(urls.userIds)
          strictEqual(requests.length, 0)
        })

        QUnit.skip('resolves .gotStudentIds with the user ids', async () => {
          await loadInitialData()
          const loadedStudentIds = gradebook.courseContent.students.listStudentIds()
          deepEqual(loadedStudentIds, exampleData.studentIds)
        })

        QUnit.skip('removes the prefetch request', async () => {
          await loadInitialData()
          strictEqual(typeof getPrefetchedXHR('user_ids'), 'undefined')
        })
      })
    })

    QUnit.module('loading grading period assignments', () => {
      QUnit.module('when the course uses a grading period set', () => {
        QUnit.skip('sends the request using the given course id', async () => {
          await loadInitialData()
          const requests = server.filterRequests(urls.gradingPeriodAssignments)
          strictEqual(requests.length, 1)
        })

        QUnit.skip('updates the grading period assignments in the gradebook', async () => {
          await loadInitialData()
          strictEqual(gradebook.updateGradingPeriodAssignments.callCount, 1)
        })

        QUnit.skip('includes the loaded grading period assignments when updating the gradebook', async () => {
          await loadInitialData()
          const [gradingPeriodAssignments] = gradebook.updateGradingPeriodAssignments.lastCall.args
          deepEqual(gradingPeriodAssignments, exampleData.gradingPeriodAssignments)
        })
      })

      QUnit.module('when the course does not use a grading period set', () => {
        QUnit.skip('does not request grading period assignments', async () => {
          gradebook.gradingPeriodSet = null
          await loadInitialData()
          const requests = server.filterRequests(urls.gradingPeriodAssignments)
          strictEqual(requests.length, 0)
        })
      })
    })

    QUnit.module('loading assignment groups', () => {
      QUnit.skip('sends a request for each page of assignment groups', async () => {
        await loadInitialData()
        const requests = server.filterRequests(urls.assignmentGroups)
        strictEqual(requests.length, 2)
      })

      QUnit.skip('updates the assignment groups in the gradebook', async () => {
        await loadInitialData()
        strictEqual(gradebook.updateAssignmentGroups.callCount, 1)
      })

      QUnit.skip('includes the loaded assignment groups when updating the gradebook', async () => {
        await loadInitialData()
        const [assignmentGroups] = gradebook.updateAssignmentGroups.lastCall.args
        deepEqual(
          assignmentGroups.map(group => group.id),
          exampleData.assignmentGroups.map(group => group.id)
        )
      })
    })

    QUnit.module('loading context modules', () => {
      QUnit.skip('sends a request for each page of context modules', async () => {
        await loadInitialData()
        const requests = server.filterRequests(urls.contextModules)
        strictEqual(requests.length, 2)
      })

      QUnit.skip('updates the context modules in the gradebook', async () => {
        await loadInitialData()
        strictEqual(gradebook.updateContextModules.callCount, 1)
      })

      QUnit.skip('includes the loaded context modules when updating the gradebook', async () => {
        await loadInitialData()
        const [contextModules] = gradebook.updateContextModules.lastCall.args
        deepEqual(
          contextModules.map(contextModule => contextModule.id),
          exampleData.contextModules.map(contextModule => contextModule.id)
        )
      })
    })

    QUnit.module('loading custom columns', () => {
      QUnit.skip('sends a request for each page of custom columns', async () => {
        await loadInitialData()
        const requests = server.filterRequests(urls.customColumns)
        strictEqual(requests.length, 2)
      })

      QUnit.skip('includes hidden custom columns', async () => {
        await loadInitialData()
        const requests = server.filterRequests(urls.customColumns)
        const includeHidden = requests.map(request => paramsFromRequest(request).include_hidden)
        deepEqual(includeHidden, ['true', 'true'])
      })

      QUnit.skip('updates the custom columns in the gradebook', async () => {
        await loadInitialData()
        strictEqual(gradebook.gotCustomColumns.callCount, 1)
      })

      QUnit.skip('includes the loaded custom columns when updating the gradebook', async () => {
        await loadInitialData()
        const [customColumns] = gradebook.gotCustomColumns.lastCall.args
        deepEqual(
          customColumns.map(column => column.id),
          exampleData.customColumns.map(column => column.id)
        )
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

      QUnit.skip('requests students using the retrieved student ids', async () => {
        setStudentsResponse(exampleData.studentIds, exampleData.students)
        setSubmissionsResponse(exampleData.studentIds, exampleData.submissions)
        await loadInitialData()
        const studentRequest = server.findRequest(urls.students)
        const params = paramsFromRequest(studentRequest)
        deepEqual(params.user_ids, exampleData.studentIds)
      })

      QUnit.skip('chunks students when per page limit is less than count of student ids', async () => {
        gradebook.options.api_max_per_page = 2
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await loadInitialData()
        const studentsRequests = server.filterRequests(urls.students)
        strictEqual(studentsRequests.length, 2)
      })

      QUnit.skip('updates the gradebook with each chunk of loaded students', async () => {
        gradebook.options.api_max_per_page = 2
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await loadInitialData()
        strictEqual(gradebook.gotChunkOfStudents.callCount, 2)
      })

      QUnit.skip('includes loaded students when updating the gradebook', async () => {
        gradebook.options.api_max_per_page = 2
        setStudentsResponse(exampleData.studentIds.slice(0, 2), exampleData.students.slice(0, 2))
        setStudentsResponse(exampleData.studentIds.slice(2, 3), exampleData.students.slice(2, 3))
        await loadInitialData()
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

        QUnit.skip('updates the "students loaded" status', async () => {
          await loadInitialData()
          strictEqual(gradebook.updateStudentsLoaded.callCount, 1)
        })

        QUnit.skip('sets the students as loaded', async () => {
          await loadInitialData()
          const [loaded] = gradebook.updateStudentsLoaded.lastCall.args
          strictEqual(loaded, true)
        })

        QUnit.skip('updates the status after storing loaded students', async () => {
          gradebook.updateStudentsLoaded.callsFake(() => {
            strictEqual(gradebook.gotChunkOfStudents.callCount, 2)
          })
          await loadInitialData()
        })
      })
    })

    QUnit.module('loading submissions', () => {
      QUnit.skip('requests submissions for each page of students', async () => {
        await loadInitialData()
        const submissionsRequests = server.filterRequests(urls.submissions)
        strictEqual(submissionsRequests.length, 2)
      })

      QUnit.skip('includes "points_deducted" in response fields', async () => {
        await loadInitialData()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        ok(params.response_fields.includes('points_deducted'))
      })

      QUnit.skip('includes "cached_due_date" in response fields', async () => {
        await loadInitialData()
        const submissionsRequest = server.findRequest(urls.submissions)
        const params = paramsFromRequest(submissionsRequest)
        ok(params.response_fields.includes('cached_due_date'))
      })

      QUnit.skip('updates the gradebook with each page of submissions', async () => {
        await loadInitialData()
        strictEqual(gradebook.gotSubmissionsChunk.callCount, 2)
      })

      QUnit.skip('includes the loaded submissions when updating the gradebook', async () => {
        await loadInitialData()
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
        QUnit.skip('updates the "submissions loaded" status', async () => {
          await loadInitialData()
          strictEqual(gradebook.updateSubmissionsLoaded.callCount, 1)
        })

        QUnit.skip('sets the submissions as loaded', async () => {
          await loadInitialData()
          const [loaded] = gradebook.updateSubmissionsLoaded.lastCall.args
          strictEqual(loaded, true)
        })

        QUnit.skip('updates the status after storing loaded submissions', async () => {
          gradebook.updateSubmissionsLoaded.callsFake(() => {
            strictEqual(gradebook.gotSubmissionsChunk.callCount, 2)
          })
          await loadInitialData()
        })
      })
    })

    QUnit.module('loading final grade overrides', () => {
      QUnit.skip('requests overrides when "allow final grade overrides" is enabled', async () => {
        await loadInitialData()
        strictEqual(FinalGradeOverrideApi.getFinalGradeOverrides.callCount, 1)
      })

      QUnit.skip('does not request overrides when "allow final grade overrides" is disabled', async () => {
        gradebook.courseSettings.setAllowFinalGradeOverride(false)
        await loadInitialData()
        strictEqual(FinalGradeOverrideApi.getFinalGradeOverrides.callCount, 0)
      })

      QUnit.skip('uses the given course id when loading final grade overrides', async () => {
        await loadInitialData()
        const [courseId] = FinalGradeOverrideApi.getFinalGradeOverrides.lastCall.args
        strictEqual(courseId, '1201')
      })

      QUnit.skip('updates Gradebook when the final grade overrides have loaded', async () => {
        await loadInitialData()
        strictEqual(gradebook.finalGradeOverrides.setGrades.callCount, 1)
      })

      QUnit.skip('updates Gradebook with the loaded final grade overrides', async () => {
        await loadInitialData()
        const [finalGradeOverrides] = gradebook.finalGradeOverrides.setGrades.lastCall.args
        deepEqual(finalGradeOverrides, exampleData.finalGradeOverrides)
      })
    })

    QUnit.module('loading custom column data', () => {
      QUnit.skip('waits while students are still loading', async () => {
        await loadInitialData()
        const indexOfLastStudentRequest = server.findLastIndex(urls.students)
        const indexOfFirstDataRequest = server.findFirstIndex(urls.customColumnData('.*'))
        ok(indexOfFirstDataRequest > indexOfLastStudentRequest)
      })

      QUnit.skip('waits while submissions are still loading', async () => {
        await loadInitialData()
        const indexOfLastStudentRequest = server.findLastIndex(urls.submissions)
        const indexOfFirstDataRequest = server.findFirstIndex(urls.customColumnData('.*'))
        ok(indexOfFirstDataRequest > indexOfLastStudentRequest)
      })

      QUnit.module('when submissions have finished loading', () => {
        QUnit.skip('requests custom column data for each custom column', async () => {
          await loadInitialData()
          const requests = server.filterRequests(urls.customColumnData('.*'))
          strictEqual(requests.length, 3)
        })

        QUnit.skip('requests custom column data using the custom column ids', async () => {
          await loadInitialData()
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

        QUnit.skip('includes custom column data parameters with each request', async () => {
          await loadInitialData()
          const parameterValues = server
            .filterRequests(urls.customColumnData('.*'))
            .map(request => paramsFromRequest(request).include_hidden)
          deepEqual(parameterValues, ['true', 'true', 'true'])
        })
      })
    })
  })
})
