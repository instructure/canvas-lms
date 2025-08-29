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

import {useRef, useState} from 'react'

export const useEditingBlock = () => {
  const [id, setId] = useState<string | null>(null)
  const callbackRef = useRef<Set<() => void>>(new Set())
  const idRef = useRef<string | null>(id)
  idRef.current = id

  return {
    id,
    setId: (newId: string | null) => {
      if (id !== null && newId !== id) {
        callbackRef.current.forEach(cb => cb())
      }
      setId(newId)
    },
    idRef,
    addSaveCallback: (callback: () => void) => {
      callbackRef.current.add(callback)
    },
    deleteSaveCallback: (callback: () => void) => {
      callbackRef.current.delete(callback)
    },
  }
}
