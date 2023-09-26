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
  onDelete: undefined,
}

const renderComponent = (overrides: UnknownSubset<ItemAssignToCardProps> = {}) =>
  render(<ItemAssignToCard {...props} {...overrides} />)

describe('ItemAssignToCard', () => {
  it('renders', () => {
    const {getByLabelText, getAllByLabelText, getByTestId, queryByRole} = renderComponent()
    expect(getByTestId('item-assign-to-card')).toBeInTheDocument()
    expect(queryByRole('button', {name: 'Delete'})).not.toBeInTheDocument()
    expect(getByLabelText('Date')).toBeInTheDocument()
    expect(getAllByLabelText('Time').length).toBe(3)
    expect(getByLabelText('Available from')).toBeInTheDocument()
    expect(getByLabelText('Until')).toBeInTheDocument()
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
})
