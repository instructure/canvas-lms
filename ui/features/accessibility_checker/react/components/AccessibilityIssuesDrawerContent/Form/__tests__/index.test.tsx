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
    displayName: 'Test rule',
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

  describe('getValue method for other FormTypes', () => {
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
})
