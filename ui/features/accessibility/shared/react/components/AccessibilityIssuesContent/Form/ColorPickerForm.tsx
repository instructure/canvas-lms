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

import React, {forwardRef, useRef, useImperativeHandle, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {ColorPicker} from '@instructure/ui-color-picker'
import type {FormMessage} from '@instructure/ui-form-field'
import {FormComponentHandle, FormComponentProps} from './index'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getColorMixerSettings} from '../../../utils/colorUtils'

const I18n = createI18nScope('accessibility_checker')
const SUGGESTION_MESSAGE = I18n.t(
  "Tip: Only #0000 will automatically update to white if the user's background is in dark mode.",
)
const SUGGESTED_COLORS = ['#000000', '#248029', '#9242B4', '#2063C1', '#B50000']

export type ContrastErrorCode = 'color_missing' | 'invalid_color_format'
export const COLOR_REQUIRED_MESSAGE = I18n.t('You must select a color to proceed.')
export const INVALID_COLOR_MESSAGE = I18n.t('Not a valid color.')

export const ErrorMessage: Record<ContrastErrorCode, string> = {
  color_missing: COLOR_REQUIRED_MESSAGE,
  invalid_color_format: INVALID_COLOR_MESSAGE,
}

const ColorPickerForm: React.FC<FormComponentProps & React.RefAttributes<FormComponentHandle>> =
  forwardRef<FormComponentHandle, FormComponentProps>(
    ({issue, error, onChangeValue, isDisabled}: FormComponentProps, ref) => {
      const colorPickerInputRef = useRef<HTMLInputElement | null>(null)
      const backgroundColor = issue.form.backgroundColor ?? '#FFFFFF'
      const [foregroundColor, setForegroundColor] = useState(issue.form.value || '#000000')

      useImperativeHandle(ref, () => ({
        focus: () => {
          colorPickerInputRef.current?.focus()
        },
      }))

      const handleColorChange = (newColor: string) => {
        setForegroundColor(newColor)
        onChangeValue(newColor)
      }

      const renderMessages = (): FormMessage[] => {
        if (!error) return []
        const text = ErrorMessage[error as ContrastErrorCode] || error
        return [{text, type: 'newError'}]
      }

      return (
        <View as="div" data-testid="contrast-ratio-form">
          <View as="div" style={{overflow: 'visible'}}>
            <ColorPicker
              id="a11y-color-picker"
              data-testid="color-picker"
              placeholderText={I18n.t('Enter HEX')}
              label={issue.form.inputLabel || I18n.t('New Color')}
              value={foregroundColor}
              onChange={handleColorChange}
              inputRef={el => (colorPickerInputRef.current = el)}
              disabled={isDisabled}
              isRequired
              renderMessages={renderMessages}
              renderInvalidColorMessage={() =>
                error ? [] : [{text: INVALID_COLOR_MESSAGE, type: 'newError'}]
              }
              renderIsRequiredMessage={() =>
                error ? [] : [{text: COLOR_REQUIRED_MESSAGE, type: 'newError'}]
              }
              colorMixerSettings={getColorMixerSettings(backgroundColor, SUGGESTED_COLORS)}
              popoverButtonScreenReaderLabel={I18n.t('New text color picker')}
            />
          </View>
          {backgroundColor.toUpperCase() === '#FFFFFF' && (
            <Text data-testid="suggestion-message">{SUGGESTION_MESSAGE}</Text>
          )}
        </View>
      )
    },
  )

export default ColorPickerForm
