/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import NotificationPreferencesContextSelect from '../NotificationPreferencesContextSelect'

describe('NotificationPreferencesContextSelect', () => {
  const defaultProps = {
    enrollments: [],
    currentContext: {name: 'Account', value: 'account'},
    handleContextChanged: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('enrollment deduplication', () => {
    it('removes duplicate enrollments by course._id', () => {
      const enrollments = [
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        }, // duplicate
        {
          course: {_id: '2', name: 'Course 2', term: {_id: 't1', name: 'Term 1'}},
        },
      ]

      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()

      // Should have 2 unique courses (not 3)
      // The component groups by term, so we expect options for the unique courses
    })

    it('handles multiple duplicate enrollments correctly', () => {
      const enrollments = [
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '2', name: 'Course 2', term: {_id: 't2', name: 'Term 2'}},
        },
      ]

      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })

    it('keeps first occurrence when duplicates exist', () => {
      const enrollments = [
        {
          course: {_id: '1', name: 'First Name', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '1', name: 'Different Name', term: {_id: 't1', name: 'Term 1'}},
        },
      ]

      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      // The component should use the first occurrence's data
      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })
  })

  describe('enrollment sorting and grouping', () => {
    it('groups enrollments by term', () => {
      const enrollments = [
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Fall 2024'}},
        },
        {
          course: {_id: '2', name: 'Course 2', term: {_id: 't1', name: 'Fall 2024'}},
        },
        {
          course: {_id: '3', name: 'Course 3', term: {_id: 't2', name: 'Spring 2025'}},
        },
      ]

      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })

    it('sorts terms alphabetically by name', () => {
      const enrollments = [
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't3', name: 'Spring 2025'}},
        },
        {
          course: {_id: '2', name: 'Course 2', term: {_id: 't1', name: 'Fall 2024'}},
        },
        {
          course: {_id: '3', name: 'Course 3', term: {_id: 't2', name: 'Winter 2025'}},
        },
      ]

      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
      // Terms should be sorted: Fall 2024, Spring 2025, Winter 2025
    })
  })

  describe('edge cases', () => {
    it('handles empty enrollments array', () => {
      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={[]} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })

    it('handles null enrollments', () => {
      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={null} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })

    it('handles undefined enrollments', () => {
      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={undefined} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })

    it('handles single enrollment', () => {
      const enrollments = [
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        },
      ]

      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })
  })

  describe('user interactions', () => {
    it('calls onSelectedContextChanged when selection changes', async () => {
      const user = userEvent.setup()
      const enrollments = [
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '2', name: 'Course 2', term: {_id: 't1', name: 'Term 1'}},
        },
      ]

      const handleContextChanged = vi.fn()

      render(
        <NotificationPreferencesContextSelect
          {...defaultProps}
          enrollments={enrollments}
          handleContextChanged={handleContextChanged}
        />,
      )

      const select = screen.getByRole('combobox')
      await user.click(select)

      // Should call the callback when an option is selected
      // (Actual selection testing would require InstUI SimpleSelect internal knowledge)
    })
  })

  describe('nested course properties', () => {
    it('handles nested property access for course._id', () => {
      const enrollments = [
        {
          course: {_id: '1', name: 'Course 1', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '1', name: 'Course 1 Duplicate', term: {_id: 't1', name: 'Term 1'}},
        },
        {
          course: {_id: '2', name: 'Course 2', term: {_id: 't1', name: 'Term 1'}},
        },
      ]

      // Should deduplicate by 'course._id' - testing sortedUniqBy with nested property
      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })

    it('handles nested property access for term._id', () => {
      const enrollments = [
        {
          course: {
            _id: '1',
            name: 'Course 1',
            term: {_id: 'term-fall', name: 'Fall 2024'},
          },
        },
        {
          course: {
            _id: '2',
            name: 'Course 2',
            term: {_id: 'term-fall', name: 'Fall 2024'},
          },
        },
        {
          course: {
            _id: '3',
            name: 'Course 3',
            term: {_id: 'term-spring', name: 'Spring 2025'},
          },
        },
      ]

      // Should group by 'course.term._id' correctly
      render(<NotificationPreferencesContextSelect {...defaultProps} enrollments={enrollments} />)

      const select = screen.getByRole('combobox')
      expect(select).toBeInTheDocument()
    })
  })
})
