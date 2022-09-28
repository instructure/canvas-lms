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
import FakeServer from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import * as FinalGradeOverrideApi from '@canvas/grading/FinalGradeOverrideApi'

QUnit.module('Gradebook > DataLoader', suiteHooks => {
  const urls = {
    customColumnData: columnId => `/api/v1/courses/1201/custom_gradebook_columns/${columnId}/data`,
    students: '/api/v1/courses/1201/users',
    submissions: '/api/v1/courses/1201/students/submissions',
    userIds: '/courses/1201/gradebook/user_ids',
  }

  let dataLoader
  let exampleData
  let gradebook
  let server
  let returnStudentIds = []

  suiteHooks.beforeEach(() => {
    exampleData = {
      customColumnData: [{id: '2801'}, {id: '2802'}, {id: '2803'}],

      finalGradeOverrides: {
        1101: {
          courseGrade: {
            percentage: 91.23,
          },
        },
      },

      studentIds: ['1101', '1102', '1103'],

      students: [
        {
          id: '1101',
          name: 'Adam Jones',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1101'},
              type: 'StudentEnrollment',
            },
          ],
        },

        {
          id: '1102',
          name: 'Betty Ford',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1102'},
              type: 'StudentEnrollment',
            },
          ],
        },

        {
          id: '1103',
          name: 'Chuck Long',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1103'},
              type: 'StudentEnrollment',
            },
          ],
        },
      ],

      submissions: [
        {
          assignment_id: '2301',
          assignment_visible: true,
          cached_due_date: '2015-10-15T12:00:00Z',
          id: '2501',
          score: 10,
          user_id: '1101',
        },

        {
          assignment_id: '2302',
          assignment_visible: true,
          cached_due_date: '2015-12-15T12:00:00Z',
          id: '2502',
          score: 9,
          user_id: '1101',
        },

        {
          assignment_id: '2301',
          assignment_visible: true,
          cached_due_date: '2015-10-16T12:00:00Z',
          id: '2503',
          score: 10,
          user_id: '1102',
        },
      ],
    }
  })

  QUnit.module('#reloadStudentDataForSectionFilterChange()', hooks => {
    hooks.beforeEach(() => {
      server = new FakeServer()
      server.for(urls.userIds).respond({status: 200, body: {user_ids: exampleData.studentIds}})

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
        context_id: '1201',

        course_settings: {
          allow_final_grade_override: true,
          filter_speed_grader_by_student_group: false,
        },

        final_grade_override_enabled: true,
        grading_period_set: {
          id: '1501',
          grading_periods: [
            {id: '701', title: 'Grading Period 1', startDate: new Date(1)},
            {id: '702', title: 'Grading Period 2', startDate: new Date(2)},
          ],
        },

        performance_controls: {
          students_chunk_size: 2, // students per page
        },

        fetchStudentIds: () => Promise.resolve(returnStudentIds),
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

      returnStudentIds = []
    })

    hooks.afterEach(() => {
      FinalGradeOverrideApi.getFinalGradeOverrides.restore()
      server.teardown()
    })

    async function reloadData() {
      dataLoader.reloadStudentDataForSectionFilterChange()

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

    test('does not load assignment groups', async () => {
      sinon.spy(dataLoader.assignmentGroupsLoader, 'loadAssignmentGroups')
      await reloadData()
      strictEqual(dataLoader.assignmentGroupsLoader.loadAssignmentGroups.callCount, 0)
    })

    test('loads student content', async () => {
      sinon.spy(dataLoader.studentContentDataLoader, 'load')
      await reloadData()
      strictEqual(dataLoader.studentContentDataLoader.load.callCount, 1)
    })

    test('excludes students already loaded when loading student content', async () => {
      returnStudentIds = ['1102']

      // This will not be sufficient when interruptable reloads are implemented
      gradebook.updateStudentIds(['1101', '1103'])
      sinon.spy(dataLoader.studentContentDataLoader, 'load')

      server
        .for(urls.students, {user_ids: ['1102']})
        .respond({status: 200, body: exampleData.students.slice(1, 2)})
      server.unsetResponses(urls.submissions)
      server
        .for(urls.submissions, {student_ids: ['1102']})
        .respond([{status: 200, body: exampleData.submissions.slice(2, 3)}])

      await reloadData()
      const [studentIds] = dataLoader.studentContentDataLoader.load.lastCall.args
      deepEqual(studentIds, ['1102'])
    })

    test('loads custom column data', async () => {
      sinon.spy(dataLoader.customColumnsDataLoader, 'loadCustomColumnsData')
      await reloadData()
      strictEqual(dataLoader.customColumnsDataLoader.loadCustomColumnsData.callCount, 1)
    })

    test('loads custom column data after students finish loading', async () => {
      sinon.stub(dataLoader.customColumnsDataLoader, 'loadCustomColumnsData').callsFake(() => {
        strictEqual(gradebook.updateStudentsLoaded.withArgs(true).callCount, 1)
      })
      await reloadData()
    })

    test('loads custom column data after submissions finish loading', async () => {
      sinon.stub(dataLoader.customColumnsDataLoader, 'loadCustomColumnsData').callsFake(() => {
        strictEqual(gradebook.updateSubmissionsLoaded.withArgs(true).callCount, 1)
      })
      await reloadData()
    })
  })
})
