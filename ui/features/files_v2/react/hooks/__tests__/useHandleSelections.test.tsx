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

import {act} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {getSelectionScreenReaderText} from '../../components/FileFolderTable/FileFolderTableUtils'
import {useHandleSelections} from '../useHandleSelections'

describe('useHandleSelections', () => {
  const selectableIds = ['file1', 'file2', 'file3']
  let setSelectionAnnouncement: any

  beforeEach(() => {
    setSelectionAnnouncement = vi.fn()
  })

  it('should initialize with no selected IDs', () => {
    const {result} = renderHook(() => useHandleSelections(selectableIds, setSelectionAnnouncement))
    expect(result.current.selectedIds).toEqual(new Set())
  })

  it('should select all items when selectAll is called', () => {
    const {result} = renderHook(() => useHandleSelections(selectableIds, setSelectionAnnouncement))
    act(() => {
      result.current.selectionHandlers.selectAll()
    })
    expect(result.current.selectedIds).toEqual(new Set(selectableIds))
  })

  it('should deselect all items when deselectAll is called', () => {
    const {result} = renderHook(() => useHandleSelections(selectableIds, setSelectionAnnouncement))
    act(() => {
      result.current.selectionHandlers.selectAll()
      result.current.selectionHandlers.deselectAll()
    })
    expect(result.current.selectedIds).toEqual(new Set())
  })

  it('should toggle selection of an item', () => {
    const {result} = renderHook(() => useHandleSelections(selectableIds, setSelectionAnnouncement))
    act(() => {
      result.current.selectionHandlers.toggleSelection('file1')
    })
    expect(result.current.selectedIds).toEqual(new Set(['file1']))

    act(() => {
      result.current.selectionHandlers.toggleSelection('file1')
    })
    expect(result.current.selectedIds).toEqual(new Set())
  })

  it('should toggle select all items when toggleSelectAll is called', () => {
    const {result} = renderHook(() => useHandleSelections(selectableIds, setSelectionAnnouncement))
    act(() => {
      result.current.selectionHandlers.toggleSelectAll()
    })
    expect(result.current.selectedIds).toEqual(new Set(selectableIds))

    act(() => {
      result.current.selectionHandlers.toggleSelectAll()
    })
    expect(result.current.selectedIds).toEqual(new Set())
  })

  it('should not select items when anchor not set and selectRange is called', () => {
    const {result} = renderHook(() => useHandleSelections(selectableIds, setSelectionAnnouncement))
    act(() => {
      result.current.selectionHandlers.selectRange('file2')
    })
    expect(result.current.selectedIds).toEqual(new Set())
  })

  it('should call updateSelectionAnnouncement with correct text when selecting items', () => {
    const {result} = renderHook(() => useHandleSelections(selectableIds, setSelectionAnnouncement))
    act(() => {
      result.current.selectionHandlers.toggleSelection('file1')
    })
    expect(setSelectionAnnouncement).toHaveBeenCalledWith(
      getSelectionScreenReaderText(1, selectableIds.length),
    )

    act(() => {
      result.current.selectionHandlers.selectAll()
    })
    expect(setSelectionAnnouncement).toHaveBeenCalledWith(
      getSelectionScreenReaderText(selectableIds.length, selectableIds.length),
    )

    act(() => {
      result.current.selectionHandlers.deselectAll()
    })
    expect(setSelectionAnnouncement).toHaveBeenCalledWith(
      getSelectionScreenReaderText(0, selectableIds.length),
    )
  })
})
