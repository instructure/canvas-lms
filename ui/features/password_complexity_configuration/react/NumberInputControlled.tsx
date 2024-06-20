/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

interface NumberInputControlledProps {
  minimum: number
  maximum: number
  defaultValue: number
  disabled: boolean
  'data-testid': string
}

const NumberInputControlled: React.FC<NumberInputControlledProps> = ({
  minimum,
  maximum,
  defaultValue,
  disabled,
  'data-testid': dataTestid,
}) => {
  const [number, setNumber] = useState(defaultValue)
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setNumber(value ? Number(value) : 0) // Replace null with 0
  }

  const handleDecrement = () => {
    if (Number.isNaN(number)) return
    if (number === null) setBoundedNumber(minimum)
    else setBoundedNumber(Math.floor(number) - 1)
  }

  const handleIncrement = () => {
    if (Number.isNaN(number)) return
    if (number === null) setBoundedNumber(minimum + 1)
    else setBoundedNumber(Math.ceil(number) + 1)
  }

  const handleBlur = () => {
    if (Number.isNaN(number)) return
    if (number === null) return
    setBoundedNumber(Math.round(number))
  }

  const setBoundedNumber = (n: number) => {
    if (n < minimum) setNumber(minimum)
    else if (n > maximum) setNumber(maximum)
    else setNumber(n)
  }

  return (
    <NumberInput
      min={minimum}
      max={maximum}
      renderLabel=""
      onIncrement={handleIncrement}
      onDecrement={handleDecrement}
      onChange={handleChange}
      onBlur={handleBlur}
      value={number}
      disabled={disabled}
      data-testid={dataTestid}
    />
  )
}

export default NumberInputControlled
