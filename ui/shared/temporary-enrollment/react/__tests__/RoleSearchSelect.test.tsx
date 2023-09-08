/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import RoleSearchSelect from '../RoleSearchSelect'

const props = {
  placeholder: 'Select a Role',
  label: 'Select a Role',
  isLoading: false,
  noResultsLabel: 'empty results',
  noSearchMatchLabel: 'empty search',
  onChange: jest.fn(),
  id: '',
  value: '',
}

const roleOptions = [
  <RoleSearchSelect.Option key="12" id="12" value="Teacher" label="Teacher" />,
  <RoleSearchSelect.Option key="13" id="13" value="Student" label="Student" />,
]

describe('RoleSearchSelect', () => {
  it('shows options on click', () => {
    const {getByText, queryByText} = render(
      <RoleSearchSelect {...props}>{roleOptions}</RoleSearchSelect>
    )
    const select = getByText('Select a Role')
    fireEvent.click(select)
    expect(queryByText('Teacher')).toBeInTheDocument()
    expect(queryByText('Student')).toBeInTheDocument()
  })

  it('shows options starting with the input letter', () => {
    const {getByPlaceholderText, queryByText} = render(
      <RoleSearchSelect {...props}>{roleOptions}</RoleSearchSelect>
    )
    const select = getByPlaceholderText('Select a Role')
    fireEvent.click(select)
    fireEvent.input(select, {target: {value: 't'}})
    expect(queryByText('Teacher')).toBeInTheDocument()
    expect(queryByText('Student')).not.toBeInTheDocument()
  })

  it('hides options when not focused on select', () => {
    const {queryByText} = render(<RoleSearchSelect {...props}>{roleOptions}</RoleSearchSelect>)
    expect(queryByText('Teacher')).not.toBeInTheDocument()
    expect(queryByText('Student')).not.toBeInTheDocument()
  })

  it('calls onChange when user clicks an option', () => {
    const {getByText} = render(<RoleSearchSelect {...props}>{roleOptions}</RoleSearchSelect>)
    const select = getByText('Select a Role')
    fireEvent.click(select)
    fireEvent.click(getByText('Teacher'))
    expect(props.onChange).toHaveBeenCalled()
  })
})
