/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const $fixtures =
  document.getElementById('fixtures') ||
  (() => {
    const fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)
    return fixturesDiv
  })()

describe('GradeSummary', () => {
  describe('getSelectedGradingPeriodId', () => {
    beforeEach(() => {
      fakeENV.setup()
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('returns the id of the current grading period', () => {
      ENV.current_grading_period_id = '701'
      expect(GradeSummary.getSelectedGradingPeriodId()).toBe('701')
    })

    it('returns null when the current grading period is "All Grading Periods"', () => {
      ENV.current_grading_period_id = '0'
      expect(GradeSummary.getSelectedGradingPeriodId()).toBeNull()
    })

    it('returns null when there is no current grading period', () => {
      expect(GradeSummary.getSelectedGradingPeriodId()).toBeNull()
    })
  })

  describe('renderSelectMenuGroup', () => {
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

    beforeEach(() => {
      jest.spyOn(GradeSummary, 'getSelectMenuGroupProps').mockReturnValue(props)
      fakeENV.setup({context_asset_string: 'course_42', current_user: {}})
      $fixtures.innerHTML = '<div id="GradeSummarySelectMenuGroup"></div>'
    })

    afterEach(() => {
      fakeENV.teardown()
      jest.restoreAllMocks()
      $fixtures.innerHTML = ''
    })

    it('calls getSelectMenuGroupProps', () => {
      GradeSummary.renderSelectMenuGroup()
      expect(GradeSummary.getSelectMenuGroupProps).toHaveBeenCalledTimes(1)
    })
  })

  describe('getSelectMenuGroupProps', () => {
    beforeEach(() => {
      fakeENV.setup({
        context_asset_string: 'course_42',
        current_user: {},
        courses_with_grades: [],
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('sets assignmentSortOptions to the assignment_sort_options environment variable', () => {
      ENV.assignment_sort_options = [
        ['Assignment Group', 'assignment_group'],
        ['Due Date', 'due_at'],
        ['Name', 'title'],
      ]

      expect(GradeSummary.getSelectMenuGroupProps().assignmentSortOptions).toEqual(
        ENV.assignment_sort_options,
      )
    })

    it('sets courses to camelized version of courses_with_grades', () => {
      ENV.courses_with_grades = [
        {grading_period_set: null, id: '15', nickname: 'Course #1', url: '/courses/15/grades'},
        {grading_period_set: 3, id: '42', nickname: 'Course #2', url: '/courses/42/grades'},
      ]

      const expectedCourses = [
        {gradingPeriodSet: null, id: '15', nickname: 'Course #1', url: '/courses/15/grades'},
        {gradingPeriodSet: 3, id: '42', nickname: 'Course #2', url: '/courses/42/grades'},
      ]

      expect(GradeSummary.getSelectMenuGroupProps().courses).toEqual(expectedCourses)
    })

    it('sets currentUserID to the current user id as set in the environment', () => {
      ENV.current_user = {id: 42}
      expect(GradeSummary.getSelectMenuGroupProps().currentUserID).toBe(42)
    })

    it('sets gradingPeriods to the grading period data passed in the environment', () => {
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

      expect(GradeSummary.getSelectMenuGroupProps().gradingPeriods).toEqual(ENV.grading_periods)
    })

    it('sets gradingPeriods to an empty array if there is no grading period data in the environment', () => {
      expect(GradeSummary.getSelectMenuGroupProps().gradingPeriods).toEqual([])
    })

    it('sets selectedAssignmentSortOrder to the current_assignment_sort_order environment variable', () => {
      ENV.current_assignment_sort_order = 'due_at'
      expect(GradeSummary.getSelectMenuGroupProps().selectedAssignmentSortOrder).toBe(
        ENV.current_assignment_sort_order,
      )
    })

    it('sets selectedCourseID to the context id', () => {
      expect(GradeSummary.getSelectMenuGroupProps().selectedCourseID).toBe('42')
    })

    it('sets selectedGradingPeriodID to the current_grading_period_id environment variable', () => {
      ENV.current_grading_period_id = '3'
      expect(GradeSummary.getSelectMenuGroupProps().selectedGradingPeriodID).toBe(
        ENV.current_grading_period_id,
      )
    })

    it('sets selectedStudentID to the student_id environment variable', () => {
      ENV.student_id = '66'
      expect(GradeSummary.getSelectMenuGroupProps().selectedStudentID).toBe(ENV.student_id)
    })

    it('sets students to the students environment variable', () => {
      ENV.students = [
        {id: 42, name: 'Abel'},
        {id: 43, name: 'Baker'},
      ]
      expect(GradeSummary.getSelectMenuGroupProps().students).toEqual(ENV.students)
    })
  })

  describe('SubmissionCommentsTray', () => {
    beforeEach(() => {
      fakeENV.setup()
      ENV.submissions = [
        {
          assignment_id: '22',
          submission_comments: [],
          assignment_url: '/courses/1/assignments/22',
        },
      ]

      $fixtures.innerHTML = `
        <div id="comments_thread_22">
          <button data-assignment-id="22" class="comments-button">Comments</button>
        </div>
        <div id="submission_22"></div>
      `

      // Reset the store state before each test
      useStore.setState({
        submissionTrayOpen: false,
        submissionTrayAssignmentId: undefined,
        submissionCommentsTray: {attempts: {}},
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      $fixtures.innerHTML = ''
      jest.restoreAllMocks()
    })

    describe('handleSubmissionsCommentTray', () => {
      it('should open tray with no prior assignmentId', () => {
        jest.spyOn(useStore, 'setState').mockClear()
        jest.spyOn($.fn, 'addClass')
        jest.spyOn($.fn, 'removeClass')

        GradeSummary.handleSubmissionsCommentTray('22')

        expect(useStore.setState).toHaveBeenCalledWith({
          submissionCommentsTray: {attempts: {}},
          submissionTrayOpen: true,
          submissionTrayAssignmentId: '22',
          submissionTrayAssignmentUrl: '/courses/1/assignments/22',
        })

        expect($('#comments_thread_22').hasClass('comment_thread_show_print')).toBe(true)
        expect($('#submission_22').hasClass('selected-assignment')).toBe(true)
      })

      it('should close tray when clicking the same assignment twice', () => {
        jest.spyOn(useStore, 'setState').mockClear()
        jest.spyOn($.fn, 'addClass')
        jest.spyOn($.fn, 'removeClass')

        // Set initial state
        useStore.setState({
          submissionTrayAssignmentId: '22',
          submissionTrayOpen: true,
          submissionCommentsTray: {attempts: {}},
        })

        GradeSummary.handleSubmissionsCommentTray('22')

        expect(useStore.setState).toHaveBeenCalledWith({
          submissionTrayOpen: false,
          submissionTrayAssignmentId: undefined,
        })

        expect($('#comments_thread_22').hasClass('comment_thread_show_print')).toBe(false)
        expect($('#submission_22').hasClass('selected-assignment')).toBe(false)
      })

      it('should switch from one assignment to another', () => {
        // Add second assignment to ENV and DOM
        ENV.submissions.push({
          assignment_id: '23',
          submission_comments: [],
          assignment_url: '/courses/1/assignments/23',
        })

        $fixtures.innerHTML += `
          <div id="comments_thread_23">
            <button data-assignment-id="23" class="comments-button">Comments</button>
          </div>
          <div id="submission_23"></div>
        `

        jest.spyOn(useStore, 'setState').mockClear()
        jest.spyOn($.fn, 'addClass')
        jest.spyOn($.fn, 'removeClass')

        // Set initial state
        useStore.setState({
          submissionTrayAssignmentId: '22',
          submissionTrayOpen: true,
          submissionCommentsTray: {attempts: {}},
        })

        // Switch to assignment 23
        GradeSummary.handleSubmissionsCommentTray('23')

        expect(useStore.setState).toHaveBeenCalledWith({
          submissionCommentsTray: {attempts: {}},
          submissionTrayOpen: true,
          submissionTrayAssignmentId: '23',
          submissionTrayAssignmentUrl: '/courses/1/assignments/23',
        })

        expect($('#comments_thread_22').hasClass('comment_thread_show_print')).toBe(false)
        expect($('#submission_22').hasClass('selected-assignment')).toBe(false)
        expect($('#comments_thread_23').hasClass('comment_thread_show_print')).toBe(true)
        expect($('#submission_23').hasClass('selected-assignment')).toBe(true)
      })

      it('should handle comments with attempts', () => {
        // Reset ENV.submissions to ensure clean state
        ENV.submissions = [
          {
            assignment_id: '22',
            submission_comments: [
              {id: 1, attempt: 1, comment: 'First attempt'},
              {id: 2, attempt: 1, comment: 'Also first attempt'},
              {id: 3, attempt: 2, comment: 'Second attempt'},
              {id: 4, attempt: null, comment: 'No attempt specified'},
            ],
            assignment_url: '/courses/1/assignments/22',
          },
        ]

        jest.spyOn(useStore, 'setState').mockClear()

        GradeSummary.handleSubmissionsCommentTray('22')

        expect(useStore.setState).toHaveBeenCalledWith({
          submissionCommentsTray: {
            attempts: {
              1: [
                {id: 1, attempt: 1, comment: 'First attempt'},
                {id: 2, attempt: 1, comment: 'Also first attempt'},
                {id: 4, attempt: null, comment: 'No attempt specified'},
              ],
              2: [{id: 3, attempt: 2, comment: 'Second attempt'}],
            },
          },
          submissionTrayOpen: true,
          submissionTrayAssignmentId: '22',
          submissionTrayAssignmentUrl: '/courses/1/assignments/22',
        })
      })

      it('should handle non-existent assignment', () => {
        jest.spyOn(useStore, 'setState').mockClear()
        jest.spyOn(console, 'error').mockImplementation(() => {})

        expect(() => {
          GradeSummary.handleSubmissionsCommentTray('999')
        }).toThrow()

        expect(useStore.setState).not.toHaveBeenCalled()
      })
    })
  })
})
