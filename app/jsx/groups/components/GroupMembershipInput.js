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
import I18n from 'i18n!groups'
import {func} from 'prop-types'
import {NumberInput} from '@instructure/ui-number-input'

const MIN = 1
const MAX = 100000

GroupMembershipInput.propTypes = {
  onChange: func.isRequired
}

export default function GroupMembershipInput({onChange, ...props}) {
  const [messages, setMessages] = useState([])
  const [number, setNumber] = useState('')

  useEffect(() => {
    onChange(number)
  }, [number, onChange])

  function handleIncrement() {
    if (Number.isNaN(Number(number))) return
    if (number === '') return validateAndSetNumber(MIN)
    if (Number.isInteger(number)) return validateAndSetNumber(number + 1)
    return validateAndSetNumber(Math.ceil(number))
  }

  function handleDecrement() {
    if (Number.isNaN(Number(number))) return
    if (number === '') return validateAndSetNumber(MIN)
    if (Number.isInteger(number)) return validateAndSetNumber(number - 1)
    return validateAndSetNumber(Math.floor(number))
  }

  function handleChange(_, value) {
    if (Number.isNaN(Number(value))) {
      setNumber('')
      return setMessages([{text: `'${value}' is not a valid number.`, type: 'error'}])
    }
    if (value === '') return value
    return validateAndSetNumber(Math.round(value))
  }

  function handleKeyDown(e) {
    if (e.key === 'Backspace' && number < 10) {
      setNumber('')
    }
  }

  function validateAndSetNumber(n) {
    setMessages([])
    if (n < MIN || n > MAX) {
      setNumber('')
      return setMessages([
        {text: `Number must be between ${MIN} and ${I18n.n(MAX)}`, type: 'error'}
      ])
    } else {
      return setNumber(n)
    }
  }

  return (
    <NumberInput
      {...props}
      id="group_max_membership"
      renderLabel={I18n.t('Group Membership Limit')}
      messages={messages}
      onChange={handleChange}
      onKeyDown={handleKeyDown}
      onIncrement={handleIncrement}
      onDecrement={handleDecrement}
      placeholder="Number"
    />
  )
}
