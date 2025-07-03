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

const TextInputForm = ({issue, value, onChangeValue}: FormComponentProps) => {
  return (
    <View as="div" margin="small 0">
      <TextInput
        data-testid="text-input-form"
        renderLabel={issue.form.label}
        display="inline-block"
        width="15rem"
        value={value || ''}
        onChange={(_, value) => onChangeValue(value)}
      />
    </View>
  )
}

export default TextInputForm
