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
import ThemeEditorColorRow from '../ThemeEditorColorRow'

describe('ThemeEditorColorRow Component', () => {
  const defaultProps = {
    varDef: {
      variable_name: 'test_var',
      human_name: 'Test Variable',
      type: 'color',
      default: '#000000',
    },
    placeholder: '#FFFFFF',
    onChange: jest.fn(),
    handleThemeStateChange: jest.fn(),
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows warning in appropriate situations', () => {
    // Test not invalid case
    const validProps = {
      ...defaultProps,
      userInput: {invalid: false},
    }
    const {rerender} = render(<ThemeEditorColorRow {...validProps} />)
    const alertElement = screen.queryByRole('alert')
    expect(alertElement?.textContent || '').toBe('')

    // Test invalid but focused
    const invalidProps = {
      ...defaultProps,
      userInput: {invalid: true, val: 'invalid-color'},
    }
    rerender(<ThemeEditorColorRow {...invalidProps} />)
    const input = screen.getByRole('textbox')
    input.focus()
    expect(screen.getByTestId('warning-message')).toBeInTheDocument()

    // Test invalid and not focused
    input.blur()
    expect(screen.getByTestId('warning-message')).toBeInTheDocument()
    expect(screen.getByTestId('warning-message')).toHaveTextContent(
      "'invalid-color' is not a valid color.",
    )
  })

  it('validates color values correctly', async () => {
    const user = userEvent.setup()
    const {container} = render(<ThemeEditorColorRow {...defaultProps} />)
    const input = screen.getByRole('textbox')

    // Test invalid string
    await user.clear(input)
    await user.type(input, 'foo')
    expect(defaultProps.onChange).toHaveBeenCalledWith('foo', true)

    // Test valid hex color
    await user.clear(input)
    await user.type(input, '#fff')
    expect(defaultProps.onChange).toHaveBeenCalledWith('#fff', false)

    // Test valid color word
    await user.clear(input)
    await user.type(input, 'red')
    expect(defaultProps.onChange).toHaveBeenCalledWith('red', false)

    // Test transparent
    await user.clear(input)
    await user.type(input, 'transparent')
    expect(defaultProps.onChange).toHaveBeenCalledWith('transparent', false)

    // Test undefined/empty - simulate onChange directly
    const inputEl = container.querySelector('input')
    inputEl.value = ''
    inputEl.dispatchEvent(new Event('change'))
    expect(defaultProps.onChange).toHaveBeenCalledWith('', false)

    // Test valid rgb
    await user.clear(input)
    await user.type(input, 'rgb(123,123,123)')
    expect(defaultProps.onChange).toHaveBeenCalledWith('rgb(123,123,123)', false)

    // Test valid rgba
    await user.clear(input)
    await user.type(input, 'rgba(255, 255, 255, 255)')
    expect(defaultProps.onChange).toHaveBeenCalledWith('rgba(255, 255, 255, 255)', false)

    // Test invalid rgba
    await user.clear(input)
    await user.type(input, 'rgba(foo)')
    expect(defaultProps.onChange).toHaveBeenCalledWith('rgba(foo)', true)
  })

  it('validates hex strings correctly', async () => {
    const user = userEvent.setup()
    render(<ThemeEditorColorRow {...defaultProps} />)
    const input = screen.getByRole('textbox')

    // Test non-hex string
    await user.clear(input)
    await user.type(input, 'foo')
    expect(defaultProps.onChange).toHaveBeenCalledWith('foo', true)

    // Test invalid hex (7+ characters)
    await user.clear(input)
    await user.type(input, '#aabbccc')
    expect(defaultProps.onChange).toHaveBeenCalledWith('#aabbccc', true)

    // Test valid short hex
    await user.clear(input)
    await user.type(input, '#abcc')
    expect(defaultProps.onChange).toHaveBeenCalledWith('#abcc', true)
  })

  it('handles input changes correctly', async () => {
    const user = userEvent.setup()
    render(<ThemeEditorColorRow {...defaultProps} />)
    const input = screen.getByRole('textbox')

    // Test valid color
    await user.clear(input)
    await user.type(input, '#123456')
    expect(defaultProps.onChange).toHaveBeenCalledWith('#123456', false)
    expect(defaultProps.handleThemeStateChange).toHaveBeenCalledWith('test_var', '#123456')

    // Test invalid color
    await user.clear(input)
    await user.type(input, 'invalid')
    expect(defaultProps.onChange).toHaveBeenCalledWith('invalid', true)
    expect(defaultProps.handleThemeStateChange).not.toHaveBeenCalledWith('test_var', 'invalid')

    // Test invalid hex string
    await user.clear(input)
    await user.type(input, '#ggg')
    expect(defaultProps.onChange).toHaveBeenCalledWith('#ggg', true)
    expect(defaultProps.handleThemeStateChange).not.toHaveBeenCalledWith('test_var', '#ggg')
  })

  it('handles input focus and blur correctly', async () => {
    const user = userEvent.setup()
    render(<ThemeEditorColorRow {...defaultProps} />)

    document.body.focus()
    const input = screen.getByRole('textbox')
    expect(document.activeElement).not.toBe(input)

    await user.click(input)
    expect(document.activeElement).toBe(input)

    input.blur()
    expect(document.activeElement).not.toBe(input)
  })
})
