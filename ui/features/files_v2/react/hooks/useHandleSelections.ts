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

import {useCallback, useMemo, useState, useEffect} from 'react'
import {getSelectionScreenReaderText} from '../components/FileFolderTable/FileFolderTableUtils'

export const useHandleSelections = (
  selectableIds: string[],
  setSelectionAnnouncement: (announcement: string) => void,
) => {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())

  useEffect(() => {
    setSelectedIds(new Set())
  }, [selectableIds])

  const idsIndex = useMemo(
    () =>
      selectableIds.reduce(
        (acc, id, index) => {
          acc[id] = index
          return acc
        },
        {} as Record<string, number>,
      ),
    [selectableIds],
  )

  const updateSelectionAnnouncement = useCallback(
    (newlySelectedIds: Set<string>) => {
      setSelectionAnnouncement(
        getSelectionScreenReaderText(newlySelectedIds.size, selectableIds.length),
      )
    },
    [setSelectionAnnouncement, selectableIds.length],
  )

  const selectAll = useCallback(() => {
    const newlySelectedIds = new Set(selectableIds)
    setSelectedIds(newlySelectedIds)
    updateSelectionAnnouncement(newlySelectedIds)
  }, [selectableIds, updateSelectionAnnouncement])

  const deselectAll = useCallback(() => {
    const newlySelectedIds = new Set<string>()
    setSelectedIds(newlySelectedIds)
    updateSelectionAnnouncement(newlySelectedIds)
  }, [updateSelectionAnnouncement])

  const toggleSelectAll = useCallback(() => {
    if (selectedIds.size === selectableIds.length) {
      deselectAll()
    } else {
      selectAll()
    }
  }, [selectAll, deselectAll, selectedIds, selectableIds])

  const toggleSelection = useCallback(
    (id: string) => {
      setSelectedIds(prevSelected => {
        const newSelected = new Set([...prevSelected])
        if (newSelected.has(id)) {
          newSelected.delete(id)
        } else {
          newSelected.add(id)
        }
        updateSelectionAnnouncement(newSelected)
        return newSelected
      })
    },
    [updateSelectionAnnouncement],
  )

  const selectRange = useCallback(
    (id: string) => {
      if (selectedIds.size === 0) {
        return
      }

      const newPos = idsIndex[id]
      const lastPosition = idsIndex[[...selectedIds].at(-1)!]

      const range = selectableIds.slice(
        Math.min(newPos, lastPosition),
        Math.max(newPos, lastPosition) + 1,
      )

      if (newPos > lastPosition) {
        range.reverse()
      }

      const newlySelectedIds = new Set(range)
      setSelectedIds(newlySelectedIds)
      updateSelectionAnnouncement(newlySelectedIds)
    },
    [idsIndex, selectedIds, selectableIds, updateSelectionAnnouncement],
  )

  return {
    selectedIds,
    selectionHandlers: {toggleSelection, toggleSelectAll, selectAll, deselectAll, selectRange},
  }
}
