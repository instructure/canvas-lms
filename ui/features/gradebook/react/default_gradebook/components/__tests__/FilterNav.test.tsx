/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import FilterNav from '../FilterNav'
import fetchMock from 'fetch-mock'
import store from '../../stores/index'
import type {FilterNavProps} from '../FilterNav'
import type {FilterPreset, Filter} from '../../gradebook.d'
import type {Assignment} from '../../../../../../api.d'
import {render} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

const originalState = store.getState()

const defaultRules = {
  drop_lowest: 0,
  drop_highest: 0,
  never_drop: [],
}

const defaultAssignmentGroupProps = {
  rules: {},
  sis_source_id: null,
  integration_data: null,
}

const defaultSectionProps = {
  course_id: '1',
  created_at: '1970-01-01T00:00:00Z',
  end_at: null,
  integration_id: null,
  nonxlist_course_id: null,
  restrict_enrollments_to_section_dates: null,
  sis_course_id: null,
  sis_import_id: null,
  sis_section_id: null,
  start_at: null,
}

const defaultGradingPeriodProps = {
  endDate: new Date(4),
  isClosed: false,
}

const StudentGroupCategoryProps = {
  allows_multiple_memberships: false,
  auto_leader: null,
  context_type: 'course',
  course_id: '1',
  created_at: '1970-01-01T00:00:00Z',
  group_limit: null,
  is_member: false,
  protected: false,
  role: null,
  self_signup: null,
  sis_group_category_id: null,
  sis_import_id: null,
}

const defaultProps: FilterNavProps = {
  modules: [
    {id: '1', name: 'Module 1', position: 1},
    {id: '2', name: 'Module 2', position: 2},
    {id: '3', name: 'Module 3', position: 3},
  ],
  assignmentGroups: [
    {
      ...defaultAssignmentGroupProps,
      id: '4',
      name: 'Assignment Group 4',
      position: 1,
      group_weight: 0,
      assignments: [
        {
          module_ids: ['1'],
        } as Assignment,
      ],
    },
    {
      id: '5',
      name: 'Assignment Group 5',
      position: 2,
      group_weight: 0,
      assignments: [],
      integration_data: null,
      rules: defaultRules,
      sis_source_id: null,
    },
    {
      id: '6',
      name: 'Assignment Group 6',
      position: 3,
      group_weight: 0,
      assignments: [],
      integration_data: null,
      rules: defaultRules,
      sis_source_id: null,
    },
  ],
  sections: [
    {...defaultSectionProps, id: '7', name: 'Section 7'},
    {...defaultSectionProps, id: '8', name: 'Section 8'},
    {...defaultSectionProps, id: '9', name: 'Section 9'},
  ],
  gradingPeriods: [
    {
      ...defaultGradingPeriodProps,
      id: '1',
      title: 'Grading Period 1',
      startDate: new Date(1),
      closeDate: new Date(2),
      isLast: false,
      weight: 0.5,
    },
    {
      ...defaultGradingPeriodProps,
      id: '2',
      title: 'Grading Period 2',
      startDate: new Date(2),
      closeDate: new Date(2),
      isLast: false,
      weight: 0.5,
    },
    {
      ...defaultGradingPeriodProps,
      id: '3',
      title: 'Grading Period 3',
      startDate: new Date(3),
      closeDate: new Date(2),
      isLast: false,
      weight: 0.5,
    },
  ],
  studentGroupCategories: {
    '1': {
      ...StudentGroupCategoryProps,
      id: '1',
      name: 'Student Group Category 1',
      groups: [
        {id: '1', name: 'Student Group 1'},
        {id: '2', name: 'Student Group 2'},
      ],
    },
    '2': {
      ...StudentGroupCategoryProps,
      id: '2',
      name: 'Student Group Category 2',
      groups: [
        {id: '3', name: 'Student Group 3'},
        {id: '4', name: 'Student Group 4'},
      ],
    },
  },
  customStatuses: [
    {
      id: '1',
      name: 'Custom Status 1',
      color: '#000000',
    },
    {
      id: '2',
      name: 'Custom Status 2',
      color: '#000000',
    },
  ],
  multiselectGradebookFiltersEnabled: false,
}

const defaultAppliedFilters: Filter[] = [
  {
    id: '2',
    type: 'module',
    value: '1',
    created_at: new Date().toISOString(),
  },
  {
    id: '3',
    type: 'start-date',
    value: '2022-02-07',
    created_at: new Date().toISOString(),
  },
  {
    id: '4',
    type: 'end-date',
    value: '2023-02-07',
    created_at: new Date().toISOString(),
  },
]

const defaultFilterPresets: FilterPreset[] = [
  {
    id: '1',
    name: 'Filter Preset 1',
    filters: [
      {
        id: '2',
        type: 'module',
        value: '1',
        created_at: '2022-02-05T10:18:34-07:00',
      },
    ],
    created_at: '2022-02-05T10:18:34-07:00',
    updated_at: '2022-02-05T10:18:34-07:00',
  },
  {
    id: 'preset-2',
    name: 'Filter Preset 2',
    filters: [
      {
        id: '3',
        type: 'section',
        value: '7',
        created_at: new Date().toISOString(),
      },
    ],
    created_at: '2022-02-06T10:18:34-07:00',
    updated_at: '2022-02-06T10:18:34-07:00',
  },
]

const mockPostResponse = {
  gradebook_filter: {
    id: '25',
    course_id: '0',
    user_id: '1',
    name: 'test',
    payload: {
      filters: [
        {
          id: 'f783e528-dbb5-4474-972a-0f1a19c29551',
          type: 'section',
          value: '2',
          created_at: '2022-02-08T17:18:13.190Z',
        },
      ],
    },
    created_at: '2022-02-08T10:18:34-07:00',
    updated_at: '2022-02-08T10:18:34-07:00',
  },
}

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never}

describe('FilterNav', () => {
  beforeEach(() => {
    let liveRegion = null
    if (!document.getElementById('flash_screenreader_holder')) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }

    store.setState({
      filterPresets: defaultFilterPresets,
      appliedFilters: defaultAppliedFilters,
    })
    fetchMock.mock('*', 200)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('renders filters button', async () => {
    const {getByRole} = render(<FilterNav {...defaultProps} />)
    await getByRole('button', {name: 'Apply Filters'})
  })

  it('render condition tag for applied staged filter', async () => {
    store.setState({
      stagedFilters: [
        {
          id: '4',
          type: 'module',
          value: '1',
          created_at: new Date().toISOString(),
        },
        {
          id: '5',
          type: undefined,
          value: undefined,
          created_at: new Date().toISOString(),
        },
      ],
    })
    const {getByTestId} = render(<FilterNav {...defaultProps} />)
    expect(await getByTestId(`applied-filter-${defaultProps.modules[0].name}`)).toHaveTextContent(
      defaultProps.modules[0].name
    )
  })

  it('render custom status filter', () => {
    store.setState({
      appliedFilters: [
        {
          id: '1',
          type: 'submissions',
          value: 'custom-status-1',
          created_at: new Date().toISOString(),
        },
      ],
    })
    const {getByTestId} = render(<FilterNav {...defaultProps} />)
    expect(getByTestId(`applied-filter-${defaultProps.customStatuses[0].name}`)).toHaveTextContent(
      defaultProps.customStatuses[0].name
    )
  })

  it('render All Grading Periods filter', () => {
    store.setState({
      appliedFilters: [
        {
          id: '1',
          type: 'grading-period',
          value: '0',
          created_at: new Date().toISOString(),
        },
      ],
    })
    const {getByTestId} = render(<FilterNav {...defaultProps} />)
    expect(getByTestId('applied-filter-All Grading Periods')).toHaveTextContent(
      'All Grading Periods'
    )
  })

  it('opens tray', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Create & Manage Filter Presets'))
    expect(getByRole('heading')).toHaveTextContent('Saved Filter Presets')
  })

  it('shows friendly panda image when there are no filters', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    store.setState({filterPresets: [], stagedFilters: []})
    const {getByTestId, getByText} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Create & Manage Filter Presets'))
    expect(await getByTestId('friendly-panda')).toBeInTheDocument()
  })

  it('hides friendly panda image when there are filters', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {queryByTestId, getByText} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Create & Manage Filter Presets'))
    expect(await queryByTestId('friendly-panda')).toBeNull()
  })

  it('clicking Create New Filter Preset triggers onChange with filter', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    store.setState({filterPresets: []})
    const {getByText, queryByTestId, getByTestId} = render(<FilterNav {...defaultProps} />)
    expect(queryByTestId('save-filter-button')).toBeNull()
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Create & Manage Filter Presets'))
    await user.click(getByText('Toggle Create Filter Preset'))
    expect(getByTestId('save-filter-button')).toBeVisible()
  })

  describe('FilterNavPopover', () => {
    const filterProps = {...defaultProps, multiselectGradebookFiltersEnabled: true}

    it('applies filter popover trigger tag when filter is applied', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, queryByTestId, getByRole} = render(
        <FilterNav {...filterProps} />
      )
      expect(queryByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeNull()
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()
    })

    it('opens popover when filter nav tag is clicked', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, queryByTestId, getByRole} = render(
        <FilterNav {...filterProps} />
      )
      expect(queryByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeNull()
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
      expect(getByTestId('remove-filter-popover-menu-item')).toBeVisible()
      expect(getByTestId(`${defaultProps.sections[0].name}-filter-type`)).toBeVisible()
    })

    it('clicking remove filter removes filter', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, queryByTestId, getByRole} = render(
        <FilterNav {...filterProps} />
      )
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()

      await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
      await user.click(getByTestId('remove-filter-popover-menu-item'))
      expect(queryByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeNull()
    })

    it('clicking on the same section in the popover will close the popover', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, queryByTestId, getByRole} = render(
        <FilterNav {...filterProps} />
      )
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()
      await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
      await user.click(getByTestId(`${defaultProps.sections[0].name}-filter-type`))
      expect(queryByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeNull()
    })

    it('clicking on another section in the popover will change the filter value', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, getByRole} = render(<FilterNav {...filterProps} />)
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()
      await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
      await user.click(getByTestId(`${defaultProps.sections[1].name}-filter-type`))
      expect(getByTestId(`applied-filter-Sections (2)`)).toBeVisible()
    })

    it.skip('clicking on another popover trigger will close the current popover', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, queryByTestId, getByRole} = render(
        <FilterNav {...filterProps} />
      )
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()
      expect(getByTestId(`applied-filter-${defaultProps.modules[0].name}`)).toBeVisible()
      await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
      expect(getByTestId(`${defaultProps.sections[0].name}-filter-type`)).toBeVisible()
      await user.click(getByTestId(`applied-filter-${defaultProps.modules[0].name}`))
      expect(getByTestId(`${defaultProps.modules[0].name}-filter-type`)).toBeVisible()
      expect(queryByTestId(`${defaultProps.sections[0].name}-filter-type`)).toBeNull()
    })

    it('allows the FilterNavDateModal to open when clicking on a start date filter', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByTestId, queryByTestId} = render(<FilterNav {...filterProps} />)
      const startDateFilter = queryByTestId(/^applied-filter-Start/)
      expect(startDateFilter).not.toBeNull()
      await user.click(startDateFilter as HTMLElement)
      await user.click(getByTestId('start-date-filter-type'))
      expect(getByTestId(`start-date-input`)).toBeVisible()

      const endDateFilter = queryByTestId(/^applied-filter-End/)
      expect(endDateFilter).not.toBeNull()
      await user.click(endDateFilter as HTMLElement)
      await user.click(getByTestId('end-date-filter-type'))
      expect(getByTestId(`end-date-input`)).toBeVisible()
    })

    it('renders menu student groups correctly', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, getByRole} = render(<FilterNav {...filterProps} />)
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Student Groups'}))
      await user.click(getByTestId('Student Group 3-sorted-filter'))
      await user.click(getByTestId('applied-filter-Student Group 3'))

      expect(getByTestId('Student Group Category 1-sorted-filter-group')).toBeVisible()
      expect(getByTestId('Student Group Category 2-sorted-filter-group')).toBeVisible()
      expect(getByTestId('Student Group 1-sorted-filter-group-item')).toBeVisible()
      expect(getByTestId('Student Group 2-sorted-filter-group-item')).toBeVisible()
      expect(getByTestId('Student Group 3-sorted-filter-group-item')).toBeVisible()
      expect(getByTestId('Student Group 4-sorted-filter-group-item')).toBeVisible()
    })

    it('renders the name of the filter value when only 1 is selected', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, getByRole} = render(<FilterNav {...filterProps} />)
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      const popover = getByTestId(`applied-filter-${defaultProps.sections[0].name}`)
      expect(popover).toBeVisible()
      expect(popover).toHaveTextContent(defaultProps.sections[0].name)
    })

    it('renders the name of the filter type with how many are selected when multiple are selected', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByTestId, getByRole} = render(<FilterNav {...filterProps} />)
      await user.click(getByText('Apply Filters'))
      await user.click(getByRole('menuitemradio', {name: 'Sections'}))
      await user.click(getByRole('menuitemcheckbox', {name: 'Section 7'}))
      expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()
      await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
      await user.click(getByTestId(`${defaultProps.sections[1].name}-filter-type`))
      const popover = getByTestId(`applied-filter-Sections (2)`)
      expect(popover).toBeVisible()
      expect(popover).toHaveTextContent('Sections (2)')
    })
  })
})

describe('Filter dropdown', () => {
  beforeEach(() => {
    store.setState({
      filterPresets: defaultFilterPresets,
      appliedFilters: [],
    })
    fetchMock.mock('*', 200)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('Shows filter menu items', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    expect(getByText('Filter Preset 1')).toBeVisible()
    expect(getByText('Filter Preset 2')).toBeVisible()
    expect(getByText('Sections')).toBeVisible()
    expect(getByText('Modules')).toBeVisible()
    expect(getByText('Grading Periods')).toBeVisible()
    expect(getByText('Assignment Groups')).toBeVisible()
    expect(getByText('Student Groups')).toBeVisible()
    expect(getByText('Status')).toBeVisible()
    expect(getByText('Submissions')).toBeVisible()
    expect(getByText('Start & End Date')).toBeVisible()
  })

  it('Custom Statuses and regular statuses are shown in the status filter', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getAllByText} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Status'))
    const customStatusNames = defaultProps.customStatuses.map(status => status.name)
    const allStatusNames = [
      'Late',
      'Missing',
      'Resubmitted',
      'Dropped',
      'Excused',
      'Extended',
      ...customStatusNames,
    ]
    allStatusNames.forEach(statusName => {
      // We expect to find two here, the screenreader text and the actual filter line. We'll check against the later
      expect(getAllByText(statusName).pop()).toBeVisible()
    })
  })

  it('Clicking filter preset activates condition', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId, queryByTestId} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Filter Preset 1'))
    expect(getByTestId(`applied-filter-${defaultProps.modules[0].name}`)).toBeVisible()
    await user.click(getByText('Filter Preset 1'))
    expect(queryByTestId(`applied-filter-${defaultProps.modules[0].name}`)).toBeNull()
  })

  it('Clicking filter activates condition', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId, queryByTestId, getByRole} = render(
      <FilterNav {...defaultProps} />
    )
    expect(queryByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeNull()
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()
  })

  it('Clicking "Clear All Filters" removes all applied filters', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId, queryByTestId, getByRole} = render(
      <FilterNav {...defaultProps} />
    )
    expect(queryByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeNull()
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeVisible()
    await user.click(getByText('Clear All Filters'))
    expect(queryByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toBeNull()
  })

  it('Clicking "Clear All Filters" focuses apply filters button', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    await user.click(getByText('Clear All Filters'))
    expect(getByTestId('apply-filters-button')).toHaveFocus()
  })

  it('Check for accessability text to remove filter', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByTestId(`applied-filter-${defaultProps.sections[0].name}`)).toHaveTextContent(
      'Remove Section 7 Filter'
    )
  })

  it('selecting a filter and deselecting the same filter from the filter dropdown triggers screenreader alerts', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByText('Added Section 7 Filter')).toBeInTheDocument()
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByText('Removed Section 7 Filter')).toBeInTheDocument()
  })

  it('selecting a filter from the filter dropdown and pressing the filter pill will trigger remove filter screenreader alert', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
    expect(getByText('Removed Section 7 Filter')).toBeInTheDocument()
  })

  it('pressing the Clear All Filters button will trigger the all filters have been cleared screenreader alert', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByRole('button', {name: 'Clear All Filters'})).toBeInTheDocument()
    await user.click(getByRole('button', {name: 'Clear All Filters'}))
    expect(getByText('All Filters Have Been Cleared')).toBeInTheDocument()
  })
})

describe('FilterNav (save)', () => {
  beforeEach(() => {
    store.setState({
      filterPresets: defaultFilterPresets,
      appliedFilters: defaultAppliedFilters,
    })
    fetchMock.post('/api/v1/courses/0/gradebook_filters', mockPostResponse)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('Save button is disabled if filter preset name is blank', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Create & Manage Filter Presets'))
    await user.click(getByText('Toggle Create Filter Preset'))
    expect(getByTestId('save-filter-button')).toBeDisabled()
  })

  it.skip('clicking Save saves new filter', async () => {
    const user = userEvent.setup({...USER_EVENT_OPTIONS, delay: null})
    const {getByText, getByPlaceholderText, getByTestId, queryByTestId} = render(
      <FilterNav {...defaultProps} />
    )
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Create & Manage Filter Presets'))
    await user.click(getByText('Toggle Create Filter Preset'))
    await user.type(
      getByPlaceholderText('Give your filter preset a name'),
      'Sample filter preset name'
    )
    expect(getByTestId('delete-filter-preset-button')).toBeVisible()
    await user.click(getByTestId('save-filter-button'))
    expect(queryByTestId('save-filter-button')).toBeNull()
  })
})
