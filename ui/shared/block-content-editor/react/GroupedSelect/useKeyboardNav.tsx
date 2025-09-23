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

import {useRef, useEffect, useCallback} from 'react'
import {GroupedSelectData, GroupedSelectItem} from './GroupedSelect'

export const useKeyboardNav = (
  data: GroupedSelectData[],
  selectedItem: string,
  selectedGroup: string,
  selectedGroupItems: GroupedSelectItem[],
  onGroupChange: (group: GroupedSelectData) => void,
  onItemChange: (item: GroupedSelectItem) => void,
) => {
  const focusedPositionRef = useRef<{column: number; row: number}>({column: 0, row: 0})
  const elementsRef = useRef<Map<string | number, HTMLDivElement | null>>(new Map())

  const updateTabIndexes = useCallback(() => {
    elementsRef.current.forEach(element => {
      if (element) {
        element.setAttribute('tabIndex', '-1')
      }
    })
    elementsRef.current.get(selectedGroup)?.setAttribute('tabIndex', '0')
    elementsRef.current.get(selectedItem)?.setAttribute('tabIndex', '0')
  }, [selectedGroup, selectedItem])

  const updateFocus = (column: number, row: number) => {
    focusedPositionRef.current = {column, row}

    const focusedElement = elementsRef.current.get(
      column === 0 ? data[row].groupName : selectedGroupItems[row].id,
    )

    if (focusedElement) {
      focusedElement.setAttribute('tabIndex', '0')
      focusedElement.focus()
    }
  }

  useEffect(() => {
    for (const [key, value] of elementsRef.current.entries()) {
      if (value === null) {
        elementsRef.current.delete(key)
      }
    }

    updateTabIndexes()
  }, [elementsRef, updateTabIndexes])

  const handleKeyDown = (event: React.KeyboardEvent) => {
    const {column, row} = focusedPositionRef.current

    // Sometimes first column TAB navigation jump to X button, force left navigation to selected item
    if (event.key === 'Tab' && !event.shiftKey && column === 0) {
      elementsRef.current.get(selectedItem)?.focus()
      event.preventDefault()
    } else if (event.key === 'Enter' || event.key === ' ') {
      if (column === 0) {
        onGroupChange(data[row])
        updateFocus(0, row)
      } else {
        onItemChange(selectedGroupItems[row])
        updateFocus(1, row)
      }
    } else if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
      if (event.key === 'ArrowRight' && column === 0) {
        const newRow = selectedGroupItems.findIndex(item => item.id === selectedItem)
        updateFocus(1, newRow)
      } else if (event.key === 'ArrowLeft' && column === 1) {
        const newRow = data.findIndex(group => group.groupName === selectedGroup)
        updateFocus(0, newRow)
      }
    } else if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault()
      const columnLength = column === 0 ? data.length : selectedGroupItems.length
      const newRow =
        event.key === 'ArrowDown' ? Math.min(row + 1, columnLength - 1) : Math.max(row - 1, 0)
      updateFocus(column, newRow)
    }
  }

  const overrideFocus = (column: number, row: number) => {
    focusedPositionRef.current = {column, row}
  }

  const handleBlur = (event: React.FocusEvent) => {
    if (
      event.target !== elementsRef.current.get(selectedGroup) &&
      event.target !== elementsRef.current.get(selectedItem)
    ) {
      event.target.setAttribute('tabIndex', '-1')
    }
  }

  return {
    handleKeyDown,
    elementsRef,
    overrideFocus,
    handleBlur,
  }
}
