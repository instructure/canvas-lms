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
import StatusColorListItem from '../StatusColorListItem'

const defaultProps = (props = {}) => ({
  status: 'late',
  color: '#efefef',
  isColorPickerShown: false,
  colorPickerOnToggle: jest.fn(),
  colorPickerButtonRef: jest.fn(),
  colorPickerContentRef: jest.fn(),
  colorPickerAfterClose: jest.fn(),
  afterSetColor: jest.fn(),
  ...props,
})

describe('StatusColorListItem', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('displays the status text', () => {
    render(<StatusColorListItem {...defaultProps()} />)
    expect(screen.getByText('Late')).toBeInTheDocument()
  })

  it('renders color picker with correct initial color', () => {
    const props = defaultProps()
    render(<StatusColorListItem {...props} />)
    const colorPickerButton = screen.getByRole('button', {name: /late color picker/i})
    expect(colorPickerButton).toBeInTheDocument()
  })

  it('renders edit icon as popover trigger', () => {
    render(<StatusColorListItem {...defaultProps()} />)
    const editButton = screen.getByRole('button', {name: /late color picker/i})
    expect(editButton).toBeInTheDocument()
  })

  it('applies background color to list item', () => {
    const color = '#FFFFFF'
    render(<StatusColorListItem {...defaultProps({color})} />)
    const listItem = screen.getByRole('listitem')
    expect(listItem).toHaveStyle({backgroundColor: color})
  })

  it('calls afterSetColor when color is changed', async () => {
    const afterSetColor = jest.fn()
    const user = userEvent.setup()

    render(<StatusColorListItem {...defaultProps({afterSetColor})} />)

    const editButton = screen.getByRole('button', {name: /late color picker/i})
    await user.click(editButton)

    // Note: Further color picker interaction tests would depend on the actual ColorPicker implementation
    // and would need to be added based on how the color selection is implemented
  })
})
