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
import {render} from '@testing-library/react'
import {AccessibilityIssue, FormType} from '../../../../types'
import Form, {FormHandle} from '../index'

describe('Form', () => {
  const createMockIssue = (formType: FormType, formValue?: string): AccessibilityIssue => ({
    id: '1',
    ruleId: 'test-rule',
    message: 'Test issue',
    why: 'Test why',
    element: 'div',
    path: '//div',
    form: {
      type: formType,
      label: 'Test label',
      value: formValue,
    },
  })

  describe('getValue method for FormType.Checkbox', () => {
    it('returns "false" when issue.form.value is "true"', () => {
      const mockIssue = createMockIssue(FormType.Checkbox, 'true')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('false')
    })

    it('returns "true" when issue.form.value is "false"', () => {
      const mockIssue = createMockIssue(FormType.Checkbox, 'false')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('true')
    })

    it('returns "true" when issue.form.value is undefined', () => {
      const mockIssue = createMockIssue(FormType.Checkbox, undefined)
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('true')
    })

    it('returns "true" when issue.form.value is null', () => {
      const mockIssue = createMockIssue(FormType.Checkbox, null as any)
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('true')
    })

    it('returns "true" when issue.form.value is empty string', () => {
      const mockIssue = createMockIssue(FormType.Checkbox, '')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('true')
    })
  })

  describe('getValue method for other FormTypes', () => {
    it('returns current value for FormType.TextInput', () => {
      const mockIssue = createMockIssue(FormType.TextInput, 'initial-value')
      const ref = React.createRef<FormHandle>()

      render(<Form issue={mockIssue} ref={ref} />)

      expect(ref.current?.getValue()).toBe('initial-value')
    })

    it('returns current value for FormType.DropDown', () => {
      const mockIssue = createMockIssue(FormType.DropDown, 'selected-option')
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
  })
})
