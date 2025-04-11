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
import {render, screen, waitFor} from '@testing-library/react'
import {getByText as domGetByText} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useEditor, useNode} from '@craftjs/core'
import {ButtonBlock, type ButtonBlockProps} from '..'
import {ButtonBlockToolbar} from '../ButtonBlockToolbar'

let props: Partial<ButtonBlockProps>

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        node: {
          dom: undefined,
        },
        props,
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

describe('ButtonBlockToolbar', () => {
  beforeEach(() => {
    props = {...ButtonBlock.craft.defaultProps} as Partial<ButtonBlockProps>
  })

  it('should render', () => {
    const {getByText, getByTitle} = render(<ButtonBlockToolbar />)

    expect(getByText('Filled')).toBeInTheDocument()
    expect(getByText('Button Text/Link*')).toBeInTheDocument()
    expect(getByText('Color')).toBeInTheDocument()
    expect(getByText('Size')).toBeInTheDocument()
    expect(getByTitle('Style')).toBeInTheDocument()
    expect(getByText('Select Icon')).toBeInTheDocument()
  })

  it('checks the right size', async () => {
    const {getByText} = render(<ButtonBlockToolbar />)

    const btn = getByText('Size').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const smMenuItem = screen.getByText('Small')
    const medMenuItem = screen.getByText('Medium')
    const lgMenuItem = screen.getByText('Large')

    expect(smMenuItem).toBeInTheDocument()
    expect(medMenuItem).toBeInTheDocument()
    expect(lgMenuItem).toBeInTheDocument()
    const li = medMenuItem.parentElement as HTMLLIElement

    await waitFor(() => {
      expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
    })
  })

  it('changes the size prop', async () => {
    const {getByText} = render(<ButtonBlockToolbar />)

    const btn = getByText('Size').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const lgMenuItem = screen.getByText('Large')
    await userEvent.click(lgMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.size).toBe('large')
  })

  it('checks the right variant', async () => {
    const {getByTitle} = render(<ButtonBlockToolbar />)

    const btn = getByTitle('Style').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const menu = screen.getByRole('menu')
    const textMenuItem = domGetByText(menu, 'Text')
    const outlinedMenuItem = domGetByText(menu, 'Outlined')
    const filledMenuItem = domGetByText(menu, 'Filled')

    expect(textMenuItem).toBeInTheDocument()
    expect(outlinedMenuItem).toBeInTheDocument()
    expect(filledMenuItem).toBeInTheDocument()

    const li = filledMenuItem.parentElement as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('changes the variant prop', async () => {
    const {getByTitle} = render(<ButtonBlockToolbar />)

    const btn = getByTitle('Style').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const menu = screen.getByRole('menu')
    const outlinedMenuItem = domGetByText(menu, 'Outlined')
    await userEvent.click(outlinedMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.variant).toBe('outlined')
  })

  it('selects the right icon', async () => {
    props.iconName = 'apple'
    const {getByText} = render(<ButtonBlockToolbar />)

    const btn = getByText('Select Icon').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    // the selected icon
    const icon = screen.getByTitle('apple').closest('div[role="button"]') as HTMLElement
    expect(icon).toBeInTheDocument()
    expect(icon).toHaveAttribute('class', 'icon-picker__icon selected')

    // not selected icon
    const otherIcon = screen.getByTitle('alarm').closest('div[role="button"]') as HTMLElement
    expect(otherIcon).toBeInTheDocument()
    expect(otherIcon).toHaveAttribute('class', 'icon-picker__icon')
  })

  it('chages the icon prop', async () => {
    const {getByText} = render(<ButtonBlockToolbar />)

    const btn = getByText('Select Icon').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const icon = screen.getAllByTitle('apple')[0]
    expect(icon).toBeInTheDocument()
    await userEvent.click(icon)
    expect(props.iconName).toBe('apple')
  })

  // jest is loading the commonjs version
  // @instructure/ui-color-picker/lib/ColorMixer/index.js
  // I get ReferenceError: colorToHex8 is not defined,
  // though it works in canvas using esm modules
  // skipping for now (maybe vitest handles esm modules?)
  // it('checks the right color', async () => {
  //   const {getByText} = render(<ButtonBlockToolbar />)

  //   const btn = getByText('Color').closest('button') as HTMLButtonElement
  //   await userEvent.click(btn)

  //   const colorModal = await screen.findByRole('dialog')
  //   expect(colorModal).toBeInTheDocument()

  //   const primaryColor = screen.getByRole('radio', {name: 'Primary'})
  //   expect(primaryColor).toBeChecked()
  // })
})
