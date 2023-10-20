/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {AddressBookItem} from '../AddressBookItem'

const defaultProps = {
  id: '1',
  name: 'Test Entry',
}

const setup = props => {
  return render(<AddressBookItem {...props}>{props.name}</AddressBookItem>)
}

describe('Address Book Component', () => {
  describe('Rendering', () => {
    it('Should render', () => {
      const component = setup(defaultProps)
      expect(component).toBeTruthy()
    })

    it('Should render before icon when provided', async () => {
      const mockIcon = <span data-testid="mockicon" />
      const {findByTestId} = setup({...defaultProps, iconBefore: mockIcon})
      expect(await findByTestId('mockicon')).toBeInTheDocument()
    })

    it('Should render after icon when provided', async () => {
      const mockIcon = <span data-testid="mockicon" />
      const {findByTestId} = setup({...defaultProps, iconAfter: mockIcon})
      expect(await findByTestId('mockicon')).toBeInTheDocument()
    })

    it('Should render aria-hasPopup when set', async () => {
      const {container} = setup({...defaultProps, hasPopup: true})
      expect(container.querySelector('li').getAttribute('aria-haspopup')).toBe('true')
    })

    it('Should highlight when isSelected is true', () => {
      const {container} = setup({...defaultProps, isSelected: true})
      expect(container.querySelector('li').getAttribute('data-selected')).toBe('true')
    })

    it('Should highlight when isSelected is false', () => {
      const {container} = setup({...defaultProps, isSelected: false})
      expect(container.querySelector('li').getAttribute('data-selected')).toBe('false')
    })

    it('Should highlight when mouse is hovering', async () => {
      const {container} = setup({...defaultProps, isSelected: false})
      fireEvent.mouseOver(container)

      await waitFor(() => container.querySelector('li').getAttribute('data-selected') === 'true')
      expect(container.querySelector('li').getAttribute('data-selected')).toBe('false')
    })
  })

  describe('Behaviors', () => {
    it('Should call back when selected via mouse', () => {
      const mockFunction = jest.fn()
      const {container} = setup({...defaultProps, onSelect: mockFunction})
      fireEvent.mouseDown(container.querySelector('li'))
      expect(mockFunction.mock.calls.length).toBe(1)
    })
  })
})
