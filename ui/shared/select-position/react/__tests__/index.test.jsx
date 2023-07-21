/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import SelectPosition from '../index'
import {render, fireEvent} from '@testing-library/react'

describe('SelectPosition', () => {
  it("shows the title of the item you're moving", () => {
    const {getByText} = render(
      <SelectPosition
        items={[{id: '1', title: 'Item 1', groupId: '1'}]}
        siblings={[
          {id: '2', title: 'Item 2', groupId: '1'},
          {id: '3', title: 'Item 3', groupId: '1'},
        ]}
      />
    )
    expect(getByText(/Place "Item 1"/)).toBeInTheDocument()
  })

  it("doesn't show the title if there is more than one item", () => {
    const {queryByText} = render(
      <SelectPosition
        items={[
          {id: '1', title: 'Item 1', groupId: '1'},
          {id: '2', title: 'Item 2', groupId: '1'},
        ]}
        siblings={[
          {id: '2', title: 'Assignments 2', groupId: '2'},
          {id: '3', title: 'Assignments 3', groupId: '3'},
        ]}
      />
    )
    expect(queryByText(/Place "Item 1"/)).not.toBeInTheDocument()
  })

  it('shows the sibling selection box with relative positions', () => {
    const {getByText} = render(
      <SelectPosition
        items={[{id: '1', title: 'Item 1', groupId: '1'}]}
        siblings={[
          {id: '2', title: 'Item 2', groupId: '1'},
          {id: '3', title: 'Item 3', groupId: '1'},
        ]}
        selectedPosition={{type: 'relative'}}
      />
    )
    expect(getByText(/Item Select/)).toBeInTheDocument()
    expect(getByText(/Item 2/)).toBeInTheDocument()
  })

  it("doesn't show the sibling selection box with absolute positions", () => {
    const {queryByText} = render(
      <SelectPosition
        items={[{id: '1', title: 'Item 1', groupId: '1'}]}
        siblings={[
          {id: '2', title: 'Item 2', groupId: '1'},
          {id: '3', title: 'Item 3', groupId: '1'},
        ]}
        selectedPosition={{type: 'absolute'}}
      />
    )
    expect(queryByText(/Item Select/)).not.toBeInTheDocument()
    expect(queryByText(/Item 2/)).not.toBeInTheDocument()
  })

  it('calls setPosition when you choose a position', () => {
    const selectPosition = jest.fn()
    const {getByTestId} = render(
      <SelectPosition
        items={[{id: '1', title: 'Item 1', groupId: '1'}]}
        siblings={[
          {id: '2', title: 'Item 2', groupId: '1'},
          {id: '3', title: 'Item 3', groupId: '1'},
        ]}
        selectedPosition={{type: 'absolute'}}
        selectPosition={selectPosition}
      />
    )
    fireEvent.change(getByTestId('select-position'), {target: {value: 'after'}})
    expect(selectPosition).toHaveBeenCalled()
  })

  it('calls setSibling when you choose a sibling', () => {
    const selectSibling = jest.fn()
    const {getByTestId} = render(
      <SelectPosition
        items={[{id: '1', title: 'Item 1', groupId: '1'}]}
        siblings={[
          {id: '2', title: 'Item 2', groupId: '1'},
          {id: '3', title: 'Item 3', groupId: '1'},
        ]}
        selectedPosition={{type: 'relative'}}
        selectSibling={selectSibling}
      />
    )
    fireEvent.change(getByTestId('select-sibling'), {target: {value: 'Item 3'}})
    expect(selectSibling).toHaveBeenCalled()
  })
})
