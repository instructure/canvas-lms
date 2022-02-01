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
import type {Filter} from '../../gradebook.d'
import {render, fireEvent} from '@testing-library/react'
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
  ]
}

const defaultFilters: Filter[] = [
  {
    id: '1',
    name: 'Unnamed Filter',
    conditions: [
      {
        id: '2',
        type: 'module',
        created_at: new Date().toISOString()
      }
    ],
    is_applied: true,
    created_at: new Date().toISOString()
  }
]

describe('FilterNav', () => {
  beforeEach(() => {
    store.setState({filters: defaultFilters})
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

  it('opens tray', () => {
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(getByText('Filters'))
    expect(getByRole('heading')).toHaveTextContent('Gradebook Filters')
  })

  it('renders new filter button', () => {
    const {getByText, getByRole} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(getByText('Filters'))
    expect(getByRole('button', {name: /Create New Filter/})).toBeInTheDocument()
  })

  it('clicking Create New Filter triggers onChange with filter', async () => {
    store.setState({filters: []})
    const {getByText, queryByRole, getByRole} = render(<FilterNav {...defaultProps} />)
    expect(queryByRole('button', {name: /Save/})).toBeNull()
    fireEvent.click(getByText('Filters'))
    fireEvent.click(getByRole('button', {name: /Create New Filter/}))
    expect(getByRole('button', {name: /Save/})).toBeVisible()
  })

  it('Shows condition type placeholder', () => {
    const {getByText, getByPlaceholderText} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(getByText('Filters'))
    expect(getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
  })

  it('Shows condition placeholder; selection triggers change', async () => {
    const {getByText, getByRole, getByLabelText} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(getByText('Filters'))
    expect(getByRole('button', {name: 'Condition'})).not.toHaveValue('Module 2')
    fireEvent.click(getByLabelText('Condition'))
    fireEvent.click(getByRole('option', {name: 'Module 2'}))
    expect(getByRole('button', {name: 'Condition'})).toHaveValue('Module 2')
  })

  it('Deletes condition', () => {
    const {getByText, getByRole, queryByRole, getByPlaceholderText} = render(
      <FilterNav {...defaultProps} />
    )
    fireEvent.click(getByText('Filters'))
    expect(getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
    expect(queryByRole('button', {name: /Delete condition/})).toBeVisible()
    fireEvent.click(getByRole('button', {name: /Delete condition/}))
    expect(queryByRole('button', {name: /Delete condition/})).toBeNull()
  })

  it('Disables filter', () => {
    const {getByPlaceholderText, getByRole, getByText} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(getByText('Filters'))
    expect(getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
    const checkbox = getByRole('checkbox', {name: /Apply filter/})
    expect(checkbox).toBeChecked()
    fireEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
  })

  it('Enables filter', () => {
    store.setState({filters: [{...defaultFilters[0], is_applied: false}]})
    const {getByText, getByRole, getByPlaceholderText} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(getByText('Filters'))
    expect(getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
    const checkbox = getByRole('checkbox', {name: /Apply filter/})
    expect(checkbox).not.toBeChecked()
    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()
  })
})
