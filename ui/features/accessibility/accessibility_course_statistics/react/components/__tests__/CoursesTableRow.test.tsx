/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {CoursesTableRow} from '../CoursesTableRow'
import {
  createMockCourse,
  createMockTeacher,
  createMockAccessibilityCourseStatistic,
} from '../../../__tests__/factories'

describe('CoursesTableRow', () => {
  describe('Status icons', () => {
    it('renders Published icon for available courses', () => {
      const course = createMockCourse({workflow_state: 'available'})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const publishedElements = screen.getAllByText('Published')
      expect(publishedElements.length).toBeGreaterThan(0)
    })

    it('renders Unpublished icon for unpublished courses', () => {
      const course = createMockCourse({workflow_state: 'unpublished'})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const unpublishedElements = screen.getAllByText('Unpublished')
      expect(unpublishedElements.length).toBeGreaterThan(0)
    })

    it('renders Concluded icon for completed courses', () => {
      const course = createMockCourse({workflow_state: 'completed'})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const concludedElements = screen.getAllByText('Concluded')
      expect(concludedElements.length).toBeGreaterThan(0)
    })
  })

  describe('Course name', () => {
    it('renders course name as a link', () => {
      const course = createMockCourse()
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const link = screen.getByRole('link', {name: course.name})
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', `/courses/${course.id}`)
    })
  })

  describe('SIS ID column', () => {
    it('shows SIS ID when showSISIds is true', () => {
      const course = createMockCourse()
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('SIS-101')).toBeInTheDocument()
    })

    it('hides SIS ID column when showSISIds is false', () => {
      const course = createMockCourse()
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={false} />
          </tbody>
        </table>,
      )

      expect(screen.queryByText('SIS-101')).not.toBeInTheDocument()
    })

    it('renders empty string when SIS ID is missing', () => {
      const course = createMockCourse({sis_course_id: undefined})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const sisIdCell = screen.getByTestId('sis-id-cell')
      expect(sisIdCell).toHaveTextContent('')
    })
  })

  describe('Term', () => {
    it('displays term name', () => {
      const course = createMockCourse()
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('Fall 2026')).toBeInTheDocument()
    })

    it('renders empty string when term is missing', () => {
      const course = createMockCourse({term: undefined})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const termCell = screen.getByTestId('term-cell')
      expect(termCell).toHaveTextContent('')
    })
  })

  describe('Teachers', () => {
    it('displays first 2 teachers with avatars', () => {
      const course = createMockCourse()
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByRole('link', {name: /John Doe/})).toBeInTheDocument()
      expect(screen.getByRole('link', {name: /Jane Smith/})).toBeInTheDocument()
    })

    it('shows "Show More" link when there are more than 2 teachers', () => {
      const course = createMockCourse({
        teachers: [
          createMockTeacher({id: '10', display_name: 'Teacher 1'}),
          createMockTeacher({id: '11', display_name: 'Teacher 2'}),
          createMockTeacher({id: '12', display_name: 'Teacher 3'}),
        ],
      })

      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByRole('button', {name: 'Show More'})).toBeInTheDocument()
      expect(screen.queryByText('Teacher 3')).not.toBeInTheDocument()
    })

    it('expands to show all teachers when "Show More" is clicked', async () => {
      const user = userEvent.setup()
      const course = createMockCourse({
        teachers: [
          createMockTeacher({id: '10', display_name: 'Teacher 1'}),
          createMockTeacher({id: '11', display_name: 'Teacher 2'}),
          createMockTeacher({id: '12', display_name: 'Teacher 3'}),
        ],
      })

      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const showMoreButton = screen.getByRole('button', {name: 'Show More'})
      await user.click(showMoreButton)

      expect(screen.getByText('Teacher 3')).toBeInTheDocument()
      expect(screen.queryByRole('button', {name: 'Show More'})).not.toBeInTheDocument()
    })

    it('renders empty cell when no teachers', () => {
      const course = createMockCourse({teachers: undefined})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const teachersCell = screen.getByTestId('teachers-cell')
      expect(teachersCell).toHaveTextContent('')
    })
  })

  describe('Subaccount', () => {
    it('renders subaccount as a link', () => {
      const course = createMockCourse()
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const link = screen.getByRole('link', {name: 'College of Engineering'})
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/accounts/5/accessibility')
    })

    it('renders empty string when subaccount is missing', () => {
      const course = createMockCourse({subaccount_id: undefined, subaccount_name: undefined})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const subaccountCell = screen.getByTestId('subaccount-cell')
      expect(subaccountCell).toHaveTextContent('')
    })
  })

  describe('Student count', () => {
    it('displays student count', () => {
      const course = createMockCourse()
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('25')).toBeInTheDocument()
    })

    it('defaults to 0 when student count is undefined', () => {
      const course = createMockCourse({total_students: undefined})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('0')).toBeInTheDocument()
    })
  })

  describe('Issues column', () => {
    it('shows "No report" when statistic is undefined', () => {
      const course = createMockCourse({accessibility_course_statistic: undefined})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('No report')).toBeInTheDocument()
    })

    it('shows "No report" when statistic is null', () => {
      const course = createMockCourse({accessibility_course_statistic: null})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('No report')).toBeInTheDocument()
    })

    it('shows "No report" when workflow_state is initialized', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: 0,
          workflow_state: 'initialized',
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('No report')).toBeInTheDocument()
    })

    it('shows "No report" when workflow_state is deleted', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          workflow_state: 'deleted',
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('No report')).toBeInTheDocument()
    })

    it('shows spinner and "Checking..." when workflow_state is in_progress', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: null,
          workflow_state: 'in_progress',
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const checkingElements = screen.getAllByText('Checking...')
      expect(checkingElements.length).toBeGreaterThan(0)
    })

    it('shows spinner and "Checking..." when workflow_state is queued', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: null,
          workflow_state: 'queued',
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const checkingElements = screen.getAllByText('Checking...')
      expect(checkingElements.length).toBeGreaterThan(0)
    })

    it('shows published icon when workflow_state is active and active_issue_count is 0', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: 0,
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const noIssuesElements = screen.getAllByText('No issues')
      expect(noIssuesElements.length).toBeGreaterThan(0)
    })

    it('shows published icon when workflow_state is active and active_issue_count is null', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: null,
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const noIssuesElements = screen.getAllByText('No issues')
      expect(noIssuesElements.length).toBeGreaterThan(0)
    })

    it('shows published icon when workflow_state is active and active_issue_count is undefined', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: undefined as any,
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const noIssuesElements = screen.getAllByText('No issues')
      expect(noIssuesElements.length).toBeGreaterThan(0)
    })

    it('shows badge with count when workflow_state is active and active_issue_count > 0', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: 5,
        }),
      })
      const {container} = render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const badge = container.querySelector('[class*="badge"]')
      expect(badge).toBeInTheDocument()
      expect(badge?.textContent).toBe('5')
    })

    it('shows "Failed scan" when workflow_state is failed', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          active_issue_count: null,
          workflow_state: 'failed',
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      expect(screen.getByText('Failed scan')).toBeInTheDocument()
    })
  })

  describe('Resolved Issues column', () => {
    it('shows empty cell when statistic is undefined', () => {
      const course = createMockCourse({accessibility_course_statistic: undefined})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const resolvedIssuesCell = screen.getByTestId('resolved-issues-cell')
      expect(resolvedIssuesCell).toHaveTextContent('')
    })

    it('shows empty cell when statistic is null', () => {
      const course = createMockCourse({accessibility_course_statistic: null})
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const resolvedIssuesCell = screen.getByTestId('resolved-issues-cell')
      expect(resolvedIssuesCell).toHaveTextContent('')
    })

    it('shows empty cell when resolved_issue_count is null', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          resolved_issue_count: null,
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const resolvedIssuesCell = screen.getByTestId('resolved-issues-cell')
      expect(resolvedIssuesCell).toHaveTextContent('')
    })

    it('shows empty cell when resolved_issue_count is 0', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          resolved_issue_count: 0,
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const resolvedIssuesCell = screen.getByTestId('resolved-issues-cell')
      expect(resolvedIssuesCell).toHaveTextContent('')
    })

    it('shows success badge with count when resolved_issue_count > 0', () => {
      const course = createMockCourse({
        accessibility_course_statistic: createMockAccessibilityCourseStatistic({
          resolved_issue_count: 3,
        }),
      })
      render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const resolvedIssuesCell = screen.getByTestId('resolved-issues-cell')
      expect(resolvedIssuesCell).toHaveTextContent('3')
    })
  })
})
