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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {IconBlock} from '../IconBlock'
import {type IconBlockProps} from '../types'
import {IconBlockToolbar} from '../IconBlockToolbar'

const user = userEvent.setup()

let props: IconBlockProps = {...IconBlock.craft.defaultProps}

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props: IconBlock.craft.defaultProps,
      }
    }),
    useEditor: jest.fn(() => {
      return {
        query: {
          getSerializedNodes: jest.fn(() => ({})),
        },
      }
    }),
  }
})

describe('IconBlockToolbar', () => {
  beforeEach(() => {
    props = {...IconBlock.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<IconBlockToolbar />)

    expect(getByText('Select Icon')).toBeInTheDocument()
  })

  it('checks the right size', async () => {
    const {getByText} = render(<IconBlockToolbar />)

    const btn = getByText('Size').closest('button') as HTMLButtonElement
    await user.click(btn)

    const smMenuItem = screen.getByText('Small')
    const medMenuItem = screen.getByText('Medium')
    const lgMenuItem = screen.getByText('Large')

    expect(smMenuItem).toBeInTheDocument()
    expect(medMenuItem).toBeInTheDocument()
    expect(lgMenuItem).toBeInTheDocument()

    const li = smMenuItem?.parentElement?.parentElement as HTMLLIElement
    expect(li?.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('changes the size prop', async () => {
    const {getByText} = render(<IconBlockToolbar />)

    const btn = getByText('Size').closest('button') as HTMLButtonElement
    await user.click(btn)

    const lgMenuItem = screen.getByText('Large')
    await user.click(lgMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.size).toBe('large')
  })

  it('changes the iconName prop on changing the icon', async () => {
    const {getByText} = render(<IconBlockToolbar />)

    const btn = getByText('Select Icon').closest('button') as HTMLButtonElement
    await user.click(btn)

    const atom_icon = screen.getByTitle('atom')
    await user.click(atom_icon)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.iconName).toBe('atom')
  })

  it('sets the color prop', async () => {
    const {getByText} = render(<IconBlockToolbar />)

    const btn = getByText('Color').closest('button') as HTMLButtonElement
    await user.click(btn)

    const customColor = screen.getByLabelText('Custom').closest('input') as HTMLInputElement
    await user.click(customColor)

    const redInput = screen.getByLabelText('Input field for red') as HTMLInputElement
    await user.type(redInput, '255', {initialSelectionStart: 0, initialSelectionEnd: 3})

    const applybtn = getByText('Apply').closest('button') as HTMLButtonElement
    await user.click(applybtn)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.color).toBe('#ff0000')
  })
})
