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

import React, {forwardRef, useCallback, useImperativeHandle, useRef, useState} from 'react'

import ColorPickerForm from './ColorPickerForm'
import TextInputForm from './TextInputForm'
import RadioInputGroupForm from './RadioInputGroupForm'
import CheckboxTextInputForm from './CheckboxTextInput'
import {AccessibilityIssue, FormType, FormValue} from '../../../types'
import {PreviewHandle} from '../Preview'

export interface FormHandle {
  getValue: () => FormValue
  focus: () => void
}

export interface FormComponentHandle {
  focus: () => void
  getValue?: () => FormValue
}

export interface FormComponentProps extends FormProps {
  onChangeValue: (formValue: FormValue) => void
  value: FormValue
}

interface FormProps {
  issue: AccessibilityIssue
  error?: string | null
  onReload?: (formValue: FormValue) => void
  onClearError?: () => void
  onValidationChange?: (isValid: boolean, errorMessage?: string) => void
  isDisabled?: boolean
  previewRef?: React.RefObject<PreviewHandle>
  onGenerateLoadingChange?: (loading: boolean) => void
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
>(
  (
    {
      issue,
      error,
      onReload,
      onClearError,
      onValidationChange,
      isDisabled,
      previewRef,
      onGenerateLoadingChange,
    }: FormProps,
    ref,
  ) => {
    const formRef = useRef<FormComponentHandle>(null)
    const [value, setValue] = useState<FormValue>(issue.form.value || null)

    const handleChange = useCallback(
      (formValue: FormValue) => {
        setValue(formValue)

        if (error) onClearError?.()
      },
      [setValue, error, onClearError],
    )

    useImperativeHandle(ref, () => ({
      getValue: () => {
        if (issue.form.type === FormType.Button) return 'true'
        if (formRef.current?.getValue) {
          return formRef.current.getValue()
        }
        return value
      },
      focus: () => {
        formRef.current?.focus()
      },
    }))

    if (issue.form.type === FormType.Button) return null

    const FormComponent = FormTypeMap[issue.form.type]
    return (
      <FormComponent
        ref={formRef}
        issue={issue}
        value={value}
        error={error}
        onChangeValue={handleChange}
        onReload={onReload}
        onValidationChange={onValidationChange}
        isDisabled={isDisabled}
        previewRef={previewRef}
        onGenerateLoadingChange={onGenerateLoadingChange}
      />
    )
  },
)

export default Form
