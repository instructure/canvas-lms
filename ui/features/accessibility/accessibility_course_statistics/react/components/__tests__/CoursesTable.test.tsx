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
import {CoursesTable} from '../CoursesTable'
import {createMockCourse} from '../../../__tests__/factories'

vi.mock('@instructure/ui-responsive', () => ({
  Responsive: ({
    children,
  }: {
    children: (props: {isMobile: boolean}) => React.ReactNode
    [key: string]: unknown
  }) => <>{children({isMobile: true})}</>,
}))

const defaultProps = {
  courses: [createMockCourse()],
  sort: 'course_name',
  order: 'asc' as const,
  onChangeSort: vi.fn(),
}

describe('CoursesTable', () => {
  describe('stacked (mobile) layout column labels', () => {
    it('shows "Status:" label before the status cell', () => {
      render(<CoursesTable {...defaultProps} />)
      expect(screen.getByTestId('status-cell')).toHaveTextContent(/^Status:/)
    })

    it('shows "Course:" label before the course name cell', () => {
      render(<CoursesTable {...defaultProps} />)
      expect(screen.getByTestId('course-name-cell')).toHaveTextContent(/^Course:/)
    })

    it('shows "Term:" label before the term cell', () => {
      render(<CoursesTable {...defaultProps} />)
      const termCell = screen.getByTestId('term-cell')
      expect(termCell).toHaveTextContent(/^Term:/)
    })

    it('shows "Teacher:" label before the teachers cell', () => {
      render(<CoursesTable {...defaultProps} />)
      const teachersCell = screen.getByTestId('teachers-cell')
      expect(teachersCell).toHaveTextContent(/^Teacher:/)
    })

    it('shows "Sub-Account:" label before the subaccount cell', () => {
      render(<CoursesTable {...defaultProps} />)
      const subaccountCell = screen.getByTestId('subaccount-cell')
      expect(subaccountCell).toHaveTextContent(/^Sub-Account:/)
    })

    it('shows "Issues:" label before the issues cell', () => {
      render(<CoursesTable {...defaultProps} />)
      const issuesCell = screen.getByTestId('issues-cell')
      expect(issuesCell).toHaveTextContent(/^Issues:/)
    })

    it('shows "Resolved:" label before the resolved issues cell', () => {
      render(<CoursesTable {...defaultProps} />)
      const resolvedCell = screen.getByTestId('resolved-issues-cell')
      expect(resolvedCell).toHaveTextContent(/^Resolved:/)
    })

    it('shows "Students:" label before the student count cell', () => {
      render(<CoursesTable {...defaultProps} />)
      const studentCell = screen.getByTestId('student-count-cell')
      expect(studentCell).toHaveTextContent(/^Students:/)
    })

    it('shows "SIS ID:" label before the SIS ID cell when present', () => {
      render(<CoursesTable {...defaultProps} />)
      const sisCell = screen.getByTestId('sis-id-cell')
      expect(sisCell).toHaveTextContent(/^SIS ID:/)
    })
  })
})
