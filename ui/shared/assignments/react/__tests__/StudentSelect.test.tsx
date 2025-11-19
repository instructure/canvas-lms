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
import {CourseStudent} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

jest.mock('../../graphql/hooks/useAssignedStudents', () => ({
  useAssignedStudents: jest.fn(),
}))

const {useAssignedStudents} = require('../../graphql/hooks/useAssignedStudents')
const mockUseAssignedStudents = useAssignedStudents as jest.MockedFunction<
  typeof useAssignedStudents
>

const mockStudents: CourseStudent[] = [
  {_id: '1', name: 'Pikachu', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '2', name: 'Squirtle', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '3', name: 'Togepi', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '4', name: 'Snorlax', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
]

const mockStudentsWithPeerReviewStatus: CourseStudent[] = [
  {
    _id: '1',
    name: 'Pikachu',
    peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 3},
  },
  {
    _id: '2',
    name: 'Squirtle',
    peerReviewStatus: {mustReviewCount: 2, completedReviewsCount: 1},
  },
  {
    _id: '3',
    name: 'Togepi',
    peerReviewStatus: {mustReviewCount: 3, completedReviewsCount: 0},
  },
  {
    _id: '4',
    name: 'Snorlax',
    peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 1},
  },
]

describe('StudentSelect', () => {
  const mockOnOptionSelect = jest.fn()
  const mockHandleInputRef = jest.fn()
  const mockClearErrors = jest.fn()

  const defaultProps = {
    inputId: 'test-student-select',
    label: 'Select Student',
    errors: [],
    selectedStudent: null,
    filteredStudents: [],
    onOptionSelect: mockOnOptionSelect,
    handleInputRef: mockHandleInputRef,
    clearErrors: mockClearErrors,
    requiredPeerReviewsCount: 2,
    assignmentId: '123',
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    jest.clearAllMocks()

    mockUseAssignedStudents.mockReturnValue({
      students: [],
      loading: false,
      error: null,
    })
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

    it('renders with selectedStudent prop populated', () => {
      const selectedStudent = mockStudents[0]
      renderWithMocks({selectedStudent})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      expect(input).toHaveValue('Pikachu')
    })
  })

  describe('Selected student prop', () => {
    it('input renders given selected student', () => {
      mockUseAssignedStudents.mockReturnValue({
        students: mockStudents,
        loading: false,
        error: null,
      })

      renderWithMocks({selectedStudent: mockStudents[0]})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      expect(input).toHaveValue('Pikachu')
    })

    it('clears selection when user types different value', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: mockStudents,
        loading: false,
        error: null,
      })

      renderWithMocks({
        selectedStudent: mockStudents[0],
      })

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      expect(input).toHaveValue('Pikachu')

      await user.clear(input!)
      await user.type(input!, 'Different Name')

      expect(mockOnOptionSelect).toHaveBeenLastCalledWith(undefined)
    })
  })

  describe('Student filtering', () => {
    it('filters out students in the filteredStudents array', async () => {
      const filteredStudents = [mockStudents[0]]

      mockUseAssignedStudents.mockReturnValue({
        students: mockStudents,
        loading: false,
        error: null,
      })

      renderWithMocks({filteredStudents})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()

      await user.type(input!, 'St')

      await waitFor(() => {
        expect(screen.getByText('Squirtle')).toBeInTheDocument()
        expect(screen.getByText('Snorlax')).toBeInTheDocument()
        expect(screen.queryByText('Pikachu')).not.toBeInTheDocument()
      })
    })

    it('shows all students when filteredStudents is empty', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: mockStudents,
        loading: false,
        error: null,
      })

      renderWithMocks({filteredStudents: []})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()

      await user.type(input!, 'St')

      await waitFor(() => {
        expect(screen.getByText('Squirtle')).toBeInTheDocument()
        expect(screen.getByText('Snorlax')).toBeInTheDocument()
      })
    })
  })

  describe('Assignment student search', () => {
    it('shows loading spinner while fetching assigned students', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [],
        loading: true,
        error: null,
      })

      renderWithMocks({})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'Pikachu')

      expect(screen.getByTestId('loading-option')).toBeInTheDocument()
    })

    it('displays assigned students in search results', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [mockStudents[0]],
        loading: false,
        error: null,
      })

      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()

      await user.type(input!, 'Pikachu')

      await waitFor(() => {
        expect(screen.getByText('Pikachu')).toBeInTheDocument()
      })
    })

    it('allows selection of assigned student', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [mockStudents[0]],
        loading: false,
        error: null,
      })

      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()

      await user.type(input!, 'Pikachu')

      await waitFor(() => {
        expect(screen.getByText('Pikachu')).toBeInTheDocument()
      })

      await user.click(screen.getByText('Pikachu'))

      expect(mockOnOptionSelect).toHaveBeenCalledWith(mockStudents[0])
      expect(input).toHaveValue('Pikachu')
    })
  })

  describe('Input interactions', () => {
    it('hides options when input loses focus', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [mockStudents[0]],
        loading: false,
        error: null,
      })

      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()

      await user.type(input!, 'Pikachu')
      await user.tab()

      expect(input!.getAttribute('aria-expanded')).toBe('false')
    })

    it('clears errors when typing', async () => {
      const errors = [{text: 'This field is required', type: 'error'}]
      renderWithMocks({errors})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'A')

      expect(mockClearErrors).toHaveBeenCalled()
    })

    it('calls handleInputRef with input reference', () => {
      renderWithMocks()
      expect(mockHandleInputRef).toHaveBeenCalled()
    })
  })

  describe('Empty states', () => {
    it('shows "No results" when search returns empty', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [],
        loading: false,
        error: null,
      })

      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'NonexistentStudent')

      await waitFor(() => {
        expect(screen.getByText('No results')).toBeInTheDocument()
      })
    })

    it('shows empty option when no students are available', async () => {
      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'xx')

      await waitFor(() => {
        expect(screen.getByText('No results')).toBeInTheDocument()
      })
    })
  })

  describe('Error handling', () => {
    it('displays error alert when search fails', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [],
        loading: false,
        error: new Error('Network error occurred'),
      })

      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'Error')

      await waitFor(() => {
        expect(
          screen.getByText('An error occurred while searching for Select Student'),
        ).toBeInTheDocument()
      })
    })

    it('does not show options when there is an error', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [],
        loading: false,
        error: new Error('Network error occurred'),
      })

      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'Error')

      await waitFor(() => {
        expect(input!.getAttribute('aria-expanded')).toBe('false')
      })
    })

    it('does not show error alert for single character search', async () => {
      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'E')

      expect(
        screen.queryByText('An error occurred while searching for Select Student'),
      ).not.toBeInTheDocument()
    })
  })

  describe('Accessibility', () => {
    it('provides screen reader accessible error messages', () => {
      const errors = [{text: 'This field is required', type: 'error'}]
      renderWithMocks({errors})

      expect(screen.getByText('This field is required')).toBeInTheDocument()
    })

    it('provides screen reader accessible loading state', async () => {
      mockUseAssignedStudents.mockReturnValue({
        students: [],
        loading: true,
        error: null,
      })

      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'Pikachu')

      expect(screen.getByTitle('Loading')).toBeInTheDocument()
    })
  })

  describe('Search term validation', () => {
    it('shows error message for single character search', async () => {
      renderWithMocks({delay: 0})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'A')

      await waitFor(() => {
        expect(
          screen.getByText('Search term must be at least 2 characters long'),
        ).toBeInTheDocument()
      })
    })

    it('clears single character error when typing more characters', async () => {
      renderWithMocks({delay: 0})

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'A')

      await waitFor(() => {
        expect(
          screen.getByText('Search term must be at least 2 characters long'),
        ).toBeInTheDocument()
      })

      await user.type(input!, 'B')

      await waitFor(() => {
        expect(
          screen.queryByText('Search term must be at least 2 characters long'),
        ).not.toBeInTheDocument()
      })
    })

    it('does not show options when search term is only one character', async () => {
      renderWithMocks()

      const input = document.getElementById('test-student-select')
      expect(input).not.toBeNull()
      await user.type(input!, 'A')

      expect(input!.getAttribute('aria-expanded')).toBe('false')
    })
  })

  describe('Peer review status hints', () => {
    it('displays hint message when passed as prop', () => {
      const hintMessage = {
        type: 'hint',
        text: 'Pikachu has already completed the required amount of peer reviews.',
      }
      const errors = [hintMessage]

      renderWithMocks({errors})

      expect(
        screen.getByText('Pikachu has already completed the required amount of peer reviews.'),
      ).toBeInTheDocument()
    })

    it('does not display hint when errors array is empty', () => {
      renderWithMocks({errors: []})

      expect(screen.queryByText(/has already completed/)).not.toBeInTheDocument()
      expect(screen.queryByText(/has enough "must review"/)).not.toBeInTheDocument()
    })
  })
})
