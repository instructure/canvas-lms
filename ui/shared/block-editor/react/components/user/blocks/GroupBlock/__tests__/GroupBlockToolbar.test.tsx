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
import {GroupBlock, GroupBlockToolbar} from '..'

let props = {...GroupBlock.craft.defaultProps}

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  return {
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        props: GroupBlock.craft.defaultProps,
      }
    }),
  }
})

describe('GroupBlockToolbar', () => {
  beforeEach(() => {
    props = {...GroupBlock.craft.defaultProps}
  })

  it('should render', () => {
    const {getByText} = render(<GroupBlockToolbar />)

    expect(getByText('Layout direction')).toBeInTheDocument()
    expect(getByText('Align Horizontally')).toBeInTheDocument()
    expect(getByText('Align Vertically')).toBeInTheDocument()
  })

  describe('layout direction', () => {
    it('checks the right layout direction', async () => {
      const {getByText} = render(<GroupBlockToolbar />)

      const btn = getByText('Layout direction').closest('button') as HTMLButtonElement
      await userEvent.click(btn)

      const colMenuItem = screen.getByText('Column')
      const rowMenuItem = screen.getByText('Row')

      expect(colMenuItem).toBeInTheDocument()
      expect(rowMenuItem).toBeInTheDocument()

      const li = colMenuItem.closest('li') as HTMLLIElement
      expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
    })

    it('changes the direction prop', async () => {
      const {getByText} = render(<GroupBlockToolbar />)

      const btn = getByText('Layout direction').closest('button') as HTMLButtonElement
      await userEvent.click(btn)

      const rowMenuItem = screen.getByText('Row')
      await userEvent.click(rowMenuItem)

      expect(mockSetProp).toHaveBeenCalled()
      expect(props.layout).toBe('row')
    })
  })

  describe('horizontal alignment', () => {
    it('checks the right alignment', async () => {
      const {getByText} = render(<GroupBlockToolbar />)

      const btn = getByText('Align Horizontally').closest('button') as HTMLButtonElement
      await userEvent.click(btn)

      const startMenuItem = screen.getByText('Align to start')
      const centerMenuItem = screen.getByText('Align to center')
      const endMenuItem = screen.getByText('Align to end')

      expect(startMenuItem).toBeInTheDocument()
      expect(centerMenuItem).toBeInTheDocument()
      expect(endMenuItem).toBeInTheDocument()

      const startLi = startMenuItem.closest('li') as HTMLLIElement
      expect(startLi.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
    })

    it('changes the alignment prop', async () => {
      const {getByText} = render(<GroupBlockToolbar />)

      const btn = getByText('Align Horizontally').closest('button') as HTMLButtonElement
      await userEvent.click(btn)

      const centerMenuItem = screen.getByText('Align to center')
      await userEvent.click(centerMenuItem)

      expect(mockSetProp).toHaveBeenCalled()
      expect(props.alignment).toBe('center')
    })
  })

  describe('vertical alignment', () => {
    it('checks the right alignment', async () => {
      const {getByText} = render(<GroupBlockToolbar />)

      const btn = getByText('Align Vertically').closest('button') as HTMLButtonElement
      await userEvent.click(btn)

      const startMenuItem = screen.getByText('Align to start')
      const centerMenuItem = screen.getByText('Align to center')
      const endMenuItem = screen.getByText('Align to end')

      expect(startMenuItem).toBeInTheDocument()
      expect(centerMenuItem).toBeInTheDocument()
      expect(endMenuItem).toBeInTheDocument()

      const startLi = startMenuItem.closest('li') as HTMLLIElement
      expect(startLi.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
    })

    it('changes the vertical alignment prop', async () => {
      const {getByText} = render(<GroupBlockToolbar />)

      const btn = getByText('Align Vertically').closest('button') as HTMLButtonElement
      await userEvent.click(btn)

      const centerMenuItem = screen.getByText('Align to center')
      await userEvent.click(centerMenuItem)

      expect(mockSetProp).toHaveBeenCalled()
      expect(props.verticalAlignment).toBe('center')
    })
  })
})
