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
import {render, fireEvent} from '@testing-library/react'
import {StudentHeader, StudentHeaderProps} from '../StudentHeader'
import {SortOrder, SortBy, NameDisplayFormat} from '../../../utils/constants'

const makeProps = (props = {}): StudentHeaderProps => {
  return {
    sorting: {
      sortOrder: SortOrder.ASC,
      setSortOrder: jest.fn(),
      sortBy: SortBy.Name,
      setSortBy: jest.fn(),
    },
    nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
    onChangeNameDisplayFormat: jest.fn(),
    ...props,
  }
}

describe('StudentHeader', () => {
  it('renders a "Student" cell', () => {
    const {getByText} = render(<StudentHeader {...makeProps()} />)
    expect(getByText('Students')).toBeInTheDocument()
  })

  it('renders a menu with various sorting options', () => {
    const {getByText} = render(<StudentHeader {...makeProps()} />)
    fireEvent.click(getByText('Student Options'))
    expect(getByText('Sort Order')).toBeInTheDocument()
    expect(getByText('Ascending')).toBeInTheDocument()
    expect(getByText('Descending')).toBeInTheDocument()
  })

  it('renders sorting options for student attributes', () => {
    const {getByText} = render(<StudentHeader {...makeProps()} />)
    fireEvent.click(getByText('Student Options'))
    expect(getByText('Sort By')).toBeInTheDocument()
    expect(getByText('Name')).toBeInTheDocument()
    expect(getByText('Sortable Name')).toBeInTheDocument()
    expect(getByText('SIS ID')).toBeInTheDocument()
    expect(getByText('Integration ID')).toBeInTheDocument()
    expect(getByText('Login ID')).toBeInTheDocument()
  })

  it('calls setSortOrder when a sorting option is selected', () => {
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    fireEvent.click(getByText('Student Options'))
    fireEvent.click(getByText('Ascending'))
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.ASC)
  })

  it('calls setSortOrder with descending order when "Descending" is selected', () => {
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    fireEvent.click(getByText('Student Options'))
    fireEvent.click(getByText('Descending'))
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.DESC)
  })

  it('calls setSortBy when a sort by option is selected', () => {
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    const menu = getByText('Student Options')
    fireEvent.click(menu)
    fireEvent.click(getByText('Name'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.Name)

    fireEvent.click(menu)
    fireEvent.click(getByText('Sortable Name'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.SortableName)

    fireEvent.click(menu)
    fireEvent.click(getByText('SIS ID'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.SisId)

    fireEvent.click(menu)
    fireEvent.click(getByText('Integration ID'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.IntegrationId)

    fireEvent.click(menu)
    fireEvent.click(getByText('Login ID'))
    expect(props.sorting.setSortBy).toHaveBeenCalledWith(SortBy.LoginId)
  })

  describe('Display as menu', () => {
    it('renders Display as menu group with name format options', () => {
      const {getByText} = render(<StudentHeader {...makeProps()} />)
      fireEvent.click(getByText('Student Options'))
      expect(getByText('Display as')).toBeInTheDocument()
      expect(getByText('First, Last Name')).toBeInTheDocument()
      expect(getByText('Last, First Name')).toBeInTheDocument()
    })

    it('selects First, Last Name when nameDisplayFormat is FIRST_LAST', () => {
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.FIRST_LAST})
      const {getByText} = render(<StudentHeader {...props} />)
      fireEvent.click(getByText('Student Options'))
      const firstLastItem = getByText('First, Last Name').closest('[role="menuitemradio"]')
      expect(firstLastItem).toHaveAttribute('aria-checked', 'true')
    })

    it('selects Last, First Name when nameDisplayFormat is LAST_FIRST', () => {
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.LAST_FIRST})
      const {getByText} = render(<StudentHeader {...props} />)
      fireEvent.click(getByText('Student Options'))
      const lastFirstItem = getByText('Last, First Name').closest('[role="menuitemradio"]')
      expect(lastFirstItem).toHaveAttribute('aria-checked', 'true')
    })

    it('calls onChangeNameDisplayFormat with FIRST_LAST when First, Last Name is selected', () => {
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.LAST_FIRST})
      const {getByText} = render(<StudentHeader {...props} />)
      fireEvent.click(getByText('Student Options'))
      fireEvent.click(getByText('First, Last Name'))
      expect(props.onChangeNameDisplayFormat).toHaveBeenCalledWith(NameDisplayFormat.FIRST_LAST)
    })

    it('calls onChangeNameDisplayFormat with LAST_FIRST when Last, First Name is selected', () => {
      const props = makeProps({nameDisplayFormat: NameDisplayFormat.FIRST_LAST})
      const {getByText} = render(<StudentHeader {...props} />)
      fireEvent.click(getByText('Student Options'))
      fireEvent.click(getByText('Last, First Name'))
      expect(props.onChangeNameDisplayFormat).toHaveBeenCalledWith(NameDisplayFormat.LAST_FIRST)
    })
  })
})
