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

import {render, screen, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import FiltersPanel from '../FiltersPanel'
import {AppliedFilter, FilterOption} from '../../../../../../shared/react/types'

describe('FiltersPanel', () => {
  const mockOnFilterChange = jest.fn()

  const defaultProps = {
    onFilterChange: mockOnFilterChange,
    appliedFilters: [] as AppliedFilter[],
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the filter panel with correct title', () => {
    render(<FiltersPanel {...defaultProps} />)
    const filterResourcesHeading = screen.getAllByText('Filter resources')[0]
    expect(filterResourcesHeading).toBeInTheDocument()
  })

  it('renders with closed state by default', () => {
    render(<FiltersPanel {...defaultProps} />)
    expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
  })

  it('renders applied filters component', () => {
    render(
      <FiltersPanel
        {...defaultProps}
        appliedFilters={[{key: 'workflowStates', option: {value: 'published', label: 'Published'}}]}
      />,
    )
    expect(screen.getByTestId('applied-filters')).toBeInTheDocument()
  })

  it('does not show clear filters button when no filters are applied', () => {
    render(<FiltersPanel {...defaultProps} />)
    expect(screen.queryByTestId('clear-filters-button')).not.toBeInTheDocument()
  })

  describe('toggle button', () => {
    it('opens the filter panel when clicked', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      expect(screen.queryByTestId('apply-filters-button')).toBeInTheDocument()
      expect(screen.getByText('Resource type')).toBeInTheDocument()
      expect(screen.getByText('State')).toBeInTheDocument()
      expect(screen.getByText('With issues of')).toBeInTheDocument()
    })

    it('closes the filter panel when toggled again', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)
      expect(screen.queryByTestId('apply-filters-button')).toBeInTheDocument()

      await userEvent.click(toggleButton!)
      expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
    })
  })

  describe('date inputs', () => {
    it('render when panel is open', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      expect(screen.getByLabelText(/Last edited from/i)).toBeInTheDocument()
      expect(screen.getByLabelText(/Last edited to/i)).toBeInTheDocument()
    })

    it('passes distinct screenReaderLabels to date inputs', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const fromDateCalendarButton = screen.getByText(/Choose a date for Last edited from/i)
      const toDateCalendarButton = screen.getByText(/Choose a date for Last edited to/i)

      expect(fromDateCalendarButton).toBeInTheDocument()
      expect(toDateCalendarButton).toBeInTheDocument()
    })

    it('handle from date selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      await userEvent.type(fromDateInput, '2023-01-15')

      expect(fromDateInput).toHaveValue('2023-01-15')
    })

    it('handle to date selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const toDateInput = screen.getByLabelText(/Last edited to/i)
      await userEvent.type(toDateInput, '2023-12-31')

      expect(toDateInput).toHaveValue('2023-12-31')
    })

    it('handle clearing date inputs', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      await userEvent.type(fromDateInput, '2023-01-15')
      await userEvent.clear(fromDateInput)

      expect(fromDateInput).toHaveValue('')
    })
  })

  describe('checkbox groups', () => {
    it('render when panel is open', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      expect(screen.getByTestId('resource-type-checkbox-group')).toBeInTheDocument()
      expect(screen.getByTestId('state-checkbox-group')).toBeInTheDocument()
      expect(screen.getByTestId('issue-type-checkbox-group')).toBeInTheDocument()
    })

    it('handle resource type selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const resourceTypeGroup = screen.getByTestId('resource-type-checkbox-group')
      const wikiPageCheckbox = within(resourceTypeGroup).getByLabelText('Pages')
      const assignmentCheckbox = within(resourceTypeGroup).getByLabelText('Assignments')

      await userEvent.click(wikiPageCheckbox)

      expect(wikiPageCheckbox).not.toBeChecked()
      expect(assignmentCheckbox).toBeChecked()
    })

    it('handle state selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const stateGroup = screen.getByTestId('state-checkbox-group')
      const publishedCheckbox = within(stateGroup).getByLabelText('Published')
      const unpublishedCheckbox = within(stateGroup).getByLabelText('Unpublished')

      await userEvent.click(publishedCheckbox)

      expect(publishedCheckbox).not.toBeChecked()
      expect(unpublishedCheckbox).toBeChecked()
    })

    it('handle issue type selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const issueTypeGroup = screen.getByTestId('issue-type-checkbox-group')
      const adjacentLinksCheckbox = within(issueTypeGroup).getByLabelText('Duplicate links')
      const altTextCheckbox = within(issueTypeGroup).getByLabelText('Alt text')
      const missingTableHeaderCheckbox =
        within(issueTypeGroup).getByLabelText('Missing table headers')

      await userEvent.click(adjacentLinksCheckbox)

      expect(adjacentLinksCheckbox).not.toBeChecked()
      expect(altTextCheckbox).toBeChecked()
      expect(missingTableHeaderCheckbox).toBeChecked()
    })
  })

  describe('apply filters button', () => {
    it('calls onFilterChange with current filter selections when apply is clicked', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const applyButton = screen.getByTestId('apply-filters-button')
      await userEvent.click(applyButton)

      expect(mockOnFilterChange).toHaveBeenCalledWith({
        ruleTypes: [{label: 'all', value: 'all'}],
        artifactTypes: [{label: 'all', value: 'all'}],
        workflowStates: [{label: 'all', value: 'all'}],
        fromDate: null,
        toDate: null,
      })
    })

    it('closes the panel when apply is clicked', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const applyButton = screen.getByTestId('apply-filters-button')
      await userEvent.click(applyButton)

      expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
    })

    it('applies filters when panel is closed', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByRole('button', {name: 'Filter resources'})
      await userEvent.click(toggleButton!)

      const resourceTypeGroup = screen.getByTestId('resource-type-checkbox-group')
      const assignmentCheckbox = within(resourceTypeGroup).getByLabelText('Assignments')
      await userEvent.click(assignmentCheckbox)

      await userEvent.click(toggleButton!)

      expect(mockOnFilterChange).toHaveBeenCalledWith({
        ruleTypes: [{label: 'all', value: 'all'}],
        artifactTypes: [{label: 'Pages', value: 'wiki_page'}],
        workflowStates: [{label: 'all', value: 'all'}],
        fromDate: null,
        toDate: null,
      })
    })
  })

  describe('clear filters button', () => {
    it('shows when filters are applied', () => {
      const appliedFilters: AppliedFilter[] = [
        {
          key: 'workflowStates',
          option: {value: 'published', label: 'Published'} as FilterOption,
        },
      ]

      render(<FiltersPanel {...defaultProps} appliedFilters={appliedFilters} />)
      expect(screen.getByTestId('clear-filters-button')).toBeInTheDocument()
    })

    it('calls onFilterChange with null when clear filters is clicked', async () => {
      const appliedFilters: AppliedFilter[] = [
        {
          key: 'workflowStates',
          option: {value: 'published', label: 'Published'} as FilterOption,
        },
      ]

      render(<FiltersPanel {...defaultProps} appliedFilters={appliedFilters} />)

      const clearButton = screen.getByTestId('clear-filters-button')
      await userEvent.click(clearButton)

      expect(mockOnFilterChange).toHaveBeenCalledWith(null)
    })

    it('closes the panel when clear filters is clicked', async () => {
      const appliedFilters: AppliedFilter[] = [
        {
          key: 'workflowStates',
          option: {value: 'published', label: 'Published'} as FilterOption,
        },
      ]

      render(<FiltersPanel {...defaultProps} appliedFilters={appliedFilters} />)

      const clearButton = screen.getByTestId('clear-filters-button')
      await userEvent.click(clearButton)

      expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
    })
  })
})
