/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {GroupedSelect} from '../GroupedSelect'
import userEvent from '@testing-library/user-event'
import React from 'react'

describe('GroupedSelect', () => {
  let onChangeMock: jest.Mock
  const data: React.ComponentProps<typeof GroupedSelect>['data'] = [
    {
      groupName: 'G1',
      items: [
        {itemName: 'G1-I1', id: 'image'},
        {itemName: 'G1-I2', id: 'imageText'},
      ],
    },
    {
      groupName: 'G2',
      items: [
        {itemName: 'G2-I1', id: 'simpleText'},
        {itemName: 'G2-I2', id: 'imageText'},
      ],
    },
  ]

  beforeEach(() => {
    onChangeMock = jest.fn()
  })

  it('renders grouped select with initial data', () => {
    render(<GroupedSelect data={data} onChange={onChangeMock} />)
    expect(screen.getByText(data[0].groupName)).toBeInTheDocument()
    expect(screen.getByText(data[0].items[0].itemName)).toBeInTheDocument()
    expect(screen.getByText(data[0].items[1].itemName)).toBeInTheDocument()
    expect(screen.getByText(data[1].groupName)).toBeInTheDocument()
    expect(screen.queryByText(data[1].items[0].itemName)).not.toBeInTheDocument()
    expect(screen.queryByText(data[1].items[1].itemName)).not.toBeInTheDocument()
  })

  it('selects first item by default', () => {
    render(<GroupedSelect data={data} onChange={onChangeMock} />)
    expect(onChangeMock).toHaveBeenCalledWith(data[0].items[0].id)
  })

  it('changes group and selects first item of that group', async () => {
    render(<GroupedSelect data={data} onChange={onChangeMock} />)
    const group = screen.getByText(data[1].groupName)
    await userEvent.click(group)
    expect(onChangeMock).toHaveBeenCalledWith(data[1].items[0].id)
  })

  it('selects item on click and calls onChange', async () => {
    render(<GroupedSelect data={data} onChange={onChangeMock} />)
    const item = screen.getByText(data[0].items[1].itemName)
    await userEvent.click(item)
    expect(onChangeMock).toHaveBeenCalledWith(data[0].items[1].id)
  })
})
