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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import StudentSelect from '../StudentSelect'
import {CourseStudent} from '../../graphql/hooks/useAssignedStudents'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

const {executeQuery} = require('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

const mockStudents: CourseStudent[] = [
  {_id: '1', name: 'Pikachu'},
  {_id: '2', name: 'Squirtle'},
  {_id: '3', name: 'Togepi'},
  {_id: '4', name: 'Snorlax'},
]

describe('StudentSelect', () => {
  const mockOnOptionSelect = jest.fn()
  const mockHandleInputRef = jest.fn()
  const mockClearErrors = jest.fn()

  const defaultProps = {
    label: 'Select Student',
    errors: [],
    filterStudents: new Set<CourseStudent>(),
    onOptionSelect: mockOnOptionSelect,
    handleInputRef: mockHandleInputRef,
    clearErrors: mockClearErrors,
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    jest.clearAllMocks()
  })

  const renderWithMocks = (props = {}) => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    return render(
      <MockedQueryClientProvider client={queryClient}>
        <StudentSelect {...defaultProps} {...props} />
      </MockedQueryClientProvider>,
    )
  }

  describe('Basic rendering', () => {
    it('renders the select component with correct label', () => {
      renderWithMocks()
      expect(screen.getByText('Select Student')).toBeInTheDocument()
    })

    it('renders with custom label', () => {
      renderWithMocks({label: 'Choose Reviewer'})
      expect(screen.getByText('Choose Reviewer')).toBeInTheDocument()
    })

    it('displays error messages when provided', () => {
      const errors = [{text: 'This field is required', type: 'error'}]
      renderWithMocks({errors})
      expect(screen.getByText('This field is required')).toBeInTheDocument()
    })
  })

  describe('Assignment student search', () => {
    it('shows loading spinner while fetching assigned students', async () => {
      // Mock a delayed response
      mockExecuteQuery.mockImplementation(
        () =>
          new Promise(resolve =>
            setTimeout(
              () =>
                resolve({
                  assignment: {
                    assignedStudents: {
                      nodes: [mockStudents[0]],
                    },
                  },
                }),
              100,
            ),
          ),
      )

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Pikachu')

        expect(screen.getByTitle('Loading')).toBeInTheDocument()
      }
    })

    it('displays assigned students in search results', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [mockStudents[0]],
          },
        },
      })

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Pikachu')

        await waitFor(() => {
          expect(screen.getByText('Pikachu')).toBeInTheDocument()
        })
      }
    })

    it('allows selection of assigned student', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [mockStudents[0]],
          },
        },
      })

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Pikachu')

        await waitFor(() => {
          expect(screen.getByText('Pikachu')).toBeInTheDocument()
        })

        await user.click(screen.getByText('Pikachu'))

        expect(mockOnOptionSelect).toHaveBeenCalledWith(mockStudents[0])
        expect(input).toHaveValue('Pikachu')
      }
    })
  })

  describe('Course student search', () => {
    it('displays course students when courseId is provided', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        course: {
          usersConnection: {
            nodes: [mockStudents[1]],
          },
        },
      })

      renderWithMocks({courseId: 'course-456'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Squirtle')

        await waitFor(() => {
          expect(screen.getByText('Squirtle')).toBeInTheDocument()
        })
      }
    })

    it('allows selection of course student', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        course: {
          usersConnection: {
            nodes: [mockStudents[1]],
          },
        },
      })

      renderWithMocks({courseId: 'course-456'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Squirtle')

        await waitFor(() => {
          expect(screen.getByText('Squirtle')).toBeInTheDocument()
        })

        await user.click(screen.getByText('Squirtle'))

        expect(mockOnOptionSelect).toHaveBeenCalledWith(mockStudents[1])
      }
    })
  })

  describe('Student filtering', () => {
    it('filters out students in the filterStudents set', async () => {
      const filterStudents = new Set([mockStudents[0]])

      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: mockStudents,
          },
        },
      })

      renderWithMocks({assignmentId: 'assignment-123', filterStudents})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.click(input)

        await waitFor(() => {
          expect(screen.getByText('Squirtle')).toBeInTheDocument()
          expect(screen.getByText('Togepi')).toBeInTheDocument()
          expect(screen.getByText('Snorlax')).toBeInTheDocument()
          expect(screen.queryByText('Pikachu')).not.toBeInTheDocument()
        })
      }
    })
  })

  describe('Input interactions', () => {
    it('hides options when input loses focus', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [mockStudents[0]],
          },
        },
      })

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Pikachu')
        await user.tab() // Move focus away

        expect(input.getAttribute('aria-expanded')).toBe('false')
      }
    })

    it('clears errors when typing', async () => {
      const errors = [{text: 'This field is required', type: 'error'}]
      renderWithMocks({errors})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'A')

        expect(mockClearErrors).toHaveBeenCalled()
      }
    })

    it('calls handleInputRef with input reference', () => {
      renderWithMocks()
      expect(mockHandleInputRef).toHaveBeenCalled()
    })
  })

  describe('Empty states', () => {
    it('shows "No results" when search returns empty', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [],
          },
        },
      })

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'NonexistentStudent')

        await waitFor(() => {
          expect(screen.getByText('No results')).toBeInTheDocument()
        })
      }
    })

    it('shows empty option when no students are available', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [],
          },
        },
      })

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.click(input)

        await waitFor(() => {
          expect(screen.getByText('No results')).toBeInTheDocument()
        })
      }
    })
  })

  describe('Error handling', () => {
    it('displays error alert when search fails', async () => {
      mockExecuteQuery.mockRejectedValueOnce(new Error('Network error occurred'))

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Error')

        await waitFor(() => {
          expect(
            screen.getByText('An error occurred while searching for Select Student'),
          ).toBeInTheDocument()
        })
      }
    })

    it('does not show options when there is an error', async () => {
      mockExecuteQuery.mockRejectedValueOnce(new Error('Network error occurred'))

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Error')

        await waitFor(() => {
          expect(input.getAttribute('aria-expanded')).toBe('false')
        })
      }
    })

    it('does not show error alert for single character search', async () => {
      mockExecuteQuery.mockRejectedValueOnce(new Error('Network error occurred'))

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'E')

        await new Promise(resolve => setTimeout(resolve, 100))

        expect(
          screen.queryByText('An error occurred while searching for Select Student'),
        ).not.toBeInTheDocument()
      }
    })
  })

  describe('Accessibility', () => {
    it('provides screen reader accessible error messages', () => {
      const errors = [{text: 'This field is required', type: 'error'}]
      renderWithMocks({errors})

      expect(screen.getByText('This field is required')).toBeInTheDocument()
    })

    it('provides screen reader accessible loading state', async () => {
      // Mock a delayed response
      mockExecuteQuery.mockImplementation(
        () =>
          new Promise(resolve =>
            setTimeout(
              () =>
                resolve({
                  assignment: {
                    assignedStudents: {
                      nodes: [mockStudents[0]],
                    },
                  },
                }),
              100,
            ),
          ),
      )

      renderWithMocks({assignmentId: 'assignment-123'})

      const input = screen.getByText('Select Student').querySelector('input')
      if (input) {
        await user.type(input, 'Pikachu')

        expect(screen.getByTitle('Loading')).toBeInTheDocument()
      }
    })
  })
})
