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

import {useEffect, useRef, useState} from 'react'
import {debounce} from '@instructure/debounce'

const CHANGE_EVENT_DELAY = 1000

const digestValue = ({parseValueCallback, processValueCallback, formatValueCallback, value}) => {
  const parsedNewValue = parseValueCallback(value)
  if (parsedNewValue === null) {
    return [null, null]
  }
  const processedNewValue = processValueCallback(parsedNewValue)
  const formattedNewTempValue = formatValueCallback(processedNewValue)
  return [formattedNewTempValue, processedNewValue]
}

export function useDebouncedNumericValue({
  value,
  parseValueCallback,
  processValueCallback,
  formatValueCallback,
  onChange,
}) {
  const [inputValue, setInputValue] = useState(formatValueCallback(value))
  const [hasError, setHasError] = useState(false)

  const updateStateAfterDigest = newValue => {
    const [formattedValue, processedValue] = digestValue({
      parseValueCallback,
      processValueCallback,
      formatValueCallback,
      value: newValue,
    })
    if (formattedValue === null || processedValue === null) {
      setHasError(true)
      return
    }
    setHasError(false)
    if (newValue !== formattedValue) {
      setInputValue(formattedValue)
    }
    if (processedValue !== value) {
      onChange(processedValue)
    }
  }

  const debouncedUpdateStateAfterDigest = useRef(
    debounce(updateStateAfterDigest, CHANGE_EVENT_DELAY)
  )

  useEffect(() => {
    const newTempValue = formatValueCallback(value)
    if (newTempValue !== inputValue) {
      setInputValue(newTempValue)
      setHasError(false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value])

  const digestCurrentValue = () => updateStateAfterDigest(inputValue)
  const digestNewValue = rawValue => {
    setInputValue(rawValue)
    debouncedUpdateStateAfterDigest.current(rawValue)
  }

  return [inputValue, digestCurrentValue, digestNewValue, hasError]
}
