/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {func, string} from 'prop-types'
import {NumberInput} from '@instructure/ui-number-input'

const I18n = useI18nScope('groups')

const MIN = 1
const MAX = 100000

GroupMembershipInput.propTypes = {
  onChange: func.isRequired,
  value: string,
}

export default function GroupMembershipInput({onChange, value, ...props}) {
  const [messages, setMessages] = useState([])
  const [groupLimit, setGroupLimit] = useState('')

  useEffect(() => {
    onChange(groupLimit)
  }, [groupLimit, onChange])

  function handleIncrement() {
    // will allow increment from an empty string
    if (value === '') return validateAndSetGroupLimit(parseInt(value + 1, 10))
    if (parseInt(value, 10)) return validateAndSetGroupLimit(parseInt(value, 10) + 1)
  }

  function handleDecrement() {
    // won't allow decrement from an empty string; we'll throw an error instead
    if (value === '') return validateAndSetGroupLimit(parseInt(value - 1, 10))
    if (parseInt(value, 10)) return validateAndSetGroupLimit(parseInt(value, 10) - 1)
  }

  function handleChange(_, input) {
    if (Number.isNaN(Number(input))) {
      setGroupLimit('')
      return setMessages([
        {text: I18n.t('%{INPUT} is not a valid number.', {INPUT: input}), type: 'error'},
      ])
    }

    if (input === '') return input
    return validateAndSetGroupLimit(Math.round(input))
  }

  function handleKeyDown(e) {
    if (e.key === 'Backspace' && value < 10) {
      setGroupLimit('')
      onChange(groupLimit)
    }
  }

  function validateAndSetGroupLimit(v) {
    setMessages([])
    if (v < MIN || v > MAX) {
      setGroupLimit('')
      return setMessages([
        {
          text: I18n.t('Number must be between %{min} and %{max}', {min: MIN, max: I18n.n(MAX)}),
          type: 'error',
        },
      ])
    } else {
      return setGroupLimit(v)
    }
  }

  return (
    <NumberInput
      {...props}
      id="group_max_membership"
      renderLabel={I18n.t('Group Membership Limit')}
      messages={messages}
      value={value}
      onChange={handleChange}
      onKeyDown={handleKeyDown}
      onIncrement={handleIncrement}
      onDecrement={handleDecrement}
      placeholder={I18n.t('Number')}
    />
  )
}
