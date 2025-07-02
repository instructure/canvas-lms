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

import AccessibilityIssueForm from '../Form'
import {AccessibilityIssue, FormType} from '../../../types'

const baseIssue: AccessibilityIssue = {
  id: '1',
  ruleId: 'adjacent-links',
  path: '/html/body/div[1]',
  message: 'Missing label',
  form: {
    type: FormType.TextInput,
    label: 'Label text',
    value: '',
    options: [],
  },
  why: '',
  element: '',
}

describe('AccessibilityIssueForm', () => {
  it('renders text input and handles change', async () => {
    const textInputIssue = {
      ...baseIssue,
      form: {
        ...baseIssue.form,
        value: 'initial',
      },
    }
    const handleFormChange = jest.fn()

    render(<AccessibilityIssueForm issue={textInputIssue} onChange={handleFormChange} />)

    const input = screen.getByTestId('text-input-form')
    expect(input).toHaveValue('initial')
    await userEvent.clear(input)
    await userEvent.type(input, 'New label')
    expect(handleFormChange).toHaveBeenCalledWith('New label')
  })

  it('renders checkbox and toggles correctly', async () => {
    const checkboxIssue = {
      ...baseIssue,
      form: {...baseIssue.form, type: FormType.Checkbox},
    }
    const handleFormChange = jest.fn()

    render(<AccessibilityIssueForm issue={checkboxIssue} onChange={handleFormChange} />)

    await userEvent.click(screen.getByLabelText('Label text'))
    expect(handleFormChange).toHaveBeenCalledWith('true')
  })

  it('renders dropdown and handles selection', async () => {
    const dropdownIssue = {
      ...baseIssue,
      form: {
        ...baseIssue.form,
        type: FormType.DropDown,
        label: 'Dropdown Label',
        options: ['Option 1', 'Option 2'],
        value: 'Option 1',
      },
    }
    const handleFormChange = jest.fn()

    render(<AccessibilityIssueForm issue={dropdownIssue} onChange={handleFormChange} />)

    const select = screen.getByLabelText('Dropdown Label')
    await userEvent.click(select)
    await userEvent.click(screen.getByText('Option 2'))

    expect(handleFormChange).toHaveBeenCalledWith('Option 2')
  })
})
