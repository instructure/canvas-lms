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

import React, {forwardRef, useRef, useImperativeHandle} from 'react'

import {FormComponentHandle, FormComponentProps} from '.'
import ContrastRatioForm from './ContrastRatioForm'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

const ColorPickerForm: React.FC<FormComponentProps & React.RefAttributes<FormComponentHandle>> =
  forwardRef<FormComponentHandle, FormComponentProps>(
    ({issue, error, onChangeValue}: FormComponentProps, ref) => {
      const colorPickerInputRef = useRef<HTMLInputElement | null>(null)

      useImperativeHandle(ref, () => ({
        focus: () => {
          colorPickerInputRef.current?.focus()
        },
      }))

      return (
        <ContrastRatioForm
          label={issue?.form?.titleLabel || I18n.t('Contrast Ratio')}
          inputLabel={issue.form.inputLabel || I18n.t('New Color')}
          options={issue.form.options}
          backgroundColor={issue.form.backgroundColor}
          foregroundColor={issue.form.value}
          contrastRatio={issue.form.contrastRatio}
          onChange={onChangeValue}
          inputRef={el => (colorPickerInputRef.current = el)}
          messages={error ? [{text: error, type: 'newError'}] : []}
        />
      )
    },
  )

export default ColorPickerForm
