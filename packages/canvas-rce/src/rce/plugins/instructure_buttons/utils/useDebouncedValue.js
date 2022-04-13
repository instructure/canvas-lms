/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {debounce} from '@instructure/debounce'

export default function useDebouncedValue(currentValue, onChange) {
  const [immediateValue, setImmediateValue] = useState(currentValue)

  // The hook may have initially been called with currentValue
  // being set to an empty value.
  //
  // If so we need to make sure to re-set the immediate value
  // once a truthy value is given
  if (!immediateValue && !!currentValue) {
    setImmediateValue(currentValue)
  }

  const handleValueChange = event => {
    const {value} = event.target

    // Immediately set local state for low-latency feedback
    setImmediateValue(value)

    if (!value) {
      // The user may have done ctrl+a, backspace.
      // Clear the value immediately to allow this
      // action to clear the input
      onChange(value)
    } else {
      // Debounce the call to set state that may cause many
      // re-renders down the component tree
      debounce(val => {
        onChange(val)
      }, 500)(value)
    }
  }

  return [immediateValue, handleValueChange, setImmediateValue]
}
