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
import {render, screen} from '@testing-library/react'
import {AccessibilityIssue, FormType, IssueWorkflowState} from '../../../../types'
import Form, {FormHandle} from '../index'
import userEvent from '@testing-library/user-event'

describe('Form', () => {
  const createMockIssue = (formType: FormType, formValue?: string): AccessibilityIssue => ({
    id: '1',
    ruleId: 'test-rule',
    displayName: 'Test rule',
    message: 'Test issue',
    why: 'Test why',
    element: 'div',
    path: '//div',
    workflowState: IssueWorkflowState.Active,
    form: {
      type: formType,
      label: 'Test label',
      value: formValue,
      options: ['Option A', 'Option B'],
      checkboxLabel: 'Test checkbox label',
      checkboxSubtext: 'Test checkbox subtext',
      inputDescription: 'Test input description',
      inputMaxLength: 120,
    },
  })

  describe('getValue method', () => {
    it('returns current value for FormType.TextInput', () => {
      const mockIssue = createMockIssue(FormType.TextInput, 'initial-value')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('initial-value')
    })

    it('returns current value for FormType.RadioInputGroup', () => {
      const mockIssue = createMockIssue(FormType.RadioInputGroup, 'selected-option')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('selected-option')
    })

    it('returns current value for FormType.ColorPicker', () => {
      const mockIssue = createMockIssue(FormType.ColorPicker, '#ff0000')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('#ff0000')
    })

    it('returns current value for FormType.CheckboxTextInput', () => {
      const mockIssue = createMockIssue(FormType.CheckboxTextInput, 'checkbox-text-value')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('checkbox-text-value')
    })

    it('returns current value for FormType.Button', () => {
      const mockIssue = createMockIssue(FormType.Button, 'true')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('true')
    })
  })

  describe('calls onClearError when the form value changes', () => {
    it('for FormType.TextInput', async () => {
      const onClearError = vi.fn()
      const mockIssue = createMockIssue(FormType.TextInput, 'initial-value')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} onClearError={onClearError} error="Test error" />)
      const input = screen.getByTestId('text-input-form')
      await userEvent.type(input, 'test value')
      expect(onClearError).toHaveBeenCalled()
    })

    it('for FormType.RadioInputGroup', async () => {
      const onClearError = vi.fn()
      const mockIssue = createMockIssue(FormType.RadioInputGroup, 'selected-option')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} onClearError={onClearError} error="Test error" />)

      const optionBRadio = screen.getByTestId('radio-Option B')
      await userEvent.click(optionBRadio)

      expect(onClearError).toHaveBeenCalled()
    })

    it('for FormType.ColorPicker', async () => {
      const onClearError = vi.fn()
      const mockIssue = createMockIssue(FormType.ColorPicker, '#ff0000')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} onClearError={onClearError} error="Test error" />)

      const input = screen.getByLabelText(/new color/i)
      await userEvent.clear(input)
      await userEvent.type(input, '#ff0000')

      expect(onClearError).toHaveBeenCalled()
    })

    it('for FormType.CheckboxTextInput', async () => {
      const onClearError = vi.fn()
      const mockIssue = createMockIssue(FormType.CheckboxTextInput, 'checkbox-text-value')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} onClearError={onClearError} error="Test error" />)
      const input = screen.getByTestId('checkbox-text-input-form')
      await userEvent.type(input, 'test value')
      expect(onClearError).toHaveBeenCalled()
    })
  })
})
