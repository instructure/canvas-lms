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
  onSearchTextChanged: jest.fn(),
  onFilterTypeChanged: jest.fn()
}

describe('FilterControls', () => {
  it('calls onSearchTextChanged when search text is changed', () => {
    const onSearchTextChanged = jest.fn()
    const {getByPlaceholderText} = render(
      <FilterControls {...defaultProps} onSearchTextChanged={onSearchTextChanged} />
    )
    const search = getByPlaceholderText('Search Calendars')
    expect(search).toBeInTheDocument()
    expect(onSearchTextChanged).not.toHaveBeenCalled()
    fireEvent.change(search, {target: {value: 'hello'}})
    expect(onSearchTextChanged).toHaveBeenCalledWith('hello')
  })

  it('calls onFilterTypeChanged when filter is used', () => {
    const onFilterTypeChanged = jest.fn()
    const {getByRole, getByText} = render(
      <FilterControls {...defaultProps} onFilterTypeChanged={onFilterTypeChanged} />
    )
    const filter = getByRole('button', {name: 'Filter Calendars'})
    expect(filter).toBeInTheDocument()
    act(() => filter.click())
    expect(getByText('Show all')).toBeInTheDocument()
    expect(getByText('Show only enabled calendars')).toBeInTheDocument()
    const disabledCalendarsFilter = getByText('Show only disabled calendars')
    expect(disabledCalendarsFilter).toBeInTheDocument()
    expect(onFilterTypeChanged).not.toHaveBeenCalled()
    act(() => disabledCalendarsFilter.click())
    expect(onFilterTypeChanged).toHaveBeenCalledWith(FilterType.SHOW_HIDDEN)
  })
})
