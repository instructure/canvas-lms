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

import React, {useEffect, useState, useRef} from 'react'
import {FormMessage} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import numberHelper from '@canvas/i18n/numberHelper'
import round from '@canvas/round'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('editAssignmentGroupWeights')

export type GroupWeightInputProps = {
  groupId: number,
  name: string,
  canChangeWeights: boolean,
  initialValue?: string
}

const GroupWeightInput = ({
  groupId,
  name,
  canChangeWeights,
  initialValue = ''
}: GroupWeightInputProps) => {
  const [weightValue, setWeightValue] = useState<string>(initialValue)
  const [errorMessages, setErrorMessages] = useState<FormMessage[]>([])
  const inputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.classList.add('group_weight_value')
    }
  }, [])

  const handleInputChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setErrorMessages([])
    setWeightValue(value)
  }

  const handleInputBlur = (_event: React.FocusEvent<HTMLInputElement>) => {
    if (weightValue && isNaN(numberHelper.parse(weightValue))) {
      setErrorMessages([{type: 'newError', text: I18n.t('Must be a valid number')}])
    } else {
      setWeightValue(round(numberHelper.parse(weightValue), 2).toString())
    }
  }

  const handleIncrement = (_event: React.KeyboardEvent<HTMLInputElement> | React.MouseEvent<HTMLButtonElement>) => {
    const newValue = parseFloat(weightValue || '0') + 1
    setWeightValue(newValue.toString())
  }

  const handleDecrement = (_event: React.KeyboardEvent<HTMLInputElement> | React.MouseEvent<HTMLButtonElement>) => {
    const newValue = parseFloat(weightValue || '0') - 1
    setWeightValue(newValue.toString())
  }

  return (
    <NumberInput
      id={`ag_${groupId}_weight_input`}
      inputRef={(element) => inputRef.current = element}
      renderLabel ={<ScreenReaderContent>{I18n.t('Group weight for: %{groupName}', {groupName: name})}</ScreenReaderContent>}
      name={`${name}_group_weight`}
      interaction={canChangeWeights ? 'enabled' : 'readonly'}
      onBlur={handleInputBlur}
      value={weightValue}
      onChange={handleInputChange}
      allowStringValue={true}
      onIncrement={handleIncrement}
      onDecrement={handleDecrement}
      data-testid={`ag_${groupId}_weight_input`}
      messages={errorMessages}
      width='170px'
    />
  )
}

export default GroupWeightInput