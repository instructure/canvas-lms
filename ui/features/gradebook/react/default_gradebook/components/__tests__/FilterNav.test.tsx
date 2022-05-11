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
import type {Filter, FilterCondition} from '../../gradebook.d'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

const originalState = store.getState()

const defaultProps: FilterNavProps = {
  modules: [
    {id: '1', name: 'Module 1', position: 1},
    {id: '2', name: 'Module 2', position: 2},
    {id: '3', name: 'Module 3', position: 3}
  ],
  assignmentGroups: [
    {id: '4', name: 'Assignment Group 4', position: 1, group_weight: 0, assignments: []},
    {id: '5', name: 'Assignment Group 5', position: 2, group_weight: 0, assignments: []},
    {id: '6', name: 'Assignment Group 6', position: 3, group_weight: 0, assignments: []}
  ],
  sections: [
    {id: '7', name: 'Section 7'},
    {id: '8', name: 'Section 8'},
    {id: '9', name: 'Section 9'}
  ],
  gradingPeriods: [
    {id: '1', title: 'Grading Period 1', startDate: 1},
    {id: '2', title: 'Grading Period 2', startDate: 2},
    {id: '3', title: 'Grading Period 3', startDate: 3}
  ],
  studentGroupCategories: {
    '1': {
      id: '1',
      name: 'Student Group Category 1',
      groups: [
        {id: '1', name: 'Student Group 1'},
        {id: '2', name: 'Student Group 2'}
      ]
    }
  }
}

const defaultAppliedFilterConditions: FilterCondition[] = [
  {
    id: '2',
    type: 'module',
    value: '1',
    created_at: new Date().toISOString()
  }
]

const defaultFilters: Filter[] = [
  {
    id: '1',
    name: 'Filter 1',
    conditions: [
      {
        id: '2',
        type: 'module',
        value: '1',
        created_at: '2022-02-05T10:18:34-07:00'
      }
    ],
    created_at: '2022-02-05T10:18:34-07:00'
  },
  {
    id: '2',
    name: 'Filter 2',
    conditions: [
      {
        id: '3',
        type: 'section',
        value: '7',
        created_at: new Date().toISOString()
      }
    ],
    created_at: '2022-02-06T10:18:34-07:00'
  }
]

const mockPostResponse = {
  gradebook_filter: {
    id: '25',
    course_id: '0',
    user_id: '1',
    name: 'test',
    payload: {
      conditions: [
        {
          id: 'f783e528-dbb5-4474-972a-0f1a19c29551',
          type: 'section',
          value: '2',
          created_at: '2022-02-08T17:18:13.190Z'
        }
      ]
    },
    created_at: '2022-02-08T10:18:34-07:00',
    updated_at: '2022-02-08T10:18:34-07:00'
  }
}

describe('FilterNav', () => {
  beforeEach(() => {
    store.setState({
      filters: defaultFilters,
      appliedFilterConditions: defaultAppliedFilterConditions
    })
    fetchMock.mock('*', 200)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('renders filters button', async () => {
    const {getByRole} = render(<FilterNav {...defaultProps} />)
    await getByRole('button', {name: 'Filters'})
  })

  it('renders Applied Filters text', async () => {
    const {findByText} = render(<FilterNav {...defaultProps} />)
    await findByText(/Applied Filters:/)
  })

  it('render condition tag for applied staged filter', async () => {
    store.setState({
      stagedFilterConditions: [
        {
          id: '4',
          type: 'module',
          value: '1',
          created_at: new Date().toISOString()
        },
        {
          id: '5',
          type: undefined,
          value: undefined,
          created_at: new Date().toISOString()
        }
      ]
    })
    const {getAllByTestId} = render(<FilterNav {...defaultProps} />)
    expect(await getAllByTestId('staged-filter-condition-tag')[0]).toHaveTextContent('Module 1')
  })

  it('opens tray', () => {
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    userEvent.click(getByText('Filters'))
    expect(getByRole('heading')).toHaveTextContent('Gradebook Filters')
  })

  it('shows friendly panda image when there are no filters', async () => {
    store.setState({filters: [], stagedFilterConditions: []})
    const {getByAltText, getByText} = render(<FilterNav {...defaultProps} />)
    userEvent.click(getByText('Filters'))
    expect(await getByAltText('Friendly panda')).toBeInTheDocument()
  })

  it('hides friendly panda image when there are filters', async () => {
    const {queryByAltText, getByText} = render(<FilterNav {...defaultProps} />)
    userEvent.click(getByText('Filters'))
    expect(await queryByAltText('Friendly panda')).toBeNull()
  })

  it('renders new filter button', () => {
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    userEvent.click(getByText('Filters'))
    expect(getByRole('button', {name: /Create New Filter/})).toBeInTheDocument()
  })

  it('clicking Create New Filter triggers onChange with filter', async () => {
    store.setState({filters: []})
    const {getByText, queryByRole, getByRole} = render(<FilterNav {...defaultProps} />)
    expect(queryByRole('button', {name: /Save/})).toBeNull()
    userEvent.click(getByText('Filters'))
    userEvent.click(getByRole('button', {name: /Create New Filter/}))
    expect(getByRole('button', {name: /Save/})).toBeVisible()
  })

  it('Shows condition type placeholder', () => {
    const {getByText, getAllByPlaceholderText} = render(<FilterNav {...defaultProps} />)
    userEvent.click(getByText('Filters'))
    expect(getAllByPlaceholderText(/Select condition type/)[0]).toBeInTheDocument()
  })

  it('Shows condition placeholder; selection triggers change', async () => {
    const {getByText, getByRole, getAllByRole, getAllByLabelText} = render(
      <FilterNav {...defaultProps} />
    )
    userEvent.click(getByText('Filters'))
    expect(getAllByRole('button', {name: 'Condition'})[0]).not.toHaveValue('Module 2')
    userEvent.click(getAllByLabelText('Condition')[0])
    userEvent.click(getByRole('option', {name: 'Module 2'}))
    expect(getAllByRole('button', {name: 'Condition'})[0]).toHaveValue('Module 2')
  })

  it('Deletes condition', () => {
    const {getByText, getAllByRole, queryAllByRole, getAllByPlaceholderText} = render(
      <FilterNav {...defaultProps} />
    )
    userEvent.click(getByText('Filters'))
    expect(getAllByPlaceholderText(/Select condition type/)[1]).toBeInTheDocument()
    expect(queryAllByRole('button', {name: /Delete condition/})[1]).toBeVisible()
    expect(queryAllByRole('button', {name: /Delete condition/}).length).toStrictEqual(2)
    userEvent.click(getAllByRole('button', {name: /Delete condition/})[1])
    expect(queryAllByRole('button', {name: /Delete condition/}).length).toStrictEqual(1)
  })

  it('Disables filter', () => {
    const {getAllByPlaceholderText, getAllByRole, getByText} = render(
      <FilterNav {...defaultProps} />
    )
    userEvent.click(getByText('Filters'))
    expect(getAllByPlaceholderText(/Select condition type/)[0]).toBeInTheDocument()
    const checkbox = getAllByRole('checkbox', {name: /Apply conditions/})[0]
    expect(checkbox).toBeChecked()
    userEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
  })

  it('Enables filter', () => {
    store.setState({filters: [{...defaultFilters[0]}], appliedFilterConditions: []})
    const {getByText, getByRole, getByPlaceholderText} = render(<FilterNav {...defaultProps} />)
    userEvent.click(getByText('Filters'))
    expect(getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
    const checkbox = getByRole('checkbox', {name: /Apply conditions/})
    expect(checkbox).not.toBeChecked()
    userEvent.click(checkbox)
    expect(checkbox).toBeChecked()
  })
})

describe('FilterNav (save)', () => {
  beforeEach(() => {
    store.setState({
      filters: defaultFilters,
      appliedFilterConditions: defaultAppliedFilterConditions
    })
    fetchMock.post('/api/v1/courses/0/gradebook_filters', mockPostResponse)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('Save button is disabled if filter name is blank', async () => {
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    userEvent.click(getByText('Filters'))
    userEvent.click(getByRole('button', {name: /Create New Filter/}))
    expect(getByRole('button', {name: /Save/})).toBeDisabled()
  })

  it('clicking Save saves new filter', async () => {
    const {getByText, queryByRole, getByPlaceholderText, getByRole} = render(
      <FilterNav {...defaultProps} />
    )
    userEvent.click(getByText('Filters'))
    userEvent.click(getByRole('button', {name: /Create New Filter/}))
    userEvent.type(getByPlaceholderText('Give this filter a name'), 'Sample filter name')
    expect(getByRole('button', {name: /Save/})).toBeVisible()
    userEvent.click(getByRole('button', {name: /Save/}))
    await waitFor(() => expect(queryByRole('button', {name: /Save/})).toBeNull())
  })
})
