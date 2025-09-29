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

import {useCallback} from 'react'
import {useAppSelector, useAppSetStore} from '../store'

export type EditorMode = 'default' | 'preview'

export const useEditorMode = () => {
  const mode = useAppSelector(state => state.editor.mode)
  const set = useAppSetStore()

  const setMode = useCallback((mode: EditorMode) => {
    // Defer mode changes to next event loop cycle to prevent interference
    // with save operations when blocks are transitioning out of edit mode
    window.setTimeout(() => {
      set(state => {
        state.editor.mode = mode
      })
    }, 0)
  }, [])

  return {
    mode,
    setMode,
  }
}
