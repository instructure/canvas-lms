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

// This function may be used in place of 'useDebouncedValue.js' when
// awaiting the debounced onChange to fire is not possible (or very
// inconvenient)
export default function useDebouncedValue(initialValue, onChange) {
  const [immediateValue, setImmediateValue] = useState(initialValue)

  const handleValueChange = event => {
    const {value} = event.target
    setImmediateValue(value)
    // Unlike the un-mocked hook, we call onChange without debouncing
    onChange(value)
  }

  return [immediateValue, handleValueChange, setImmediateValue]
}
