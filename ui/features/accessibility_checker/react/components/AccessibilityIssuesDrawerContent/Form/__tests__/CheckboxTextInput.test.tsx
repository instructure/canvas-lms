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

import {render, screen, fireEvent} from '@testing-library/react'
import CheckboxTextInput from '../CheckboxTextInput'
import {FormType} from '../../../../types'

describe('CheckboxTextInput', () => {
  const defaultProps = {
    issue: {
      id: 'test-id',
      ruleId: 'test-rule',
      message: 'Test message',
      why: 'Test why',
      element: 'test-element',
      displayName: 'Test Display Name',
      path: 'test-path',
      form: {
        type: FormType.CheckboxTextInput,
        checkboxLabel: 'Test Checkbox Label',
        checkboxSubtext: 'Test checkbox subtext',
        label: 'Test TextArea Label',
        inputDescription: 'Test input description',
        inputMaxLength: 100,
      },
    },
    value: '',
    onChangeValue: jest.fn(),
  }

  it('renders without crashing', () => {
    render(<CheckboxTextInput {...defaultProps} />)
    expect(screen.getByTestId('checkbox-text-input-form')).toBeInTheDocument()
  })

  it('displays all text elements correctly', () => {
    render(<CheckboxTextInput {...defaultProps} />)

    expect(screen.getByText('Test Checkbox Label')).toBeInTheDocument()
    expect(screen.getByText('Test checkbox subtext')).toBeInTheDocument()
    expect(screen.getByText('Test TextArea Label')).toBeInTheDocument()
    expect(screen.getByText('Test input description')).toBeInTheDocument()
    expect(screen.getByText('0/100')).toBeInTheDocument()
  })

  it('toggles checkbox and disables/enables textarea accordingly', () => {
    render(<CheckboxTextInput {...defaultProps} />)
    const checkbox = screen.getByLabelText('Test Checkbox Label')
    const textarea = screen.getByTestId('checkbox-text-input-form')

    expect(checkbox).not.toBeChecked()
    expect(textarea).toBeEnabled()

    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()
    expect(textarea).toBeDisabled()

    fireEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
    expect(textarea).toBeEnabled()
  })

  it('clears textarea value when checkbox is checked', () => {
    const propsWithValue = {
      ...defaultProps,
      value: 'test value',
    }
    render(<CheckboxTextInput {...propsWithValue} />)
    const checkbox = screen.getByLabelText('Test Checkbox Label')

    fireEvent.click(checkbox)
    expect(defaultProps.onChangeValue).toHaveBeenCalledWith('')
  })

  it('displays the provided value in textarea', () => {
    const propsWithValue = {
      ...defaultProps,
      value: 'test value',
    }
    render(<CheckboxTextInput {...propsWithValue} />)
    const textarea = screen.getByTestId('checkbox-text-input-form')
    expect(textarea).toHaveValue('test value')
  })
})
