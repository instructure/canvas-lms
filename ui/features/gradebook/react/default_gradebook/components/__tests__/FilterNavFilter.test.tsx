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
import FilterNavFilter from '../FilterNavFilter'
import type {FilterNavFilterProps} from '../FilterNavFilter'
import type {Filter} from '../../gradebook.d'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

const defaultFilter: Filter = {
  id: '123',
  name: 'Label',
  created_at: '2021-11-02T20:56:23.615Z',
  conditions: [
    {
      id: '456',
      created_at: '2021-11-02T20:56:23.616Z',
      type: 'module',
      value: undefined
    },
    {
      id: '567',
      created_at: '2021-11-02T20:56:23.617Z',
      type: 'section',
      value: undefined
    }
  ],
  is_applied: true
}

const defaultProps: FilterNavFilterProps = {
  filter: defaultFilter,
  onChange: () => {},
  onDelete: () => {},
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

describe('FilterNavFilter', () => {
  it('clicking delete triggers onDelete', () => {
    const onDelete = jest.fn()
    const {getByRole} = render(<FilterNavFilter {...defaultProps} onDelete={onDelete} />)
    userEvent.click(getByRole('button', {name: /Delete filter/}))
    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('switching condition type triggers onChange', async () => {
    const onChange = jest.fn()
    const {getAllByRole} = render(<FilterNavFilter {...defaultProps} onChange={onChange} />)
    userEvent.click(getAllByRole('button', {name: /Condition type/})[0])
    userEvent.click(getAllByRole('option', {name: /Assignment Group/})[0])
    expect(onChange).toHaveBeenCalled()
  })

  it('after renaming filter, focus should transfer to rename button', async () => {
    const onChange = jest.fn()
    const {getByRole, getByPlaceholderText} = render(
      <FilterNavFilter {...defaultProps} onChange={onChange} />
    )
    userEvent.click(getByRole('button', {name: /Rename filter/}))
    userEvent.type(getByPlaceholderText('Name'), 'Sample filter name')
    userEvent.click(getByRole('button', {name: /Save label/}))
    expect(getByRole('button', {name: /Rename filter/})).toHaveFocus()
  })

  it('upon deleting second condition, focus transfers to delete button of previous condition', async () => {
    const onChange = jest.fn()
    const {getAllByRole} = render(<FilterNavFilter {...defaultProps} onChange={onChange} />)
    const secondDeleteButton = getAllByRole('button', {name: /Delete condition/})[1]
    secondDeleteButton.click()
    const firstDeleteButton = getAllByRole('button', {name: /Delete condition/})[0]
    expect(firstDeleteButton).toHaveFocus()
  })

  it('upon deleting first condition, focus transfers to delete button of previous condition', async () => {
    const onChange = jest.fn()
    const {getAllByRole, getByRole} = render(
      <FilterNavFilter {...defaultProps} onChange={onChange} />
    )
    const firstDeleteButton = getAllByRole('button', {name: /Delete condition/})[0]
    firstDeleteButton.click()
    const renameButton = getByRole('button', {name: /Rename filter/})
    expect(renameButton).toHaveFocus()
  })
})
