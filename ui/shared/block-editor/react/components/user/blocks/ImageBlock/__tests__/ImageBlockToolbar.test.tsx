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
import {ImageBlock, type ImageBlockProps} from '..'
import {ImageBlockToolbar} from '../ImageBlockToolbar'

const user = userEvent.setup()

let props = {...ImageBlock.craft.defaultProps} as Partial<ImageBlockProps>

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(_node => {
      return {
        props,
        actions: {setProp: mockSetProp},
        node: {
          dom: document.createElement('img'),
        },
        domnode: document.createElement('img'),
      }
    }),
  }
})

describe('ImageBlockToolbar', () => {
  beforeEach(() => {
    props = {...ImageBlock.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<ImageBlockToolbar />)

    expect(getByText('Upload Image')).toBeInTheDocument()
    expect(getByText('Constraint')).toBeInTheDocument()
    expect(getByText('Image Size')).toBeInTheDocument()
  })

  it('checks the right constraint', async () => {
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Constraint').closest('button') as HTMLButtonElement
    await user.click(btn)

    const coverMenuItem = screen.getByText('Cover')
    const containMenuItem = screen.getByText('Contain')

    expect(coverMenuItem).toBeInTheDocument()
    expect(containMenuItem).toBeInTheDocument()

    const li = coverMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('changes the constraint prop', async () => {
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Constraint').closest('button') as HTMLButtonElement
    await user.click(btn)

    const containMenuItem = screen.getByText('Contain')
    await user.click(containMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.constraint).toBe('contain')
  })

  it('shows the size popup', async () => {
    props.width = 117
    props.height = 217
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Image Size').closest('button') as HTMLButtonElement
    await user.click(btn)

    expect(screen.getByText('Image size')).toBeInTheDocument()
    expect(screen.getByText('Width')).toBeInTheDocument()
    expect(screen.getByText('Height')).toBeInTheDocument()
    expect(screen.getByText('117')).toBeInTheDocument()
    expect(screen.getByText('217')).toBeInTheDocument()
  })

  it('sets the width and height props', async () => {
    props.width = 117
    props.height = 217
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Image Size').closest('button') as HTMLButtonElement
    await user.click(btn)
    expect(screen.getByText('Image size')).toBeInTheDocument()
    expect(screen.getByText('Width')).toBeInTheDocument()
    expect(screen.getByText('Height')).toBeInTheDocument()
    expect(screen.getByText('117')).toBeInTheDocument()
    expect(screen.getByText('217')).toBeInTheDocument()

    const widthInput = screen.getByLabelText('Width') as HTMLInputElement
    fireEvent.change(widthInput, {target: {value: '119'}})

    expect(screen.getByText('119')).toBeInTheDocument()
    expect(screen.getByText('221')).toBeInTheDocument()

    const setButton = screen.getByText('Set').closest('button') as HTMLButtonElement
    expect(setButton).toBeInTheDocument()
    await user.click(setButton)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.width).toBe(119)
    expect(props.height).toBe(221)
  })
})
