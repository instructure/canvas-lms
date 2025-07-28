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

import {useEffect} from 'react'

export const useSetEditMode = (ref: React.RefObject<Element>, setter: (value: boolean) => void) => {
  useEffect(() => {
    const handleDocumentClick = (event: MouseEvent | TouchEvent) => {
      if (!ref.current) return
      if (ref.current.contains(event.target as Node)) {
        setter(true)
      }
    }

    document.addEventListener('click', handleDocumentClick)
    document.addEventListener('touchstart', handleDocumentClick)
    return () => {
      document.removeEventListener('click', handleDocumentClick)
      document.removeEventListener('touchstart', handleDocumentClick)
    }
  }, [ref, setter])
}
