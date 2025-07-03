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

import React from 'react'
import {render, screen, fireEvent} from '@testing-library/react'
import AccessibilityIssueForm from '../AccessibilityIssueForm'
import {AccessibilityIssue, FormType} from '../../../types'

const baseIssue: AccessibilityIssue = {
  id: '1',
  ruleId: 'label',
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
  it('renders text input and handles change', () => {
    const issue = {
      ...baseIssue,
      form: {
        ...baseIssue.form,
        type: FormType.TextInput,
        label: 'Label text',
        value: 'initial',
      },
    }
    const issueFormState = new Map([[issue.id, 'initial']])
    const setIssueFormState = jest.fn()
    const handleFormChange = jest.fn()

    render(
      <AccessibilityIssueForm
        issue={issue}
        issueFormState={issueFormState}
        setIssueFormState={setIssueFormState}
        handleFormChange={handleFormChange}
      />,
    )

    const input = screen.getByTestId('text-input-form').querySelector('input') as HTMLInputElement
    expect(input?.value).toBe('initial')
    fireEvent.change(input, {target: {value: 'New label'}})
    expect(handleFormChange).toHaveBeenCalledWith(issue, 'New label')
  })

  it('renders checkbox and toggles correctly', () => {
    const checkboxIssue = {
      ...baseIssue,
      form: {...baseIssue.form, type: FormType.Checkbox},
    }
    const issueFormState = new Map([['1', 'false']])
    const setIssueFormState = jest.fn()
    const handleFormChange = jest.fn()

    render(
      <AccessibilityIssueForm
        issue={checkboxIssue}
        issueFormState={issueFormState}
        setIssueFormState={setIssueFormState}
        handleFormChange={handleFormChange}
      />,
    )

    fireEvent.click(screen.getByLabelText('Label text'))
    expect(handleFormChange).toHaveBeenCalledWith(checkboxIssue, 'true')
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

    const issueFormState = new Map([['1', 'Option 2']])
    const setIssueFormState = jest.fn()
    const handleFormChange = jest.fn()

    render(
      <AccessibilityIssueForm
        issue={dropdownIssue}
        issueFormState={issueFormState}
        setIssueFormState={setIssueFormState}
        handleFormChange={handleFormChange}
      />,
    )

    const select = screen.getByLabelText('Dropdown Label') as HTMLSelectElement
    fireEvent.click(select)
    fireEvent.click(screen.getByText('Option 2'))

    expect(handleFormChange).toHaveBeenCalledWith(dropdownIssue, 'Option 2')
  })
})
