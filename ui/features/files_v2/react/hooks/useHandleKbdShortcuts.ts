/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useEffect, useCallback} from 'react'

const shouldBeIgnored = (target: EventTarget | null): boolean => {
  if (!target || !(target instanceof HTMLElement)) return false

  const tagName = target.tagName.toLowerCase()

  if (tagName === 'textarea') return true
  if (tagName === 'input' && target.getAttribute('type')?.toLowerCase() === 'text') return true
  if (target.closest('[role="dialog"]')) return true

  return false
}

export const useHandleKbdShortcuts = (
  selectAllHandler: () => void,
  deselectAllHandler: () => void,
) => {
  const handleCtrlPlusA = useCallback(
    (event: KeyboardEvent) => {
      if (shouldBeIgnored(event.target)) {
        return
      }

      if (event.key.toLowerCase() === 'a' && (event.ctrlKey || event.metaKey)) {
        event.preventDefault()
        if (event.shiftKey) {
          deselectAllHandler()
        } else {
          selectAllHandler()
        }
      }
    },
    [selectAllHandler, deselectAllHandler],
  )

  useEffect(() => {
    window.addEventListener('keydown', handleCtrlPlusA)

    return () => {
      window.removeEventListener('keydown', handleCtrlPlusA)
    }
  }, [handleCtrlPlusA])
}
