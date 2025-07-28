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

import React, {useState} from 'react'
import numberHelper from '@canvas/i18n/numberHelper'
import {FormMessage} from '@instructure/ui-form-field/types/FormPropTypes'
import {NumberInput} from '@instructure/ui-number-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('editGroup')

export type GroupLimitInputProps = {
  id: string,
  initialValue?: string,
}

const GroupLimitInput = ({
  id,
  initialValue = '',
}: GroupLimitInputProps) => {
  const [limitValue, setLimitValue] = useState<string>(initialValue)
  const [errorMessages, setErrorMessages] = useState<FormMessage[]>([])

  const validateInput = (_event: React.FocusEvent<HTMLInputElement>) => {
    if (limitValue) {
      let errorText
      if (Number.isNaN(Number(limitValue)) || !Number.isInteger(Number(limitValue))) {
        errorText = I18n.t('Value must be a whole number')
      } else if (numberHelper.parse(Number(limitValue)) < 2) {
        errorText = I18n.t('Value must be greater than or equal to 2')
      }
      if (errorText) setErrorMessages([{ text: errorText, type: 'newError' }])
    }
  }

  const handleInputChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setErrorMessages([])
    setLimitValue(value)
  }

  const label = (
    <Text size='small' weight='bold'>
      {I18n.t('Maximum members per group')}
    </Text>
  )

  return (
    <View as='div' margin='small 0'>
      <NumberInput
        id={`group_limit_input_${id}`}
        placeholder={I18n.t('Leave blank for no limit')}
        renderLabel={label}
        messages={errorMessages}
        name='group_limit'
        value={limitValue}
        onBlur={validateInput}
        onChange={handleInputChange}
        allowStringValue={true}
        showArrows={false}
        width='294px'
        data-testid={`group_limit_input_${id}`}
      />
    </View>
  )
}

export default GroupLimitInput
