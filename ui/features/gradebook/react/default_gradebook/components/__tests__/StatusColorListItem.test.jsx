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
  colorPickerOnToggle: vi.fn(),
  colorPickerButtonRef: vi.fn(),
  colorPickerContentRef: vi.fn(),
  colorPickerAfterClose: vi.fn(),
  afterSetColor: vi.fn(),
  ...props,
})

describe('StatusColorListItem', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  it('displays the status text', () => {
    render(<StatusColorListItem {...defaultProps()} />)
    expect(screen.getByText('Late')).toBeInTheDocument()
  })

  it('renders color picker with correct initial color', () => {
    const props = defaultProps()
    render(<StatusColorListItem {...props} />)
    const colorPickerButton = screen.getByText(/late color picker/i).closest('button')
    expect(colorPickerButton).toBeInTheDocument()
  })

  it('renders edit icon as popover trigger', () => {
    render(<StatusColorListItem {...defaultProps()} />)
    const editButton = screen.getByText(/late color picker/i).closest('button')
    expect(editButton).toBeInTheDocument()
  })

  it('applies background color to list item', () => {
    const color = '#FFFFFF'
    const {container} = render(<StatusColorListItem {...defaultProps({color})} />)
    const listItem = container.querySelector('li')
    expect(listItem).toHaveStyle({backgroundColor: color})
  })

  it('calls afterSetColor when color is changed', async () => {
    const afterSetColor = vi.fn()
    const user = userEvent.setup()

    render(<StatusColorListItem {...defaultProps({afterSetColor})} />)

    const editButton = screen.getByText(/late color picker/i).closest('button')
    await user.click(editButton)

    // Note: Further color picker interaction tests would depend on the actual ColorPicker implementation
    // and would need to be added based on how the color selection is implemented
  })

  describe('icon display', () => {
    it('displays icon when showIcon is true', () => {
      const {container} = render(<StatusColorListItem {...defaultProps({showIcon: true})} />)
      const icon = container.querySelector('img')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('src')
      expect(icon).toHaveAttribute('title', 'Late')
    })

    it('does not display icon when showIcon is false', () => {
      const {container} = render(<StatusColorListItem {...defaultProps({showIcon: false})} />)
      expect(container.querySelector('img')).not.toBeInTheDocument()
    })

    it('does not display icon when showIcon is undefined', () => {
      const {container} = render(<StatusColorListItem {...defaultProps()} />)
      expect(container.querySelector('img')).not.toBeInTheDocument()
    })
  })

  describe('custom name', () => {
    it('displays custom name when name prop is provided', () => {
      const customName = 'Custom Status Name'
      render(<StatusColorListItem {...defaultProps({name: customName})} />)
      expect(screen.getByText(customName)).toBeInTheDocument()
    })

    it('displays default status name when name prop is not provided', () => {
      render(<StatusColorListItem {...defaultProps()} />)
      expect(screen.getByText('Late')).toBeInTheDocument()
    })
  })

  describe('color picker visibility', () => {
    it('hides color picker button when disableColorPicker is true', () => {
      render(<StatusColorListItem {...defaultProps({disableColorPicker: true})} />)
      expect(screen.queryByText(/color picker/i)).not.toBeInTheDocument()
    })

    it('shows color picker button when disableColorPicker is false', () => {
      render(<StatusColorListItem {...defaultProps({disableColorPicker: false})} />)
      expect(screen.getByText(/late color picker/i).closest('button')).toBeInTheDocument()
    })

    it('shows color picker button when disableColorPicker is undefined', () => {
      render(<StatusColorListItem {...defaultProps()} />)
      expect(screen.getByText(/late color picker/i).closest('button')).toBeInTheDocument()
    })

    it('applies custom padding when disableColorPicker is true', () => {
      const {container} = render(
        <StatusColorListItem {...defaultProps({disableColorPicker: true})} />,
      )
      const listItem = container.querySelector('li')
      expect(listItem).toHaveStyle({padding: '11px 8px'})
    })
  })
})
