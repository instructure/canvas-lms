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
import type {Assignment} from '../../../../../../api'
import {render} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

beforeEach(() => {
  // Ensure a live region for screenreader alerts exists for Alert component
  const existing = document.getElementById('flash_screenreader_holder')
  if (!existing) {
    const div = document.createElement('div')
    div.id = 'flash_screenreader_holder'
    div.setAttribute('role', 'alert')
    document.body.appendChild(div)
  }
})

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

const USER_EVENT_OPTIONS = {
  pointerEventsCheck: PointerEventsCheckLevel.Never,
}

let oldEnv: typeof window.ENV.FEATURES
beforeEach(() => {
  oldEnv = window.ENV.FEATURES
  window.ENV.FEATURES = {
    extended_submission_state: true,
  }
})

afterEach(() => {
  window.ENV.FEATURES = oldEnv
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
      <FilterNav {...defaultProps} />,
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
      <FilterNav {...defaultProps} />,
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
      'Remove Section 7 Filter',
    )
  })

  it('selecting a filter and deselecting the same filter from the filter dropdown triggers screenreader alerts', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByRole('alert')).toHaveTextContent('Added Section 7 Filter')
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByRole('alert')).toHaveTextContent('Removed Section 7 Filter')
  })

  it('selecting a filter from the filter dropdown and pressing the filter pill will trigger remove filter screenreader alert', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByTestId, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    await user.click(getByTestId(`applied-filter-${defaultProps.sections[0].name}`))
    expect(getByRole('alert')).toHaveTextContent('Removed Section 7 Filter')
  })

  it('pressing the Clear All Filters button will trigger the all filters have been cleared screenreader alert', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    await user.click(getByText('Apply Filters'))
    await user.click(getByRole('menuitemradio', {name: 'Sections'}))
    await user.click(getByRole('menuitemradio', {name: 'Section 7'}))
    expect(getByRole('button', {name: 'Clear All Filters'})).toBeInTheDocument()
    await user.click(getByRole('button', {name: 'Clear All Filters'}))
    expect(getByRole('alert')).toHaveTextContent('All Filters Have Been Cleared')
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
      <FilterNav {...defaultProps} />,
    )
    await user.click(getByText('Apply Filters'))
    await user.click(getByText('Create & Manage Filter Presets'))
    await user.click(getByText('Toggle Create Filter Preset'))
    await user.type(
      getByPlaceholderText('Give your filter preset a name'),
      'Sample filter preset name',
    )
    expect(getByTestId('delete-filter-preset-button')).toBeVisible()
    await user.click(getByTestId('save-filter-button'))
    expect(queryByTestId('save-filter-button')).toBeNull()
  })
})
