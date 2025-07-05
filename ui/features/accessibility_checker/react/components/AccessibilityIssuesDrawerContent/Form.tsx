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

import React, {forwardRef, useImperativeHandle, useState} from 'react'

import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'

import {AccessibilityIssue, FormType, FormValue} from '../../types'
import {Button} from '@instructure/ui-buttons'

export interface FormHandle {
  getValue: () => FormValue
}

interface FormProps {
  issue: AccessibilityIssue
  onChange: (formValue: FormValue) => void
}

const Form: React.FC<FormProps & React.RefAttributes<FormHandle>> = forwardRef<
  FormHandle,
  FormProps
>(({issue, onChange}: FormProps, ref) => {
  const [value, setValue] = useState<FormValue>(issue.form.value || null)

  useImperativeHandle(ref, () => ({
    getValue: () => value,
  }))

  if (!issue.ruleId) {
    return null
  }

  // TODO: This is where specific rule forms should be rendered please add them under rules/
  // Ex. rules/AdjacentLinksForm.tsx, rules/HeadingsSequenceForm.tsx, etc.
  if (
    [
      'adjacent-links',
      'headings-sequence',
      'has-lang-entry',
      'headings-start-at-h2',
      'img-alt',
      'img-alt-filename',
      'img-alt-length',
      'large-text-contrast',
      'small-text-contrast',
      'list-structure',
      'paragraphs-for-headings',
      'table-caption',
      'table-header',
      'table-header-scope',
    ].includes(issue.ruleId)
  ) {
    switch (issue.form.type) {
      case FormType.Checkbox:
        return (
          <View as="div" margin="small 0" data-testid="checkbox-form">
            <Checkbox
              label={issue.form.label}
              checked={value === 'true'}
              onChange={() => {
                const newValue = value === 'true' ? 'false' : 'true'
                setValue(newValue)
                onChange(newValue)
              }}
            />
          </View>
        )
      case FormType.Button:
        return (
          <View as="div" margin="small 0" data-testid="button-form">
            <Button onClick={() => onChange('true')} color="primary">
              {issue.form.label}
            </Button>
          </View>
        )
      case FormType.ColorPicker:
        return (
          <View as="div" margin="small 0">
            <Text weight="bold">{issue.form.label}</Text>
          </View>
        )
      case FormType.TextInput:
        return (
          <View as="div" margin="small 0">
            <TextInput
              data-testid="text-input-form"
              renderLabel={issue.form.label}
              display="inline-block"
              width="15rem"
              value={value || ''}
              onChange={(_, value) => {
                setValue(value)
                onChange(value)
              }}
            />
          </View>
        )
      case FormType.DropDown:
        return (
          <SimpleSelect
            renderLabel={issue.form.label}
            value={value || ''}
            onChange={(_, {value}) => {
              setValue(value)
              onChange(value)
            }}
          >
            {issue.form.options?.map(option => (
              <SimpleSelect.Option
                id={option}
                key={option}
                value={option}
                selected={issue.form.value === option}
                disabled={issue.form.value !== option}
              >
                {option}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        )
      default:
        return null
    }
  }
})

export default Form
