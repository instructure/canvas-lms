/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {ColumnCountPopup} from '../ColumnCountPopup'

const user = userEvent.setup()

let props = {columns: 2}

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props,
      }
    }),
  }
})

describe('ColumnCountPopup', () => {
  beforeEach(() => {
    props = {columns: 2}
  })

  it('should render the trigger', () => {
    const {getByText} = render(<ColumnCountPopup {...props} />)
    expect(getByText('Columns')).toBeInTheDocument()
    expect(getByText('Columns').closest('button')).toBeInTheDocument()
  })

  it('should render the popup', async () => {
    const {getByText} = render(<ColumnCountPopup {...props} />)
    const btn = getByText('Columns').closest('button') as HTMLButtonElement
    await user.click(btn)
    const colinput = await screen.findByLabelText('Columns 1-4')
    expect(colinput).toBeInTheDocument()
    expect(screen.getByLabelText('Set the number of columns')).toBeInTheDocument()
  })

  it('shows the right column count', async () => {
    const {getByText} = render(<ColumnCountPopup {...props} />)

    const btn = getByText('Columns').closest('button') as HTMLButtonElement
    await user.click(btn)

    const two = screen.queryByDisplayValue('2')
    const three = screen.queryByText('3')

    expect(two).toBeInTheDocument()
    expect(three).not.toBeInTheDocument()
  })

  it('changes the columns prop on changing the count', async () => {
    const {getByText} = render(<ColumnCountPopup {...props} />)

    const btn = getByText('Columns').closest('button') as HTMLButtonElement
    await user.click(btn)

    const colinput = await screen.findByLabelText('Columns 1-4')

    fireEvent.change(colinput, {target: {value: '3'}})

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.columns).toBe(3)
  })
})
