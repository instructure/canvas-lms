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

import {useState} from 'react'

export default function useAllowedAttemptsState(props) {
  const [limited, setLimited] = useState(props.limited)
  const [attempts, setAttempts] = useState(props.attempts)

  function onLimitedChange(newValue) {
    if (newValue && !limited && (attempts == null || attempts < 0)) {
      setAttempts(1)
    }
    setLimited(newValue)
  }

  function onAttemptsChange(newValue) {
    if (newValue == null || newValue > 0) setAttempts(newValue)
  }

  return {
    limited,
    attempts,
    onLimitedChange,
    onAttemptsChange,
  }
}
