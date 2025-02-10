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
import {HeadingBlock} from '../HeadingBlock'
import {type HeadingBlockProps} from '../types'
import {HeadingBlockToolbar} from '../HeadingBlockToolbar'

let props: HeadingBlockProps = {...HeadingBlock.craft.defaultProps}

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

describe('HeadingBlockToolbar', () => {
  beforeEach(() => {
    props = {...HeadingBlock.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<HeadingBlockToolbar />)

    expect(getByText('Level')).toBeInTheDocument()
  })

  it('checks the right level', async () => {
    const {getByText} = render(<HeadingBlockToolbar />)

    const btn = getByText('Level').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const h2 = screen.getByText('Heading 2')
    const h3 = screen.getByText('Heading 3')
    const h4 = screen.getByText('Heading 4')

    expect(h2).toBeInTheDocument()
    expect(h3).toBeInTheDocument()
    expect(h4).toBeInTheDocument()

    const li = h2?.parentElement?.parentElement as HTMLLIElement
    expect(li?.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('calls changes the level prop on changing the level', async () => {
    const {getByText} = render(<HeadingBlockToolbar />)

    const btn = getByText('Level').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const h3 = screen.getByText('Heading 3')
    await userEvent.click(h3)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.level).toBe('h3')
  })

  it('checks the right font size', async () => {
    props.fontSize = '3rem'
    const {getByText} = render(<HeadingBlockToolbar />)

    const btn = getByText('Font Size').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const defaultSz = screen.getByText('Default')
    const rem3 = screen.getByText('3rem')

    expect(defaultSz).toBeInTheDocument()
    expect(rem3).toBeInTheDocument()
    
    const li = rem3?.parentElement?.parentElement as HTMLLIElement
    expect(li?.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('sets the font size', async () => {
    const {getByText} = render(<HeadingBlockToolbar />)

    const btn = getByText('Font Size').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const rem3 = screen.getByText('3rem')
    await userEvent.click(rem3)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.fontSize).toBe('3rem')
  })

  it('sets the default font size', async () => {
    props.fontSize = '3rem'
    const {getByText} = render(<HeadingBlockToolbar />)

    const btn = getByText('Font Size').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const defaultSz = screen.getByText('Default')
    await userEvent.click(defaultSz)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.fontSize).toBeUndefined()
  })
})
