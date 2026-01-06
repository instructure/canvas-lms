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
import {createMockCourse, createMockTeacher} from '../../../__tests__/factories'

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
      const {container} = render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      // Find the cell in the SIS ID column position
      const cells = container.querySelectorAll('td')
      const sisIdCell = cells[2] // Status, Name, SIS ID
      expect(sisIdCell?.textContent).toBe('')
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
      const {container} = render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const cells = container.querySelectorAll('td')
      const termCell = cells[3] // Status, Name, SIS ID, Term
      expect(termCell?.textContent).toBe('')
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
      const {container} = render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const cells = container.querySelectorAll('td')
      const teachersCell = cells[4] // Status, Name, SIS ID, Term, Teachers
      expect(teachersCell?.textContent).toBe('')
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
      expect(link).toHaveAttribute('href', '/accounts/5')
    })

    it('renders empty string when subaccount is missing', () => {
      const course = createMockCourse({subaccount_id: undefined, subaccount_name: undefined})
      const {container} = render(
        <table>
          <tbody>
            <CoursesTableRow course={course} showSISIds={true} />
          </tbody>
        </table>,
      )

      const cells = container.querySelectorAll('td')
      const subaccountCell = cells[5] // Status, Name, SIS ID, Term, Teachers, Subaccount
      expect(subaccountCell?.textContent).toBe('')
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
})
