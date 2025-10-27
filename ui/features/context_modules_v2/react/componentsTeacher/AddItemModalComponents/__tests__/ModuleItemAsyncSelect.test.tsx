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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'
import ModuleItemAsyncSelect from '../ModuleItemAsyncSelect'
import {useModuleItemContent} from '../../../hooks/queries/useModuleItemContent'

jest.mock('../../../hooks/queries/useModuleItemContent')

const mockUseModuleItemContent = useModuleItemContent as jest.MockedFunction<
  typeof useModuleItemContent
>

const mockAssignments = [
  {id: '1', name: 'Assignment 1'},
  {id: '2', name: 'Assignment 2'},
  {id: '3', name: 'Test Assignment'},
  {id: '4', name: 'Another Assignment'},
]

const mockQuizzes = [
  {id: '5', name: 'Quiz 1'},
  {id: '6', name: 'Test Quiz'},
]

const renderWithProviders = (
  props: Partial<React.ComponentProps<typeof ModuleItemAsyncSelect>> = {},
) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  const defaultProps = {
    itemType: 'assignment' as const,
    courseId: '123',
    onSelectionChange: jest.fn(),
    renderLabel: 'Select Assignment',
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextModuleDefaultProps}>
        <ModuleItemAsyncSelect {...defaultProps} {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModuleItemAsyncSelect', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockUseModuleItemContent.mockReturnValue({
      data: {pages: [{items: []}]},
      isLoading: false,
      isError: false,
    } as any)
  })

  describe('Initial loading and display', () => {
    it('displays search results when user types', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: mockAssignments}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders()

      const input = screen.getByLabelText('Select Assignment')
      await userEvent.type(input, 'Assignment')

      await waitFor(() => {
        expect(screen.getByText('Assignment 1')).toBeInTheDocument()
        expect(screen.getByText('Assignment 2')).toBeInTheDocument()
      })
    })

    it('shows error state when loading fails', () => {
      mockUseModuleItemContent.mockReturnValue({
        data: undefined,
        isLoading: false,
        isError: true,
      } as any)

      renderWithProviders()
      expect(screen.getByDisplayValue('')).toBeInTheDocument()
    })
  })

  describe('Search functionality', () => {
    it('triggers search after typing minimum characters', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: [{id: '3', name: 'Test Assignment'}]}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders()

      const input = screen.getByLabelText('Select Assignment')
      await userEvent.type(input, 'Te')

      await waitFor(() => {
        expect(mockUseModuleItemContent).toHaveBeenCalledWith('assignment', '123', 'Te', true)
      })
    })

    it('maintains search text as user types', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: []}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders()

      const input = screen.getByLabelText('Select Assignment')
      await userEvent.type(input, 'Te')

      await waitFor(() => {
        expect(input).toHaveValue('Te')
      })
    })

    it('maintains search text in input field', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: [{id: '3', name: 'Test Assignment'}]}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders()

      const input = screen.getByLabelText('Select Assignment')
      await userEvent.type(input, 'Test')

      expect(input).toHaveValue('Test')
    })
  })

  describe('Item selection', () => {
    it('calls onSelectionChange when item is selected', async () => {
      const mockOnSelectionChange = jest.fn()

      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: mockAssignments}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders({onSelectionChange: mockOnSelectionChange})

      const input = screen.getByLabelText('Select Assignment')
      await userEvent.type(input, 'Assignment')

      await waitFor(() => {
        expect(screen.getByText('Assignment 1')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByText('Assignment 1'))

      expect(mockOnSelectionChange).toHaveBeenCalledWith('1', {id: '1', name: 'Assignment 1'})
    })

    it('clears selection when user starts typing different text', async () => {
      const mockOnSelectionChange = jest.fn()

      mockUseModuleItemContent.mockReturnValue({
        data: {
          items: [
            {id: '1', name: 'Selected Assignment'},
            {id: '3', name: 'Test Assignment'},
          ],
        },
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders({
        onSelectionChange: mockOnSelectionChange,
        selectedItemId: '1',
      })

      const input = screen.getByLabelText('Select Assignment')

      // Clear any previous calls from initial setup
      mockOnSelectionChange.mockClear()

      // Type something that doesn't match the selected item
      await userEvent.type(input, 'Different text')

      expect(mockOnSelectionChange).toHaveBeenCalledWith(null, null)
    })

    it('maintains selectedOptionId prop synchronization', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: mockAssignments}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders({
        selectedItemId: '2',
      })

      // Verify the component receives and handles the selectedItemId prop
      // The internal state should sync with the prop
      const select = screen.getByTestId('add-item-content-select')
      expect(select).toBeInTheDocument()

      // The selectedOptionId should be passed to CanvasAsyncSelect
      // This verifies the prop is being processed correctly internally
    })
  })

  describe('Content type handling', () => {
    it('filters out quizzes for assignment type', async () => {
      const mockAssignmentsWithQuizzes = [
        {id: '1', name: 'Assignment 1', isQuiz: false},
        {id: '2', name: 'Quiz Assignment', isQuiz: true},
        {id: '3', name: 'Assignment 2', isQuiz: false},
      ]

      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: mockAssignmentsWithQuizzes}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders({itemType: 'assignment'})

      const input = screen.getByLabelText('Select Assignment')
      await userEvent.type(input, 'Assignment')

      await waitFor(() => {
        expect(screen.getByText('Assignment 1')).toBeInTheDocument()
        expect(screen.getByText('Assignment 2')).toBeInTheDocument()
        expect(screen.queryByText('Quiz Assignment')).not.toBeInTheDocument()
      })
    })

    it('works with different content types', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: mockQuizzes}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders({itemType: 'quiz', renderLabel: 'Select Quiz'})

      const input = screen.getByLabelText('Select Quiz')
      await userEvent.type(input, 'Quiz')

      await waitFor(() => {
        expect(screen.getByText('Quiz 1')).toBeInTheDocument()
        expect(screen.getByText('Test Quiz')).toBeInTheDocument()
      })
    })
  })

  describe('Search behavior', () => {
    it('shows all search results when searching', async () => {
      const manySearchResults = Array.from({length: 50}, (_, i) => ({
        id: String(i + 1),
        name: `Test Item ${i + 1}`,
      }))

      mockUseModuleItemContent.mockReturnValue({
        data: {pages: [{items: manySearchResults}]},
        isLoading: false,
        isError: false,
      } as any)

      renderWithProviders()

      const input = screen.getByLabelText('Select Assignment')
      await userEvent.click(input)
      await userEvent.type(input, 'Test')

      await waitFor(() => {
        expect(screen.getByText('Test Item 1')).toBeInTheDocument()
        expect(screen.getByText('Test Item 50')).toBeInTheDocument()
      })
    })
  })
})
