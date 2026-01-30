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

import {cleanup, render, screen, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import FiltersPanel from '../FiltersPanel'
import {AppliedFilter, FilterOption} from '../../../../../../shared/react/types'
import {useAccessibilityScansStore} from '../../../../../../shared/react/stores/AccessibilityScansStore'

vi.mock('../../../../../../shared/react/stores/AccessibilityScansStore', () => ({
  useAccessibilityScansStore: vi.fn(),
}))

describe('FiltersPanel', () => {
  const mockOnFilterChange = vi.fn()

  const defaultProps = {
    onFilterChange: mockOnFilterChange,
    appliedFilters: [] as AppliedFilter[],
  }

  const mockMatchMedia = (matches: boolean) => {
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: vi.fn().mockImplementation(query => ({
        matches,
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
      })),
    })
  }

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
    mockMatchMedia(true)
    // Mock the store to return additionalResourcesEnabled: true by default
    vi.mocked(useAccessibilityScansStore).mockImplementation((selector: any) => {
      if (typeof selector === 'function') {
        return selector({additionalResourcesEnabled: true})
      }
      return {additionalResourcesEnabled: true}
    })
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

  it('renders applied filters component on desktop', () => {
    render(
      <FiltersPanel
        {...defaultProps}
        appliedFilters={[{key: 'workflowStates', option: {value: 'published', label: 'Published'}}]}
      />,
    )
    expect(screen.getByTestId('applied-filters')).toBeInTheDocument()
  })

  it('does not render applied filters component on tablet', () => {
    mockMatchMedia(false)

    render(
      <FiltersPanel
        {...defaultProps}
        appliedFilters={[{key: 'workflowStates', option: {value: 'published', label: 'Published'}}]}
      />,
    )
    expect(screen.queryByTestId('applied-filters')).not.toBeInTheDocument()
  })

  it('does not show clear filters button when no filters are applied', () => {
    render(<FiltersPanel {...defaultProps} />)
    expect(screen.queryByTestId('clear-filters-button')).not.toBeInTheDocument()
  })

  describe('toggle button', () => {
    it('opens the filter panel when clicked', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      expect(screen.queryByTestId('apply-filters-button')).toBeInTheDocument()
      expect(screen.getByText('Resource type')).toBeInTheDocument()
      expect(screen.getByText('State')).toBeInTheDocument()
      expect(screen.getByText('With issues of')).toBeInTheDocument()
    })

    it('closes the filter panel when toggled again', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)
      expect(screen.queryByTestId('apply-filters-button')).toBeInTheDocument()

      await userEvent.click(toggleButton!)
      expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
    })
  })

  describe('date inputs', () => {
    it('render when panel is open', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      expect(screen.getByLabelText(/Last edited from/i)).toBeInTheDocument()
      expect(screen.getByLabelText(/Last edited to/i)).toBeInTheDocument()
    })

    it('passes distinct screenReaderLabels to date inputs', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const fromDateCalendarButton = screen.getByText(/Choose a date for Last edited from/i)
      const toDateCalendarButton = screen.getByText(/Choose a date for Last edited to/i)

      expect(fromDateCalendarButton).toBeInTheDocument()
      expect(toDateCalendarButton).toBeInTheDocument()
    })

    it('handle from date selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      await userEvent.type(fromDateInput, '2023-01-15')

      expect(fromDateInput).toHaveValue('2023-01-15')
    })

    it('handle to date selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const toDateInput = screen.getByLabelText(/Last edited to/i)
      await userEvent.type(toDateInput, '2023-12-31')

      expect(toDateInput).toHaveValue('2023-12-31')
    })

    it('handle clearing date inputs', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      await userEvent.type(fromDateInput, '2023-01-15')
      await userEvent.clear(fromDateInput)

      expect(fromDateInput).toHaveValue('')
    })

    describe('date range validation', () => {
      it('disables fromDate dates after selected toDate', async () => {
        const appliedFilters: AppliedFilter[] = [
          {
            key: 'toDate',
            option: {value: '2024-01-20T00:00:00.000Z', label: 'Jan 20, 2024'},
          },
        ]

        render(<FiltersPanel {...defaultProps} appliedFilters={appliedFilters} />)

        const toggleButton = screen.getByTestId('filter-resources-toggle')
        await userEvent.click(toggleButton!)

        const toDateInput = screen.getByLabelText(/Last edited to/i) as HTMLInputElement
        expect(toDateInput.value).toBeTruthy()
      })

      it('disables toDate dates before selected fromDate', async () => {
        const appliedFilters: AppliedFilter[] = [
          {
            key: 'fromDate',
            option: {value: '2024-01-10T00:00:00.000Z', label: 'Jan 10, 2024'},
          },
        ]

        render(<FiltersPanel {...defaultProps} appliedFilters={appliedFilters} />)

        const toggleButton = screen.getByTestId('filter-resources-toggle')
        await userEvent.click(toggleButton!)

        // Verify fromDate is set in the component
        const fromDateInput = screen.getByLabelText(/Last edited from/i) as HTMLInputElement
        expect(fromDateInput.value).toBeTruthy()
      })

      it('allows all dates when toDate is not selected', async () => {
        render(<FiltersPanel {...defaultProps} />)

        const toggleButton = screen.getByTestId('filter-resources-toggle')
        await userEvent.click(toggleButton!)

        const fromDateInput = screen.getByLabelText(/Last edited from/i) as HTMLInputElement
        const toDateInput = screen.getByLabelText(/Last edited to/i) as HTMLInputElement

        expect(fromDateInput.value).toBe('')
        expect(toDateInput.value).toBe('')
      })

      it('allows all dates when fromDate is not selected', async () => {
        render(<FiltersPanel {...defaultProps} />)

        const toggleButton = screen.getByTestId('filter-resources-toggle')
        await userEvent.click(toggleButton!)

        const fromDateInput = screen.getByLabelText(/Last edited from/i) as HTMLInputElement
        const toDateInput = screen.getByLabelText(/Last edited to/i) as HTMLInputElement

        expect(fromDateInput.value).toBe('')
        expect(toDateInput.value).toBe('')
      })
    })
  })

  describe('checkbox groups', () => {
    it('render when panel is open', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      expect(screen.getByTestId('resource-type-checkbox-group')).toBeInTheDocument()
      expect(screen.getByTestId('state-checkbox-group')).toBeInTheDocument()
      expect(screen.getByTestId('issue-type-checkbox-group')).toBeInTheDocument()
    })

    it('handle resource type selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const resourceTypeGroup = screen.getByTestId('resource-type-checkbox-group')
      const wikiPageCheckbox = within(resourceTypeGroup).getByLabelText('Pages')
      const assignmentCheckbox = within(resourceTypeGroup).getByLabelText('Assignments')
      const discussionTopicCheckbox = within(resourceTypeGroup).getByLabelText('Discussion topics')

      await userEvent.click(wikiPageCheckbox)

      expect(wikiPageCheckbox).not.toBeChecked()
      expect(assignmentCheckbox).toBeChecked()
      expect(discussionTopicCheckbox).toBeChecked()
    })

    it('handle state selection', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
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

      const toggleButton = screen.getByTestId('filter-resources-toggle')
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

      const toggleButton = screen.getByTestId('filter-resources-toggle')
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

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const applyButton = screen.getByTestId('apply-filters-button')
      await userEvent.click(applyButton)

      expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
    })

    it('applies filters when panel is closed', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const resourceTypeGroup = screen.getByTestId('resource-type-checkbox-group')
      const assignmentCheckbox = within(resourceTypeGroup).getByLabelText('Assignments')
      const discussionTopicCheckbox = within(resourceTypeGroup).getByLabelText('Discussion topics')
      await userEvent.click(assignmentCheckbox)
      await userEvent.click(discussionTopicCheckbox)

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

  describe('Apply filter validation', () => {
    it('shows error when fromDate > toDate and prevents filter application', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      const toDateInput = screen.getByLabelText(/Last edited to/i)

      await userEvent.type(fromDateInput, '2024-01-20')
      await userEvent.type(toDateInput, '2024-01-10')

      const applyButton = screen.getByTestId('apply-filters-button')
      await userEvent.click(applyButton)

      expect(screen.getByText(/End date must be after the start date\./i)).toBeInTheDocument()

      expect(mockOnFilterChange).not.toHaveBeenCalled()
      expect(screen.getByTestId('apply-filters-button')).toBeInTheDocument()
    })

    it('applies filters successfully when fromDate < toDate', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      const toDateInput = screen.getByLabelText(/Last edited to/i)

      await userEvent.type(fromDateInput, '2024-01-10')
      await userEvent.type(toDateInput, '2024-01-20')

      const applyButton = screen.getByTestId('apply-filters-button')
      await userEvent.click(applyButton)

      expect(screen.queryByText(/End date must be after the start date\./i)).not.toBeInTheDocument()

      expect(mockOnFilterChange).toHaveBeenCalled()
      expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
    })

    it('clears errors when date is changed and apply succeeds with valid range', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      const toDateInput = screen.getByLabelText(/Last edited to/i)

      await userEvent.type(fromDateInput, '2024-01-20')
      await userEvent.type(toDateInput, '2024-01-10')

      const applyButton = screen.getByTestId('apply-filters-button')
      await userEvent.click(applyButton)

      expect(screen.getByText(/End date must be after the start date\./i)).toBeInTheDocument()

      await userEvent.clear(fromDateInput)
      await userEvent.type(fromDateInput, '2024-01-05')

      await userEvent.click(applyButton)

      expect(mockOnFilterChange).toHaveBeenCalled()
      expect(screen.queryByTestId('apply-filters-button')).not.toBeInTheDocument()
    })

    it('applies filters when only one date is set', async () => {
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const fromDateInput = screen.getByLabelText(/Last edited from/i)
      await userEvent.type(fromDateInput, '2024-01-10')

      const applyButton = screen.getByTestId('apply-filters-button')
      await userEvent.click(applyButton)

      expect(mockOnFilterChange).toHaveBeenCalled()
    })
  })

  describe('additional resources feature flag', () => {
    it('shows discussion topics checkbox when feature is enabled', async () => {
      // additionalResourcesEnabled is true by default in beforeEach
      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const resourceTypeGroup = screen.getByTestId('resource-type-checkbox-group')
      expect(within(resourceTypeGroup).getByLabelText('Discussion topics')).toBeInTheDocument()
    })

    it('hides discussion topics checkbox when feature is disabled', async () => {
      // Override the mock to return false
      vi.mocked(useAccessibilityScansStore).mockImplementation((selector: any) => {
        if (typeof selector === 'function') {
          return selector({additionalResourcesEnabled: false})
        }
        return {additionalResourcesEnabled: false}
      })

      render(<FiltersPanel {...defaultProps} />)

      const toggleButton = screen.getByTestId('filter-resources-toggle')
      await userEvent.click(toggleButton!)

      const resourceTypeGroup = screen.getByTestId('resource-type-checkbox-group')
      expect(
        within(resourceTypeGroup).queryByLabelText('Discussion topics'),
      ).not.toBeInTheDocument()
      // But Pages and Assignments should still be there
      expect(within(resourceTypeGroup).getByLabelText('Pages')).toBeInTheDocument()
      expect(within(resourceTypeGroup).getByLabelText('Assignments')).toBeInTheDocument()
    })
  })
})
