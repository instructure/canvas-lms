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
  ]
}

const defaultProps: FilterNavFilterProps = {
  filter: defaultFilter,
  applyConditions: () => ({}),
  isApplied: false,
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

describe('FilterNavFilter', () => {
  it('clicking delete triggers onDelete', () => {
    const onDelete = jest.fn()
    const {getByTestId} = render(<FilterNavFilter {...defaultProps} onDelete={onDelete} />)
    userEvent.click(getByTestId('delete-filter'))
    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('after renaming filter, focus should transfer to rename button', async () => {
    const onChange = jest.fn()
    const {getByPlaceholderText, getByTestId} = render(
      <FilterNavFilter {...defaultProps} onChange={onChange} />
    )
    userEvent.click(getByTestId('rename-filter'))
    userEvent.paste(getByPlaceholderText('Name'), 'Sample filter name')
    userEvent.click(getByTestId('save-label'))
    expect(getByTestId('rename-filter')).toHaveFocus()
  })
})
