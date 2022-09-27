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

import {useState, useCallback} from 'react'

// initialNumberValue may be null for a blank input, or it should be a number
export default function useNumberInputDriver({
  initialNumberValue, // may be null to indicate the initial text value should be blank
  minNumberValue = 1, // may be null to indicate no minimum value
  maxNumberValue = null,
}) {
  // numberValue may be null to indicate the input is not a valid number
  const [numberValue, setNumberValue] = useState(initialNumberValue)
  const [inputValue, setInputValue] = useState(
    initialNumberValue ? initialNumberValue.toString() : ''
  )

  const isSameSideAndCloserToZeroThanRange = useCallback(
    newNumberValue => {
      if (minNumberValue !== null && minNumberValue > 0) {
        return newNumberValue > 0 && newNumberValue < minNumberValue
      } else if (maxNumberValue !== null && maxNumberValue < 0) {
        return newNumberValue < 0 && newNumberValue > maxNumberValue
      } else {
        // else 0 is in range. Therefore the new value can't be closer to 0 than the range.
        return false
      }
    },
    [maxNumberValue, minNumberValue]
  )

  const isInRange = useCallback(
    newNumberValue => {
      let isAboveMin = true
      let isBelowMax = true
      if (minNumberValue !== null) isAboveMin = newNumberValue >= minNumberValue
      if (maxNumberValue !== null) isBelowMax = newNumberValue <= maxNumberValue
      return isAboveMin && isBelowMax
    },
    [maxNumberValue, minNumberValue]
  )

  const onChange = useCallback(
    e => {
      const newNumberValue = parseInt(e.target.value, 10)
      if (e.target.value === '') {
        // special case for empty string so they can back out and restart typing
        setNumberValue(null)
        setInputValue('')
      } else if (e.target.value === '-') {
        // special case for single minus. they might be in the middle of typing a number
        if (minNumberValue === null || minNumberValue < 0) {
          setNumberValue(null)
          setInputValue('-')
        } // else, do nothing to disallow minus
      } else if (Number.isNaN(newNumberValue)) {
        // do nothing; don't allow them to type nonsense
      } else if (isSameSideAndCloserToZeroThanRange(newNumberValue)) {
        // allow them to type a number that is too close to zero because they may be in the middle
        // of typing a number that is in range. But set number value to null to signal to the
        // component that the number is not valid right now.
        setNumberValue(null)
        setInputValue(newNumberValue.toString())
      } else if (!isInRange(newNumberValue)) {
        // do nothing; don't allow them to type a number that outside the range
      } else {
        // all is good, set the new values
        setNumberValue(newNumberValue)
        setInputValue(newNumberValue.toString())
      }
    },
    [isInRange, isSameSideAndCloserToZeroThanRange, minNumberValue]
  )

  // We want 1, 0, or the in range value closest to 0
  const incrementOrDecrementStartingPoint = useCallback(() => {
    if (isInRange(1)) return 1
    if (isInRange(0)) return 0
    if (minNumberValue !== null && minNumberValue >= 0) return minNumberValue
    if (maxNumberValue !== null && maxNumberValue <= 0) return maxNumberValue
    // The above should cover all cases, but just in case:
    return 1
  }, [isInRange, maxNumberValue, minNumberValue])

  const onIncrement = useCallback(() => {
    const newNumberValue =
      numberValue !== null ? numberValue + 1 : incrementOrDecrementStartingPoint()
    if (isInRange(newNumberValue)) {
      setNumberValue(newNumberValue)
      setInputValue(newNumberValue.toString())
    }
  }, [incrementOrDecrementStartingPoint, isInRange, numberValue])

  const onDecrement = useCallback(() => {
    const newNumberValue = numberValue ? numberValue - 1 : incrementOrDecrementStartingPoint()
    if (isInRange(newNumberValue)) {
      setNumberValue(newNumberValue)
      setInputValue(newNumberValue.toString())
    }
  }, [incrementOrDecrementStartingPoint, isInRange, numberValue])

  // [{state values}, {props for number input}]
  return [
    {numberValue, setNumberValue, inputValue, setInputValue},
    {value: inputValue, onChange, onIncrement, onDecrement},
  ]
}
