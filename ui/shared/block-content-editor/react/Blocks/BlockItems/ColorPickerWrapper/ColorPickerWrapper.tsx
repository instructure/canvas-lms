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

import './color-picker-wrapper.css'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ColorPicker} from '@instructure/ui-color-picker'
import {ColorPickerPopover} from './ColorPickerPopover'

const I18n = createI18nScope('block_content_editor')

export type ColorPickerWrapperProps = {
  label: string
  value: string
  baseColor: string
  onChange: (value: string) => void
  baseColorLabel: string
  popoverButtonScreenReaderLabel: string
}

export const ColorPickerWrapper = ({
  label,
  value,
  baseColor,
  baseColorLabel,
  onChange,
  popoverButtonScreenReaderLabel,
}: ColorPickerWrapperProps) => {
  return (
    <ColorPicker
      label={label}
      placeholderText={I18n.t('Enter HEX')}
      popoverButtonScreenReaderLabel={popoverButtonScreenReaderLabel}
      popoverScreenReaderLabel={I18n.t('Color picker popover')}
      value={value}
      onChange={onChange}
      withAlpha
      data-colorpicker-fix
    >
      {(value, onChange, onAdd, onClose) => {
        return (
          <ColorPickerPopover
            value={value}
            valueLabel={label}
            onChange={onChange}
            onAdd={onAdd}
            onClose={onClose}
            baseColor={baseColor}
            baseColorLabel={baseColorLabel}
            maxHeight="40vh"
          />
        )
      }}
    </ColorPicker>
  )
}
