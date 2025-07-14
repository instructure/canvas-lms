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
import {SortOrder, SortBy} from '../../../utils/constants'

const makeProps = (props = {}): StudentHeaderProps => {
  return {
    sorting: {
      sortOrder: SortOrder.ASC,
      setSortOrder: jest.fn(),
      sortBy: SortBy.Name,
      setSortBy: jest.fn(),
    },
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
    fireEvent.click(getByText('Sort Students'))
    expect(getByText('Sort Order')).toBeInTheDocument()
    expect(getByText('Ascending')).toBeInTheDocument()
    expect(getByText('Descending')).toBeInTheDocument()
  })

  it('renders sorting options for student attributes', () => {
    const {getByText} = render(<StudentHeader {...makeProps()} />)
    fireEvent.click(getByText('Sort Students'))
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
    fireEvent.click(getByText('Sort Students'))
    fireEvent.click(getByText('Ascending'))
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.ASC)
  })

  it('calls setSortOrder with descending order when "Descending" is selected', () => {
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    fireEvent.click(getByText('Sort Students'))
    fireEvent.click(getByText('Descending'))
    expect(props.sorting.setSortOrder).toHaveBeenCalledWith(SortOrder.DESC)
  })

  it('calls setSortBy when a sort by option is selected', () => {
    const props = makeProps()
    const {getByText} = render(<StudentHeader {...props} />)
    const menu = getByText('Sort Students')
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
})
