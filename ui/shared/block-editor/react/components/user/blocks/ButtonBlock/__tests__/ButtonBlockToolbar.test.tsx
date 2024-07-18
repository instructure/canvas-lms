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
import {ButtonBlock} from '../ButtonBlock'
import {ButtonBlockToolbar} from '../ButtonBlockToolbar'

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: jest.fn()},
        props: ButtonBlock.craft.defaultProps,
      }
    }),
  }
})

describe('ButtonBlockToolbar', () => {
  it('should render', () => {
    const {getByText} = render(<ButtonBlockToolbar />)

    expect(getByText('Link')).toBeInTheDocument()
    expect(getByText('Size')).toBeInTheDocument()
    expect(getByText('Style')).toBeInTheDocument()
    expect(getByText('Color')).toBeInTheDocument()
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

    const li = medMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('checks the right style', async () => {
    const {getByText} = render(<ButtonBlockToolbar />)

    const btn = getByText('Style').closest('button') as HTMLButtonElement
    await userEvent.click(btn)

    const textMenuItem = screen.getByText('Text')
    const outlinedMenuItem = screen.getByText('Outlined')
    const filledMenuItem = screen.getByText('Filled')

    expect(textMenuItem).toBeInTheDocument()
    expect(outlinedMenuItem).toBeInTheDocument()
    expect(filledMenuItem).toBeInTheDocument()

    const li = filledMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
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
