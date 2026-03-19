/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import ThemeEditorTextareaRow from '../ThemeEditorTextareaRow'

describe('ThemeEditorTextareaRow Component', () => {
  const defaultProps = {
    varDef: {
      variable_name: 'test_textarea',
      human_name: 'Test Textarea',
      type: 'textarea',
      default: 'Default text',
      helper_text: 'Enter your custom message here',
    },
    placeholder: 'Enter text...',
    onChange: vi.fn(),
    handleThemeStateChange: vi.fn(),
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders with human name as label', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    expect(screen.getByLabelText('Test Textarea')).toBeInTheDocument()
  })

  it('renders with helper text', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    expect(screen.getByText('Enter your custom message here')).toBeInTheDocument()
  })

  it('renders with placeholder', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveAttribute('placeholder', 'Enter text...')
  })

  it('uses userInput value when provided', () => {
    const props = {
      ...defaultProps,
      userInput: {val: 'User input text'},
      currentValue: 'Current value text',
      themeState: {test_textarea: 'Theme state text'},
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveValue('User input text')
  })

  it('uses currentValue when userInput is not provided', () => {
    const props = {
      ...defaultProps,
      currentValue: 'Current value text',
      themeState: {test_textarea: 'Theme state text'},
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveValue('Current value text')
  })

  it('uses themeState value when userInput and currentValue are not provided', () => {
    const props = {
      ...defaultProps,
      themeState: {test_textarea: 'Theme state text'},
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveValue('Theme state text')
  })

  it('uses empty string when no value is provided', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveValue('')
  })

  it('handles input changes correctly', async () => {
    const user = userEvent.setup()
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    await user.type(textarea, 'New text')
    // component is controlled; parent doesn’t update value prop on onChange
    // so each keystroke only sees that character
    expect(defaultProps.onChange).toHaveBeenLastCalledWith('t')
    expect(defaultProps.handleThemeStateChange).toHaveBeenLastCalledWith('test_textarea', 't')
    expect(defaultProps.onChange).toHaveBeenCalledTimes(8)
  })

  it('displays character count correctly', () => {
    const props = {
      ...defaultProps,
      currentValue: 'Hello',
    }
    render(<ThemeEditorTextareaRow {...props} />)
    expect(screen.getByText('5/500')).toBeInTheDocument()
  })

  it('updates character count based on current value', () => {
    const {rerender} = render(<ThemeEditorTextareaRow {...defaultProps} />)
    expect(screen.getByText('0/500')).toBeInTheDocument()
    const propsWithText = {
      ...defaultProps,
      currentValue: 'Hello World',
    }
    rerender(<ThemeEditorTextareaRow {...propsWithText} />)
    expect(screen.getByText('11/500')).toBeInTheDocument()
  })

  it('applies warning class when character count reaches 450', () => {
    const longText = 'a'.repeat(450)
    const props = {
      ...defaultProps,
      currentValue: longText,
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const charCountElement = screen.getByTestId('theme-editor-character-count')
    expect(charCountElement).toHaveClass('Theme__editor-textarea_character-count--warning')
    expect(screen.getByText('450/500')).toBeInTheDocument()
  })

  it('does not apply warning class when character count is below 450', () => {
    const props = {
      ...defaultProps,
      currentValue: 'Short text',
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const charCountElement = screen.getByTestId('theme-editor-character-count')
    expect(charCountElement).not.toHaveClass('Theme__editor-textarea_character-count--warning')
    expect(charCountElement).not.toHaveClass('Theme__editor-textarea_character-count--limit')
  })

  it('has maxLength attribute set to 500', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveAttribute('maxLength', '500')
  })

  it('displays limit message when value is at max length', () => {
    const limitText = 'a'.repeat(500)
    const props = {
      ...defaultProps,
      currentValue: limitText,
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const charCountElement = screen.getByTestId('theme-editor-character-count')
    expect(charCountElement?.textContent).toContain('character limit reached')
    expect(charCountElement?.textContent).toContain('500/500')
  })

  it('applies limit class when character count reaches 500', () => {
    const limitText = 'a'.repeat(500)
    const props = {
      ...defaultProps,
      currentValue: limitText,
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const charCountElement = screen.getByTestId('theme-editor-character-count')
    expect(charCountElement).toHaveClass('Theme__editor-textarea_character-count--limit')
    expect(charCountElement?.textContent).toContain('character limit reached')
    expect(charCountElement?.textContent).toContain('500/500')
  })

  it('has aria-describedby with helper text and character count', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    const ariaDescribedBy = textarea.getAttribute('aria-describedby')
    expect(ariaDescribedBy).toContain('brand_config[variables][test_textarea]-helper')
    expect(ariaDescribedBy).toContain('brand_config[variables][test_textarea]-count')
  })

  it('has aria-live="polite" on character count element', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    const charCountElement = screen.getByTestId('theme-editor-character-count')
    expect(charCountElement).toHaveAttribute('aria-live', 'polite')
  })

  it('has correct textarea id and name attributes', () => {
    render(<ThemeEditorTextareaRow {...defaultProps} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveAttribute('id', 'brand_config[variables][test_textarea]')
    expect(textarea).toHaveAttribute('name', 'brand_config[variables][test_textarea]')
  })

  it('uses empty string for userInput with undefined val', () => {
    const props = {
      ...defaultProps,
      userInput: {val: undefined},
      currentValue: 'Current value text',
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    expect(textarea).toHaveValue('Current value text')
  })

  it('handles clearing textarea correctly', async () => {
    const user = userEvent.setup()
    const props = {
      ...defaultProps,
      currentValue: 'Initial text',
    }
    render(<ThemeEditorTextareaRow {...props} />)
    const textarea = screen.getByTestId('theme-editor-textarea-input')
    await user.clear(textarea)
    expect(defaultProps.onChange).toHaveBeenCalledWith('')
    expect(defaultProps.handleThemeStateChange).toHaveBeenCalledWith('test_textarea', '')
  })
})
