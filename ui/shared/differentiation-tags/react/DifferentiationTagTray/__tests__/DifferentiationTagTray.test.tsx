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
import {render, screen, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DifferentiationTagTray from '../DifferentiationTagTray'
import type {DifferentiationTagTrayProps} from '../DifferentiationTagTray'
import {MockedQueryProvider} from '@canvas/test-utils/query'

// Mocking the DifferentiationTagModalManager, then setting the props it is passed as data attributes that we can check
// This way we can verify that the modal is opened with the correct mode and category ID
jest.mock(
  '@canvas/differentiation-tags/react/DifferentiationTagModalForm/DifferentiationTagModalManager',
  () =>
    function DummyModalManager(props: any) {
      return (
        <div
          data-testid="dummy-modal-manager"
          data-mode={props.mode}
          data-cat-id={props.differentiationTagCategoryId || ''}
        />
      )
    },
)

describe('DifferentiationTagTray', () => {
  const defaultProps: DifferentiationTagTrayProps = {
    isOpen: true,
    onClose: jest.fn(),
    differentiationTagCategories: [],
    isLoading: false,
    error: null,
  }

  const renderComponent = (props: Partial<DifferentiationTagTrayProps> = {}) => {
    render(
      <MockedQueryProvider>
        <DifferentiationTagTray {...defaultProps} {...props} />
      </MockedQueryProvider>,
    )
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the tray when isOpen is true', () => {
    renderComponent()
    expect(screen.queryByTestId('differentiation-tag-header')).toBeInTheDocument()
  })

  it('does not render search bar or + Tag button in empty state and clicking "Get Started" opens modal in create mode', async () => {
    renderComponent({differentiationTagCategories: []})

    expect(screen.queryByPlaceholderText('Search for Tag')).not.toBeInTheDocument()
    expect(screen.queryByText('+ Tag')).not.toBeInTheDocument()

    const getStartedButton = screen.getByText('Get Started').closest('button')
    await userEvent.click(getStartedButton!)
    const modalManager = screen.getByTestId('dummy-modal-manager')
    expect(modalManager).toHaveAttribute('data-mode', 'create')
    expect(modalManager).toHaveAttribute('data-cat-id', '')
  })

  it('renders link to community documentation when in empty state', () => {
    renderComponent({differentiationTagCategories: []})
    expect(
      screen.getByText(/Learn more about how we used your input to create differentiation tags./),
    ).toBeInTheDocument()
  })

  it('shows loading spinner when isLoading is true', () => {
    renderComponent({isLoading: true})
    expect(screen.getByTitle('Loading...')).toBeInTheDocument()
  })

  it('shows error message when there is an error', () => {
    const error = new Error('Failed to fetch')
    renderComponent({error})
    expect(screen.getByText(/Error loading categories:/)).toBeInTheDocument()
    expect(screen.getByText(/Failed to fetch/)).toBeInTheDocument()
  })

  it('displays differentiation tag categories when data is available', () => {
    const mockCategories = [
      {id: 1, name: 'Category 1', groups: []},
      {id: 2, name: 'Category 2', groups: []},
    ]
    renderComponent({differentiationTagCategories: mockCategories})
    expect(screen.getByText('Category 1')).toBeInTheDocument()
    expect(screen.getByText('Category 2')).toBeInTheDocument()
  })

  it('renders help text when there are no differentiation tags', () => {
    renderComponent({isOpen: true})
    expect(screen.getByText(/Like groups, but different!/)).toBeInTheDocument()
  })

  it('does not render tray when isOpen is false', () => {
    renderComponent({isOpen: false})
    expect(screen.queryByTestId('differentiation-tag-header')).not.toBeInTheDocument()
  })

  it('renders the correct category card content', () => {
    const mockCategories = [
      {id: 1, name: 'Advanced', groups: []},
      {id: 2, name: 'Remedial', groups: []},
    ]
    renderComponent({differentiationTagCategories: mockCategories})
    expect(screen.getByText('Advanced')).toBeInTheDocument()
    expect(screen.getByText('Remedial')).toBeInTheDocument()
  })

  describe('modal interactions', () => {
    it('opens modal in create mode when clicking "+ Tag" button', async () => {
      const mockCategories = [{id: 1, name: 'Category 1', groups: []}]
      renderComponent({differentiationTagCategories: mockCategories})
      const createButton = screen.getByText('+ Tag').closest('button')
      await userEvent.click(createButton!)
      const modalManager = screen.getByTestId('dummy-modal-manager')
      expect(modalManager).toHaveAttribute('data-mode', 'create')
      expect(modalManager).toHaveAttribute('data-cat-id', '')
    })

    it('opens modal in edit mode when clicking "+ Add a variant" link in a category with no tags', async () => {
      const mockCategory = {id: 42, name: 'Editable Category', groups: []}
      renderComponent({differentiationTagCategories: [mockCategory]})
      const addVariantLink = screen.getByText('+ Add a variant')
      const addVariantButton = addVariantLink.closest('button')
      await userEvent.click(addVariantButton!)
      const modalManager = screen.getByTestId('dummy-modal-manager')
      expect(modalManager).toHaveAttribute('data-mode', 'edit')
      expect(modalManager).toHaveAttribute('data-cat-id', '42')
    })
  })

  describe('pagination logic', () => {
    it('renders pagination controls when categories exceed items per page', () => {
      const mockCategories = Array.from({length: 5}, (_, i) => ({
        id: i + 1,
        name: `Category ${i + 1}`,
        groups: [],
      }))
      renderComponent({differentiationTagCategories: mockCategories})
      const paginationNav = screen.getByTestId('differentiation-tag-pagination')

      expect(paginationNav).toBeInTheDocument()
      expect(screen.getByText('1')).toBeInTheDocument()
      expect(screen.getByText('2')).toBeInTheDocument()
    })

    it('displays only the categories for the current page and updates on page change', async () => {
      const mockCategories = Array.from({length: 5}, (_, i) => ({
        id: i + 1,
        name: `Category ${i + 1}`,
        groups: [],
      }))
      renderComponent({differentiationTagCategories: mockCategories})
      expect(screen.getByText('Category 1')).toBeInTheDocument()
      expect(screen.getByText('Category 2')).toBeInTheDocument()
      expect(screen.getByText('Category 3')).toBeInTheDocument()
      expect(screen.getByText('Category 4')).toBeInTheDocument()
      expect(screen.queryByText('Category 5')).not.toBeInTheDocument()

      const pageTwoButton = screen.getByText('2').closest('button')
      await userEvent.click(pageTwoButton!)

      expect(screen.getByText('Category 5')).toBeInTheDocument()
      expect(screen.queryByText('Category 1')).not.toBeInTheDocument()
      expect(screen.queryByText('Category 2')).not.toBeInTheDocument()
      expect(screen.queryByText('Category 3')).not.toBeInTheDocument()
      expect(screen.queryByText('Category 4')).not.toBeInTheDocument()
    })

    it('does not render pagination when total pages is 1', () => {
      const mockCategories = [
        {id: 1, name: 'Category 1', groups: []},
        {id: 2, name: 'Category 2', groups: []},
      ]
      renderComponent({differentiationTagCategories: mockCategories})
      expect(screen.queryByTestId('differentiation-tag-pagination')).not.toBeInTheDocument()
    })
  })

  describe('DifferentiationTagTray - search and filtering logic', () => {
    beforeEach(() => {
      jest.useFakeTimers()
    })

    afterEach(() => {
      jest.runOnlyPendingTimers()
      jest.useRealTimers()
    })

    it('displays all categories when search input is empty', () => {
      const mockCategories = [
        {id: 1, name: 'Advanced', groups: []},
        {id: 2, name: 'Remedial', groups: []},
      ]
      renderComponent({differentiationTagCategories: mockCategories})
      expect(screen.getByText('Advanced')).toBeInTheDocument()
      expect(screen.getByText('Remedial')).toBeInTheDocument()
    })

    it('filters categories based on matching category name', async () => {
      const user = userEvent.setup({delay: null})
      const mockCategories = [
        {id: 1, name: 'Advanced', groups: []},
        {id: 2, name: 'Remedial', groups: []},
      ]
      renderComponent({differentiationTagCategories: mockCategories})
      const searchInput = screen.getByPlaceholderText('Search for Tag')

      // Type a search term that should match only "Advanced"
      await user.clear(searchInput)
      await user.type(searchInput, 'adv')

      act(() => {
        jest.advanceTimersByTime(300)
      })

      expect(screen.getByText('Advanced')).toBeInTheDocument()
      expect(screen.queryByText('Remedial')).not.toBeInTheDocument()
    })

    it('filters categories based on matching group name', async () => {
      const user = userEvent.setup({delay: null})
      const mockCategories = [
        {
          id: 1,
          name: 'Advanced',
          groups: [{id: 1, name: 'Math Group', members_count: 10}],
        },
        {
          id: 2,
          name: 'Remedial',
          groups: [{id: 2, name: 'Science Group', members_count: 5}],
        },
      ]
      renderComponent({differentiationTagCategories: mockCategories})
      const searchInput = screen.getByPlaceholderText('Search for Tag')

      // Type a search term that matches the group name in the second category
      await user.clear(searchInput)
      await user.type(searchInput, 'sci')

      act(() => {
        jest.advanceTimersByTime(300)
      })

      expect(screen.getByText('Remedial')).toBeInTheDocument()
      expect(screen.queryByText('Advanced')).not.toBeInTheDocument()
    })

    it('shows "No matching tags found." message when search does not match any category or group', async () => {
      const user = userEvent.setup({delay: null})
      const mockCategories = [
        {id: 1, name: 'Advanced', groups: []},
        {id: 2, name: 'Remedial', groups: []},
      ]
      renderComponent({differentiationTagCategories: mockCategories})
      const searchInput = screen.getByPlaceholderText('Search for Tag')

      await user.clear(searchInput)
      await user.type(searchInput, 'nonexistent')

      act(() => {
        jest.advanceTimersByTime(300)
      })

      expect(screen.getByText('No matching tags found.')).toBeInTheDocument()
    })

    it('resets pagination to the first page when the search term changes', async () => {
      const user = userEvent.setup({delay: null})
      // Create 5 categories (itemsPerPage is 4 so page 2 will show only the 5th)
      const mockCategories = Array.from({length: 5}, (_, i) => ({
        id: i + 1,
        name: `Category ${i + 1}`,
        groups: [],
      }))
      renderComponent({differentiationTagCategories: mockCategories})

      // Initially, page 1 should show Category 1-4
      expect(screen.getByText('Category 1')).toBeInTheDocument()
      expect(screen.queryByText('Category 5')).not.toBeInTheDocument()

      // Navigate to page 2 via pagination
      const pageTwoButton = screen.getByText('2').closest('button')
      await user.click(pageTwoButton!)
      expect(screen.getByText('Category 5')).toBeInTheDocument()

      // Now, type in the search input which should trigger the useEffect to reset pagination to page 1
      const searchInput = screen.getByPlaceholderText('Search for Tag')
      await user.clear(searchInput)
      await user.type(searchInput, 'Category')
      act(() => {
        jest.advanceTimersByTime(300)
      })

      // The pagination should reset to page 1 so that Category 1 is visible and Category 5 is not
      expect(screen.getByText('Category 1')).toBeInTheDocument()
      expect(screen.queryByText('Category 5')).not.toBeInTheDocument()
    })
  })
})
