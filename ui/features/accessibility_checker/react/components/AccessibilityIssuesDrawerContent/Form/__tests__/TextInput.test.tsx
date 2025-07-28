/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import TextInputForm from '../TextInput'
import {FormType} from '../../../../types'

describe('TextInputForm', () => {
  const defaultProps = {
    issue: {
      id: 'test-id',
      ruleId: 'test-rule',
      displayName: 'Test rule',
      message: 'Test message',
      why: 'Test why',
      element: 'test-element',
      path: 'test-path',
      form: {
        type: FormType.TextInput,
        label: 'Test Label',
      },
    },
    value: '',
    onChangeValue: jest.fn(),
  }

  it('renders without crashing', () => {
    render(<TextInputForm {...defaultProps} />)
    expect(screen.getByTestId('text-input-form')).toBeInTheDocument()
  })

  it('displays the correct label', () => {
    render(<TextInputForm {...defaultProps} />)
    expect(screen.getByText('Test Label')).toBeInTheDocument()
  })

  it('displays the provided value', () => {
    const propsWithValue = {
      ...defaultProps,
      value: 'test value',
    }
    render(<TextInputForm {...propsWithValue} />)
    const input = screen.getByTestId('text-input-form')
    expect(input).toHaveValue('test value')
  })

  it('calls onChangeValue when the input value changes', async () => {
    render(<TextInputForm {...defaultProps} />)
    const input = screen.getByTestId('text-input-form')
    await userEvent.type(input, 'a')
    expect(defaultProps.onChangeValue).toHaveBeenCalledWith('a')
  })

  it('displays the error message when an error is provided', () => {
    const propsWithError = {
      ...defaultProps,
      error: 'Error message',
    }
    render(<TextInputForm {...propsWithError} />)
    expect(screen.getByText('Error message')).toBeInTheDocument()
  })

  it('focuses the input when the form is refocused', () => {
    const {container} = render(<TextInputForm {...defaultProps} />)
    const input = container.querySelector('input')
    expect(input).not.toHaveFocus()
    input?.focus()
    expect(input).toHaveFocus()
  })
})
