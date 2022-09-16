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

import React, {useState, useCallback, useEffect} from 'react'
import {debounce} from '@instructure/debounce'

export default function useDebouncedValue(currentValue, onChange, processValueCallback) {
  const [immediateValue, setImmediateValue] = useState(currentValue)

  // Only invokes onChange on the trailing edge of the timeout
  const debouncedOnChangeCallback = useCallback(
    debounce(val => onChange(val), 500, {trailing: true}),
    []
  )

  useEffect(() => {
    let newValue = currentValue
    if (processValueCallback) {
      newValue = processValueCallback(immediateValue, newValue)
    }

    // If so we need to make sure to re-set the immediate value
    // once a truthy value is given
    if (newValue !== immediateValue) {
      setImmediateValue(newValue)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentValue])

  useEffect(() => {
    // Debounce the call to set reducer's state
    debouncedOnChangeCallback(immediateValue)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [immediateValue])

  const handleValueChange = event => {
    let {value} = event.target

    if (processValueCallback) {
      value = processValueCallback(value)
    }

    // Immediately set local state for low-latency feedback
    setImmediateValue(value)
  }

  return [immediateValue, handleValueChange]
}
