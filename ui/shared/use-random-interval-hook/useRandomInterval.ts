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

import _ from 'lodash'
import React, {useEffect, useRef} from 'react'

const useRandomInterval = (
  memoizedCallback: () => void,
  minDelayMs: number,
  maxDelayMs: number,
  enabled: boolean,
) => {
  const timeoutId = useRef<number | null>(null)

  useEffect(() => {
    const handleTick = () => {
      const nextTickAt = _.random(minDelayMs, maxDelayMs)
      timeoutId.current = window.setTimeout(() => {
        memoizedCallback()
        handleTick()
      }, nextTickAt)
    }

    if (enabled) {
      handleTick()
    }

    return () => {
      if (typeof timeoutId.current === 'number') {
        window.clearTimeout(timeoutId.current)
      }
    }
  }, [memoizedCallback, enabled, minDelayMs, maxDelayMs])
}

export default useRandomInterval
