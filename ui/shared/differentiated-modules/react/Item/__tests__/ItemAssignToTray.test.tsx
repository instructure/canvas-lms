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
import ItemAssignToTray, {ItemAssignToTrayProps} from '../ItemAssignToTray'

export type UnknownSubset<T> = {
  [K in keyof T]?: T[K]
}

describe('ItemAssignToTray', () => {
  const props: ItemAssignToTrayProps = {
    open: true,
    onDismiss: () => {},
    onSave: () => {},
    courseId: '1',
    moduleItemId: '2',
    moduleItemName: 'Item Name',
    moduleItemType: 'Assignment',
    pointsPossible: '10 pts',
  }

  const renderComponent = (overrides: UnknownSubset<ItemAssignToTrayProps> = {}) =>
    render(<ItemAssignToTray {...props} {...overrides} />)

  it('renders', () => {
    const {getByText, getByLabelText, getAllByTestId} = renderComponent()
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(1)
  })

  it('renders with no points', () => {
    const {getByText, queryByText, getByLabelText} = renderComponent({pointsPossible: undefined})
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment')).toBeInTheDocument()
    expect(queryByText('pts')).not.toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: 'Close'}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls onSave when save button is clicked', () => {
    const onSave = jest.fn()
    const {getByRole} = renderComponent({onSave})
    getByRole('button', {name: 'Save'}).click()
    expect(onSave).toHaveBeenCalled()
  })

  it('adds a card when add button is clicked', () => {
    const {getByRole, getAllByTestId} = renderComponent()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(1)
    getByRole('button', {name: 'Add'}).click()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
  })

  it('deletes a card when delete button is clicked', () => {
    const {getByRole, getAllByRole, getAllByTestId} = renderComponent()
    getByRole('button', {name: 'Add'}).click()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
    getAllByRole('button', {name: 'Delete'})[1].click()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(1)
  })
})
