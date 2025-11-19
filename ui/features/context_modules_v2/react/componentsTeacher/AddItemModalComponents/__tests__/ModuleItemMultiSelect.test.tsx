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
import ModuleItemMultiSelect from '../ModuleItemMultiSelect'
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

const renderWithProviders = (
  props: Partial<React.ComponentProps<typeof ModuleItemMultiSelect>> = {},
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
    selectedItemIds: [],
    onSelectionChange: jest.fn(),
    renderLabel: 'Select Assignments',
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextModuleDefaultProps}>
        <ModuleItemMultiSelect {...defaultProps} {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModuleItemMultiSelect', () => {
  beforeAll(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  afterAll(() => {
    const liveRegion = document.getElementById('flash_screenreader_holder')
    if (liveRegion) {
      document.body.removeChild(liveRegion)
    }
  })

  beforeEach(() => {
    jest.clearAllMocks()
    mockUseModuleItemContent.mockReturnValue({
      data: {
        pages: [
          {
            items: [],
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              endCursor: null,
              startCursor: null,
            },
          },
        ],
        pageParams: [undefined],
      },
      isLoading: false,
      isError: false,
      hasNextPage: false,
      fetchNextPage: jest.fn(),
      isFetchingNextPage: false,
    } as any)
  })

  describe('Multiple selection', () => {
    it('allows selecting multiple items', async () => {
      const onSelectionChange = jest.fn()
      mockUseModuleItemContent.mockReturnValue({
        data: {
          pages: [
            {
              items: mockAssignments,
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                endCursor: null,
                startCursor: null,
              },
            },
          ],
          pageParams: [undefined],
        },
        isLoading: false,
        isError: false,
        hasNextPage: false,
        fetchNextPage: jest.fn(),
        isFetchingNextPage: false,
      } as any)

      renderWithProviders({onSelectionChange})

      const input = screen.getByLabelText('Select Assignments')
      await userEvent.click(input)

      await waitFor(() => {
        expect(screen.getByText('Assignment 1')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByText('Assignment 1'))

      expect(onSelectionChange).toHaveBeenCalledWith(['1'], [{id: '1', name: 'Assignment 1'}])
    })

    it('displays selected items as tags', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {
          pages: [
            {
              items: mockAssignments,
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                endCursor: null,
                startCursor: null,
              },
            },
          ],
          pageParams: [undefined],
        },
        isLoading: false,
        isError: false,
        hasNextPage: false,
        fetchNextPage: jest.fn(),
        isFetchingNextPage: false,
      } as any)

      renderWithProviders({
        selectedItemIds: ['1', '2'],
      })

      await waitFor(() => {
        expect(screen.getByText('Assignment 1')).toBeInTheDocument()
        expect(screen.getByText('Assignment 2')).toBeInTheDocument()
      })
    })

    it('removes items when tag is dismissed', async () => {
      const onSelectionChange = jest.fn()
      mockUseModuleItemContent.mockReturnValue({
        data: {
          pages: [
            {
              items: mockAssignments,
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                endCursor: null,
                startCursor: null,
              },
            },
          ],
          pageParams: [undefined],
        },
        isLoading: false,
        isError: false,
        hasNextPage: false,
        fetchNextPage: jest.fn(),
        isFetchingNextPage: false,
      } as any)

      renderWithProviders({
        selectedItemIds: ['1', '2'],
        onSelectionChange,
      })

      await waitFor(() => {
        expect(screen.getByTitle('Remove Assignment 1')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByTitle('Remove Assignment 1'))

      await waitFor(() => {
        expect(onSelectionChange).toHaveBeenCalledWith(['2'], [{id: '2', name: 'Assignment 2'}])
      })
    })
  })

  describe('Pagination', () => {
    it('renders component with pagination data', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: {
          pages: [
            {
              items: mockAssignments,
              pageInfo: {
                hasNextPage: true,
                hasPreviousPage: false,
                endCursor: 'cursor123',
                startCursor: null,
              },
            },
          ],
          pageParams: [undefined],
        },
        isLoading: false,
        isError: false,
        hasNextPage: true,
        fetchNextPage: jest.fn(),
        isFetchingNextPage: false,
      } as any)

      renderWithProviders()

      expect(screen.getByLabelText('Select Assignments')).toBeInTheDocument()
    })
  })

  describe('Error handling', () => {
    it('shows error state when loading fails', async () => {
      mockUseModuleItemContent.mockReturnValue({
        data: undefined,
        isLoading: false,
        isError: true,
        hasNextPage: false,
        fetchNextPage: jest.fn(),
        isFetchingNextPage: false,
      } as any)

      renderWithProviders()

      expect(screen.getByLabelText('Select Assignments')).toBeInTheDocument()
    })
  })
})
