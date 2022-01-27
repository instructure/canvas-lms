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
import type {FilterNavProps} from '../FilterNav'
import {render, fireEvent, within, cleanup, screen} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'

const defaultProps: FilterNavProps = {
  onChange: () => {},
  filters: [],
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

const defaultFilters = [
  {
    id: '1',
    label: 'Unnamed Filter',
    conditions: [
      {
        id: '2',
        type: 'module',
        createdAt: new Date().toISOString()
      }
    ],
    isApplied: true,
    createdAt: new Date().toISOString()
  }
]

describe('FilterNav', () => {
  it('renders filters button', async () => {
    const {getByRole} = render(<FilterNav {...defaultProps} />)
    await getByRole('button', {name: 'Filters'})
  })

  it('renders Applied Filters text', async () => {
    const {findByText} = render(<FilterNav {...defaultProps} />)
    await findByText(/Applied Filters:/)
  })

  it('opens tray', () => {
    const {container} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByRole('heading')).toHaveTextContent('Gradebook Filters')
    cleanup()
  })

  it('renders new filter button', () => {
    const {container} = render(<FilterNav {...defaultProps} />)
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByRole('button', {name: /Create New Filter/})).toBeInTheDocument()
    cleanup()
  })

  it('clicking Create New Filter triggers onChange with filter', async () => {
    const onChange = jest.fn()
    const {container} = render(<FilterNav {...defaultProps} onChange={onChange} />)
    fireEvent.click(within(container).getByText('Filters'))
    fireEvent.click(screen.getByRole('button', {name: /Create New Filter/}))
    expect(onChange).toHaveBeenLastCalledWith([
      expect.objectContaining({
        label: expect.any(String),
        createdAt: expect.any(String),
        id: expect.any(String),
        conditions: [
          expect.objectContaining({
            createdAt: expect.any(String),
            id: expect.any(String),
            type: undefined,
            value: undefined
          })
        ],
        isApplied: true
      })
    ])
    cleanup()
  })

  it('Shows condition type placeholder', () => {
    const {container} = render(<FilterNav {...defaultProps} filters={defaultFilters} />)
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
  })

  it('Shows condition placeholder; selection triggers change', async () => {
    const onChange = jest.fn()
    const {container} = render(
      <FilterNav {...defaultProps} filters={defaultFilters} onChange={onChange} />
    )
    fireEvent.click(within(container).getByText('Filters'))
    fireEvent.click(screen.getByLabelText('Condition'))
    fireEvent.click(screen.getByRole('option', {name: /Module 2/}))
    expect(onChange).toHaveBeenLastCalledWith([
      expect.objectContaining({
        conditions: [
          expect.objectContaining({
            type: 'module',
            value: '2'
          })
        ]
      })
    ])
    cleanup()
  })

  it('Deletes condition', () => {
    const onChange = jest.fn()
    const {container} = render(
      <FilterNav {...defaultProps} filters={defaultFilters} onChange={onChange} />
    )
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', {name: /Delete condition/}))
    expect(onChange).toHaveBeenLastCalledWith([
      expect.objectContaining({
        conditions: []
      })
    ])
    cleanup()
  })

  it('Disables filter', () => {
    const onChange = jest.fn()
    const {container} = render(
      <FilterNav {...defaultProps} filters={defaultFilters} onChange={onChange} />
    )
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
    fireEvent.click(screen.getByRole('checkbox', {name: /Apply filter/}))
    expect(onChange).toHaveBeenLastCalledWith([
      expect.objectContaining({
        isApplied: false
      })
    ])
    cleanup()
  })

  it('Enables filter', () => {
    const filters = JSON.parse(JSON.stringify(defaultFilters))
    filters[0].isApplied = false
    const onChange = jest.fn()
    const {container} = render(
      <FilterNav {...defaultProps} filters={filters} onChange={onChange} />
    )
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByPlaceholderText(/Select condition type/)).toBeInTheDocument()
    fireEvent.click(screen.getByRole('checkbox', {name: /Apply filter/}))
    expect(onChange).toHaveBeenLastCalledWith([
      expect.objectContaining({
        isApplied: true
      })
    ])
    cleanup()
  })
})
