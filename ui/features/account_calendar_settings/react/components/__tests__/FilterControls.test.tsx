/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, fireEvent, act} from '@testing-library/react'

import {FilterControls, FilterType} from '../FilterControls'

const defaultProps = {
  searchValue: '',
  filterValue: FilterType.SHOW_ALL,
  setSearchValue: jest.fn(),
  setFilterValue: jest.fn(),
}

describe('FilterControls', () => {
  it('calls setSearchValue when search text is changed', () => {
    const setSearchValue = jest.fn()
    const {getByPlaceholderText} = render(
      <FilterControls {...defaultProps} setSearchValue={setSearchValue} />
    )
    const search = getByPlaceholderText('Search Calendars')
    expect(search).toBeInTheDocument()
    expect(setSearchValue).not.toHaveBeenCalled()
    fireEvent.change(search, {target: {value: 'hello'}})
    expect(setSearchValue).toHaveBeenCalledWith('hello')
  })

  it('calls setFilterValue when filter is used', () => {
    const setFilterValue = jest.fn()
    const {getByRole, getByText} = render(
      <FilterControls {...defaultProps} setFilterValue={setFilterValue} />
    )
    const filter = getByRole('combobox', {name: 'Filter Calendars'})
    expect(filter).toBeInTheDocument()
    act(() => filter.click())
    expect(getByText('Show all')).toBeInTheDocument()
    expect(getByText('Show only enabled calendars')).toBeInTheDocument()
    const disabledCalendarsFilter = getByText('Show only disabled calendars')
    expect(disabledCalendarsFilter).toBeInTheDocument()
    expect(setFilterValue).not.toHaveBeenCalled()
    act(() => disabledCalendarsFilter.click())
    expect(setFilterValue).toHaveBeenCalledWith(FilterType.SHOW_HIDDEN)
  })
})
