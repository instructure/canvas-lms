/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useRef, useCallback, useEffect} from 'react'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

export const useScreenReaderAlert = (timeout = 1500) => {
  const ref = useRef<number | null>(null)

  useEffect(() => {
    return () => {
      if (ref.current) window.clearTimeout(ref.current)
    }
  }, [])

  return useCallback(
    (message: string) => {
      if (ref.current) {
        window.clearTimeout(ref.current)
      }
      ref.current = window.setTimeout(() => {
        showFlashAlert({
          message,
          type: 'info',
          srOnly: true,
          politeness: 'assertive',
        })
        ref.current = null
      }, timeout)
    },
    [ref, timeout],
  )
}
