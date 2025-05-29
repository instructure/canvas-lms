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
import {TabsBlock} from '../TabsBlock'
import {TabsBlockToolbar} from '../TabsBlockToolbar'

let props = {...TabsBlock.craft.defaultProps}

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props: TabsBlock.craft.defaultProps,
      }
    }),
  }
})

describe('TabsBlockToolbar', () => {
  beforeEach(() => {
    props = {...TabsBlock.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<TabsBlockToolbar />)

    expect(getByText('Style')).toBeInTheDocument()
    expect(getByText('Add Tab')).toBeInTheDocument()
  })

  it('checks the right style', async () => {
    const {getByText} = render(<TabsBlockToolbar />)

    const btn = getByText('Style').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const modern = screen.getByText('Modern')
    const classic = screen.getByText('Classic')

    expect(modern).toBeInTheDocument()
    expect(classic).toBeInTheDocument()

    const li = modern?.parentElement?.parentElement as HTMLLIElement
    expect(li?.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('calls changes the level prop on changing the style', async () => {
    const {getByText} = render(<TabsBlockToolbar />)

    const btn = getByText('Style').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const classic = screen.getByText('Classic')
    await userEvent.click(classic)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.variant).toBe('classic')
  })

  it('call calls setProp with a new tab on clicking Add Tab', async () => {
    const {getByText} = render(<TabsBlockToolbar />)

    expect(props.tabs).toHaveLength(2)

    const addTab = getByText('Add Tab').closest('button') as HTMLButtonElement
    await userEvent.click(addTab)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.tabs).toHaveLength(3)
    expect(props.tabs[2].title).toBe('New Tab')
  })
})
