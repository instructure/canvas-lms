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

import React, {forwardRef, useEffect, useImperativeHandle, useState} from 'react'

import ColorPickerForm from './ColorPicker'
import TextInputForm from './TextInput'
import RadioInputGroupForm from './RadioInputGroupForm'
import CheckboxTextInputForm from './CheckboxTextInput'
import {AccessibilityIssue, FormType, FormValue} from '../../../types'

export interface FormHandle {
  getValue: () => FormValue
}

export interface FormComponentProps {
  issue: AccessibilityIssue
  value: FormValue
  onChangeValue: (formValue: FormValue) => void
  onReload?: (formValue: FormValue) => void
}

interface FormProps {
  issue: AccessibilityIssue
  onReload?: (formValue: FormValue) => void
}

const FormTypeMap = {
  [FormType.TextInput]: TextInputForm,
  [FormType.RadioInputGroup]: RadioInputGroupForm,
  [FormType.ColorPicker]: ColorPickerForm,
  [FormType.CheckboxTextInput]: CheckboxTextInputForm,
}

const Form: React.FC<FormProps & React.RefAttributes<FormHandle>> = forwardRef<
  FormHandle,
  FormProps
>(({issue, onReload}: FormProps, ref) => {
  const [value, setValue] = useState<FormValue>(issue.form.value || null)

  useEffect(() => {
    setValue(issue.form.value || null)
  }, [issue])

  useImperativeHandle(ref, () => ({
    getValue: () => {
      if (issue.form.type === FormType.Checkbox || issue.form.type === FormType.Button) {
        return issue.form.value === 'true' ? 'false' : 'true'
      }
      return value
    },
  }))

  if (issue.form.type === FormType.Checkbox || issue.form.type === FormType.Button) return null

  const FormComponent = FormTypeMap[issue.form.type]
  return <FormComponent issue={issue} value={value} onChangeValue={setValue} onReload={onReload} />
})

export default Form
