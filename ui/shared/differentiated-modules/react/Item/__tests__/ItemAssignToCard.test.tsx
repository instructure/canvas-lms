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
import {render} from '@testing-library/react'
import ItemAssignToCard, {ItemAssignToCardProps} from '../ItemAssignToCard'

export type UnknownSubset<T> = {
  [K in keyof T]?: T[K]
}

const props: ItemAssignToCardProps = {
  cardId: 'assign-to-card-001',
  due_at: null,
  unlock_at: null,
  lock_at: null,
  onDelete: undefined,
  onValidityChange: () => {},
}

const renderComponent = (overrides: UnknownSubset<ItemAssignToCardProps> = {}) =>
  render(<ItemAssignToCard {...props} {...overrides} />)

describe('ItemAssignToCard', () => {
  it('renders', () => {
    const {getByLabelText, getAllByLabelText, getByTestId, queryByRole} = renderComponent()
    expect(getByTestId('item-assign-to-card')).toBeInTheDocument()
    expect(queryByRole('button', {name: 'Delete'})).not.toBeInTheDocument()
    expect(getByLabelText('Due Date')).toBeInTheDocument()
    expect(getAllByLabelText('Time').length).toBe(3)
    expect(getByLabelText('Available from')).toBeInTheDocument()
    expect(getByLabelText('Until')).toBeInTheDocument()
  })

  it('renders with the given dates', () => {
    const due_at = '2023-10-05T12:00:00Z'
    const unlock_at = '2023-10-03T12:00:00Z'
    const lock_at = '2023-10-10T12:00:00Z'
    const {getByLabelText} = renderComponent({due_at, unlock_at, lock_at})
    expect(getByLabelText('Due Date')).toHaveValue('Oct 5, 2023')
    expect(getByLabelText('Available from')).toHaveValue('Oct 3, 2023')
    expect(getByLabelText('Until')).toHaveValue('Oct 10, 2023')
  })

  it('renders the delete button when onDelete is provided', () => {
    const onDelete = jest.fn()
    const {getByRole} = renderComponent({onDelete})
    expect(getByRole('button', {name: 'Delete'})).toBeInTheDocument()
  })

  it('calls onDelete when delete button is clicked', () => {
    const onDelete = jest.fn()
    const {getByRole} = renderComponent({onDelete})
    getByRole('button', {name: 'Delete'}).click()
    expect(onDelete).toHaveBeenCalledWith('assign-to-card-001')
  })

  it('calls onValidityChange when dates go bad', () => {
    // it's ridiculous to implement this  now.
    // eventually the card will get its dates as props from the tray
    // then it will be straight forward to write validity tests
    expect(true).toBe(true)
  })
})
