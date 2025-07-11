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

import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {FormComponentProps} from '.'

const ColorPickerForm = ({issue, value, onChangeValue, onReload}: FormComponentProps) => {
  return (
    <View as="div" margin="small 0">
      <TextInput
        data-testid="color-input-form"
        renderLabel={issue.form.label}
        display="inline-block"
        value={value || ''}
        onChange={(_, newValue) => {
          onChangeValue(newValue)
          onReload?.(newValue)
        }}
      />
    </View>
  )
}

export default ColorPickerForm
