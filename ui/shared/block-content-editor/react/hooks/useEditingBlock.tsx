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

import {useGetAppStore, useAppSetStore} from '../store'

export const useEditingBlock = () => {
  const getStore = useGetAppStore()
  const set = useAppSetStore()

  function saveOtherBlock(newId: string | null) {
    const {
      editingBlock: {id, saveCallbacks},
    } = getStore()
    if (id && id !== newId) {
      saveCallbacks.forEach(callback => callback())
    }
  }

  function setId(newId: string, viaEditButton: boolean): void
  function setId(newId: null): void
  function setId(newId: string | null, viaEditButton?: boolean): void {
    saveOtherBlock(newId)
    set(state => {
      state.editingBlock.id = newId
      state.editingBlock.viaEditButton = viaEditButton ?? false
    })
  }

  return {
    setId,
    addSaveCallback: (callback: () => void) => {
      set(state => {
        state.editingBlock.saveCallbacks.add(callback)
      })
    },
    deleteSaveCallback: (callback: () => void) => {
      set(state => {
        state.editingBlock.saveCallbacks.delete(callback)
      })
    },
  }
}
