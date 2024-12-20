/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import _ from 'lodash'

import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import GradeSummary from '../index'
import useStore from '../../react/stores'

const $fixtures = $('#fixtures')

function commonTeardown() {
  fakeENV.teardown()
  $fixtures.html('')
}

QUnit.module('GradeSummary', () => {
  QUnit.module('.getSelectedGradingPeriodId', hooks => {
    hooks.beforeEach(() => {
      fakeENV.setup()
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
    })

    test('returns the id of the current grading period', () => {
      ENV.current_grading_period_id = '701'

      strictEqual(GradeSummary.getSelectedGradingPeriodId(), '701')
    })

    test('returns null when the current grading period is "All Grading Periods"', () => {
      ENV.current_grading_period_id = '0'

      strictEqual(GradeSummary.getSelectedGradingPeriodId(), null)
    })

    test('returns null when there is no current grading period', () => {
      strictEqual(GradeSummary.getSelectedGradingPeriodId(), null)
    })
  })

  QUnit.module('#renderSelectMenuGroup', hooks => {
    const props = {
      assignmentSortOptions: [],
      courses: [],
      currentUserID: '42',
      displayPageContent() {},
      goToURL() {},
      gradingPeriods: [],
      saveAssignmentOrder() {},
      selectedAssignmentSortOrder: '1',
      selectedCourseID: '2',
      selectedGradingPeriodID: '3',
      selectedStudentID: '4',
      students: [],
    }

    hooks.beforeEach(() => {
      sinon.stub(GradeSummary, 'getSelectMenuGroupProps').returns(props)
      fakeENV.setup({context_asset_string: 'course_42', current_user: {}})
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
      GradeSummary.getSelectMenuGroupProps.restore()
    })

    test('calls getSelectMenuGroupProps', () => {
      $('#fixtures').html('<div id="GradeSummarySelectMenuGroup"></div>')
      GradeSummary.renderSelectMenuGroup()

      strictEqual(GradeSummary.getSelectMenuGroupProps.callCount, 1)
    })
  })

  QUnit.module('#getSelectMenuGroupProps', hooks => {
    hooks.beforeEach(() => {
      fakeENV.setup({
        context_asset_string: 'course_42',
        current_user: {},
        courses_with_grades: [],
      })
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
    })

    test('sets assignmentSortOptions to the assignment_sort_options environment variable', () => {
      ENV.assignment_sort_options = [
        ['Assignment Group', 'assignment_group'],
        ['Due Date', 'due_at'],
        ['Name', 'title'],
      ]

      deepEqual(
        GradeSummary.getSelectMenuGroupProps().assignmentSortOptions,
        ENV.assignment_sort_options
      )
    })

    test('sets courses to camelized version of courses_with_grades', () => {
      ENV.courses_with_grades = [
        {grading_period_set: null, id: '15', nickname: 'Course #1', url: '/courses/15/grades'},
        {grading_period_set: 3, id: '42', nickname: 'Course #2', url: '/courses/42/grades'},
      ]

      const expectedCourses = [
        {gradingPeriodSet: null, id: '15', nickname: 'Course #1', url: '/courses/15/grades'},
        {gradingPeriodSet: 3, id: '42', nickname: 'Course #2', url: '/courses/42/grades'},
      ]

      deepEqual(GradeSummary.getSelectMenuGroupProps().courses, expectedCourses)
    })

    test('sets currentUserID to the current user id as set in the environment', () => {
      ENV.current_user = {id: 42}

      strictEqual(GradeSummary.getSelectMenuGroupProps().currentUserID, 42)
    })

    test('sets gradingPeriods to the grading period data passed in the environment', () => {
      ENV.grading_periods = [
        {
          id: '6',
          close_date: '2017-09-01T05:59:59Z',
          end_date: '2017-09-01T05:59:59Z',
          is_closed: true,
          is_last: false,
          permissions: {
            create: false,
            delete: false,
            read: true,
            update: false,
          },
          start_date: '2017-08-01T06:00:00Z',
          title: 'Summer 2017',
          weight: 10,
        },
      ]

      deepEqual(GradeSummary.getSelectMenuGroupProps().gradingPeriods, ENV.grading_periods)
    })

    test('sets gradingPeriods to an empty array if there is no grading period data in the environment', () => {
      deepEqual(GradeSummary.getSelectMenuGroupProps().gradingPeriods, [])
    })

    test('sets selectedAssignmentSortOrder to the current_assignment_sort_order environment variable', () => {
      ENV.current_assignment_sort_order = 'due_at'

      strictEqual(
        GradeSummary.getSelectMenuGroupProps().selectedAssignmentSortOrder,
        ENV.current_assignment_sort_order
      )
    })

    test('sets selectedCourseID to the context id', () => {
      strictEqual(GradeSummary.getSelectMenuGroupProps().selectedCourseID, '42')
    })

    test('sets selectedGradingPeriodID to the current_grading_period_id environment variable', () => {
      ENV.current_grading_period_id = '3'

      strictEqual(
        GradeSummary.getSelectMenuGroupProps().selectedGradingPeriodID,
        ENV.current_grading_period_id
      )
    })

    test('sets selectedStudentID to the student_id environment variable', () => {
      ENV.student_id = '66'

      strictEqual(GradeSummary.getSelectMenuGroupProps().selectedStudentID, ENV.student_id)
    })

    test('sets students to the students environment variable', () => {
      ENV.students = [
        {id: 42, name: 'Abel'},
        {id: 43, name: 'Baker'},
      ]

      deepEqual(GradeSummary.getSelectMenuGroupProps().students, ENV.students)
    })
  })

  QUnit.module('SubmissionCommentsTray', hooks => {
    hooks.beforeEach(() => {
      ENV.submissions = [
        {
          assignment_id: '22',
          submission_comments: [
            {
              id: '2',
              attempt: null,
              author_name: 'test user',
              created_at: '2022-09-27T16:34:17Z',
              edited_at: '2022-09-27T19:32:02Z',
              comment: 'Lorem ipsum dolor sit amet',
              display_updated_at: 'Sep 27 at 1:32pm',
            },
            {
              id: '3',
              attempt: 0,
              author_name: 'test user',
              created_at: '2022-09-27T19:32:17Z',
              edited_at: null,
              comment: 'this is a test comment 2',
              display_updated_at: 'Sep 27 at 1:32pm',
            },
            {
              id: '4',
              attempt: 1,
              author_name: 'test user',
              created_at: '2022-09-27T19:32:17Z',
              edited_at: null,
              comment: 'this is a test comment 2',
              display_updated_at: 'Sep 27 at 1:32pm',
            },
            {
              id: '5',
              attempt: 2,
              author_name: 'test user',
              created_at: '2022-09-27T19:32:17Z',
              edited_at: null,
              comment: 'this is a test comment 2',
              display_updated_at: 'Sep 27 at 1:32pm',
            },
            {
              id: '6',
              attempt: 3,
              author_name: 'test user',
              created_at: '2022-09-27T19:32:17Z',
              edited_at: null,
              comment: 'this is a test comment 2',
              display_updated_at: 'Sep 27 at 1:32pm',
            },
          ],
          excused: false,
          score: 10,
          workflow_state: 'graded',
        },
        {
          assignment_id: '17',
          submission_comments: [
            {
              id: '1',
              attempt: 4,
              author_name: 'test user 2',
              created_at: '2022-09-27T16:34:00Z',
              edited_at: null,
              comment: 'This is another test comment',
              display_updated_at: 'Sep 27 at 10:34am',
            },
          ],
          excused: false,
          score: 19,
          workflow_state: 'graded',
          assignment_url: 'assignment.url',
        },
      ]
    })
    hooks.afterEach(() => {
      commonTeardown()
    })
    const expectedCommentTrayProps = {
      attempts: {
        4: [
          {
            id: '1',
            attempt: 4,
            author_name: 'test user 2',
            created_at: '2022-09-27T16:34:00Z',
            edited_at: null,
            comment: 'This is another test comment',
            display_updated_at: 'Sep 27 at 10:34am',
          },
        ],
      },
      assignmentUrl: 'assignment.url',
    }
    QUnit.module('getSubmissionCommentsTrayProps', () => {
      test('gets props getSubmissionCommentsTrayProps for correct assignmentId', () => {
        const commentTrayProps = GradeSummary.getSubmissionCommentsTrayProps('17')
        deepEqual(commentTrayProps, expectedCommentTrayProps)
      })

      test('it sets attempts less than 1 or null to the value 1', () => {
        const commentTrayProps = GradeSummary.getSubmissionCommentsTrayProps('22')
        const {attempts} = commentTrayProps
        equal(attempts[1].length, 3)
        equal(attempts[2].length, 1)
        equal(attempts[3].length, 1)
      })
    })
    QUnit.module('handleSubmissionsCommentTray', () => {
      test('should open tray with no prior assignmentId', () => {
        sandbox.spy(useStore, 'setState')
        sandbox.spy($.fn, 'addClass')
        sandbox.spy($.fn, 'removeClass')
        GradeSummary.handleSubmissionsCommentTray('17')
        equal(useStore.setState.callCount, 1)
        const [value] = useStore.setState.getCall(0).args
        const {attempts} = expectedCommentTrayProps
        const expectedState = {
          submissionCommentsTray: {attempts},
          submissionTrayOpen: true,
          submissionTrayAssignmentId: '17',
          submissionTrayAssignmentUrl: 'assignment.url',
        }
        deepEqual(value, expectedState)
        equal($.fn.addClass.callCount, 2)
        equal($.fn.removeClass.callCount, 2)
      })
      test('should open tray with different prior assignmentId', () => {
        sandbox.stub(useStore, 'getState').returns({
          submissionTrayAssignmentId: '22',
          submissionTrayOpen: false,
          submissionTrayAssignmentUrl: 'testUr',
        })
        sandbox.spy(useStore, 'setState')
        sandbox.spy($.fn, 'addClass')
        sandbox.spy($.fn, 'removeClass')
        GradeSummary.handleSubmissionsCommentTray('17')

        equal(useStore.setState.callCount, 1)
        const [value] = useStore.setState.getCall(0).args
        const {attempts} = expectedCommentTrayProps
        const expectedState = {
          submissionCommentsTray: {attempts},
          submissionTrayOpen: true,
          submissionTrayAssignmentId: '17',
          submissionTrayAssignmentUrl: 'assignment.url',
        }
        deepEqual(value, expectedState)
        equal($.fn.addClass.callCount, 2)
        equal($.fn.removeClass.callCount, 2)
      })
      test('should close tray if same assignmentId and tray is open', () => {
        sandbox.stub(useStore, 'getState').returns({
          submissionTrayAssignmentId: '17',
          submissionTrayOpen: true,
          submissionTrayAssignmentUrl: 'testUr',
        })
        sandbox.spy(useStore, 'setState')
        sandbox.spy($.fn, 'addClass')
        sandbox.spy($.fn, 'removeClass')
        GradeSummary.handleSubmissionsCommentTray('17')

        equal(useStore.setState.callCount, 1)
        const [value] = useStore.setState.getCall(0).args
        const expectedState = {
          submissionTrayOpen: false,
          submissionTrayAssignmentId: undefined,
        }
        deepEqual(value, expectedState)
        equal($.fn.addClass.callCount, 0)
        equal($.fn.removeClass.callCount, 2)
      })
      test('should keep tray open and switch assignmentId for different assignment and tray open', () => {
        sandbox.stub(useStore, 'getState').returns({
          submissionTrayAssignmentId: '22',
          submissionTrayOpen: true,
          submissionTrayAssignmentUrl: 'testUr',
        })
        sandbox.spy(useStore, 'setState')
        sandbox.spy($.fn, 'addClass')
        sandbox.spy($.fn, 'removeClass')
        GradeSummary.handleSubmissionsCommentTray('17')

        equal(useStore.setState.callCount, 1)
        const [value] = useStore.setState.getCall(0).args
        const {attempts} = expectedCommentTrayProps
        const expectedState = {
          submissionCommentsTray: {attempts},
          submissionTrayOpen: true,
          submissionTrayAssignmentId: '17',
          submissionTrayAssignmentUrl: 'assignment.url',
        }
        deepEqual(value, expectedState)
        equal($.fn.addClass.callCount, 2)
        equal($.fn.removeClass.callCount, 2)
      })
    })
  })
})
