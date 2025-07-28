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
import {NumberInput} from '@instructure/ui-number-input'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('editAssignmentGroup')

export type GroupRuleInputProps = {
  groupId: number,
  type: string,
  initialValue?: string,
  onBlur?: () => void,
  onChange?: () => void
}

const GroupRuleInput = ({
  groupId,
  type,
  initialValue = '',
  onBlur = () => {},
  onChange = () => {}
}: GroupRuleInputProps) => {
  const [ruleValue, setRuleValue] = useState<string>(initialValue)

  const handleInputChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setRuleValue(value)
    onChange()
  }

  const handleIncrement = (_event: React.KeyboardEvent<HTMLInputElement> | React.MouseEvent<HTMLButtonElement>) => {
    const newValue = Math.floor(parseFloat(ruleValue || '0')) + 1
    setRuleValue(newValue.toString())
    onChange()
  }

  const handleDecrement = (_event: React.KeyboardEvent<HTMLInputElement> | React.MouseEvent<HTMLButtonElement>) => {
    const newValue = Math.floor(parseFloat(ruleValue || '0')) - 1
    setRuleValue(newValue.toString())
    onChange()
  }

  return (
    <NumberInput
      id={`ag_${groupId}_${type}`}
      renderLabel=""
      name={`rules[${type}]`}
      onBlur={onBlur}
      value={ruleValue}
      onChange={handleInputChange}
      allowStringValue={true}
      onIncrement={handleIncrement}
      onDecrement={handleDecrement}
      data-testid={`ag_${groupId}_${type}`}
    />
  )
}

export default GroupRuleInput