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
    assignmentGroups: '/api/v1/courses/1201/assignment_groups',
    contextModules: '/api/v1/courses/1201/modules',
    customColumns: '/api/v1/courses/1201/custom_gradebook_columns',
    customColumnData: columnId => `/api/v1/courses/1201/custom_gradebook_columns/${columnId}/data`,
    gradingPeriodAssignments: '/courses/1201/gradebook/grading_period_assignments',
    students: '/api/v1/courses/1201/users',
    submissions: '/api/v1/courses/1201/students/submissions',
    userIds: '/courses/1201/gradebook/user_ids',
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
        submission_types: ['online_text_entry'],
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
        submission_types: ['online_text_entry'],
      },
    ]

    exampleData = {
      assignmentGroups: [
        {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1)},
        {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2)},
        {id: '2203', position: 3, name: 'Extra Credit', assignments: []},
      ],
      assignments,

      contextModules: [{id: '2601'}, {id: '2602 '}, {id: '2603'}],
      customColumnData: [{id: '2801'}, {id: '2802'}, {id: '2803'}],
      customColumns: [{id: '2401'}, {id: '2402'}, {id: '2403'}],

      finalGradeOverrides: {
        1101: {
          courseGrade: {
            percentage: 91.23,
          },
        },
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

  QUnit.module('#loadInitialData()', hooks => {
    hooks.beforeEach(() => {
      server = new FakeServer()
      server.for(urls.userIds).respond({status: 200, body: {user_ids: exampleData.studentIds}})

      server.for(urls.assignmentGroups).respond([
        {status: 200, body: exampleData.assignmentGroups.slice(0, 2)},
        {status: 200, body: exampleData.assignmentGroups.slice(2, 3)},
      ])

      server.for(urls.contextModules).respond([
        {status: 200, body: exampleData.contextModules.slice(0, 2)},
        {status: 200, body: exampleData.contextModules.slice(2, 3)},
      ])

      server.for(urls.gradingPeriodAssignments).respond({
        status: 200,
        body: {grading_period_assignments: exampleData.gradingPeriodAssignments},
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
        {status: 200, body: exampleData.customColumns.slice(2, 3)},
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

    test('loads student content', async () => {
      sinon.spy(dataLoader.studentContentDataLoader, 'load')
      await loadInitialData()
      strictEqual(dataLoader.studentContentDataLoader.load.callCount, 1)
    })

    test('loads custom column data', async () => {
      sinon.spy(dataLoader.customColumnsDataLoader, 'loadCustomColumnsData')
      await loadInitialData()
      strictEqual(dataLoader.customColumnsDataLoader.loadCustomColumnsData.callCount, 1)
    })

    test('loads custom column data after submissions finish loading', async () => {
      sinon.stub(dataLoader.customColumnsDataLoader, 'loadCustomColumnsData').callsFake(() => {
        strictEqual(gradebook.updateSubmissionsLoaded.withArgs(true).callCount, 1)
      })
      await loadInitialData()
    })
  })
})
