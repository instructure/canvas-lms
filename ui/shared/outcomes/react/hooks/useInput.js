/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useState} from 'react'

const useInput = initialValue => {
  const initialState = initialValue || ''
  const [value, setValue] = useState(initialState)
  const changeValue = arg => {
    if (typeof arg === 'object' && arg.target?.value !== undefined) {
      setValue(arg.target.value)
    } else {
      setValue(arg)
    }
  }
  const valueChanged = (value || '').length !== initialState.length || value !== initialState

  return [value, changeValue, valueChanged]
}

export default useInput
