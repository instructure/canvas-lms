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

import {QueryClient} from '@tanstack/react-query'
import {handleDragEnd as dndHandleDragEnd} from '../../utils/dndUtils'
import type {DropResult} from 'react-beautiful-dnd'
import {MODULES} from '../../utils/constants'

function makeItemResult(
  draggableId: string,
  sourceIndex: number,
  sourceDroppableId: string,
  destIndex: number | null,
  destDroppableId: string | null,
): DropResult {
  return {
    draggableId,
    type: 'MODULE_ITEM',
    source: {index: sourceIndex, droppableId: sourceDroppableId},
    destination:
      destDroppableId == null || destIndex == null
        ? null
        : {index: destIndex, droppableId: destDroppableId},
    reason: 'DROP',
    mode: 'FLUID',
    combine: null,
  } as any
}

function makeModuleResult(
  draggableId: string,
  sourceIndex: number,
  destIndex: number | null,
): DropResult {
  return {
    draggableId,
    type: 'MODULE',
    source: {index: sourceIndex, droppableId: 'modules-list'},
    destination: destIndex == null ? null : {index: destIndex, droppableId: 'modules-list'},
    reason: 'DROP',
    mode: 'FLUID',
    combine: null,
  } as any
}

describe('dndUtils.handleDragEnd (ITEM moves)', () => {
  const courseId = 'course-1'
  const reorderModulesMutation = {mutate: (_: unknown) => void 0}
  const data: any = {pages: [{}]}

  function runAndCaptureItem(result: DropResult) {
    const calls: Array<[number, number, string, string]> = []
    const handleMoveItem = (
      sourceIndex: number,
      destinationIndex: number,
      sourceModuleId: string,
      destinationModuleId: string,
    ) => {
      calls.push([sourceIndex, destinationIndex, sourceModuleId, destinationModuleId])
    }

    dndHandleDragEnd(
      result,
      data,
      courseId,
      new QueryClient(),
      reorderModulesMutation as any,
      handleMoveItem,
    )
    return calls
  }

  it('within same module: move down (index 0 -> 1)', () => {
    const result = makeItemResult('item-a', 0, 'mod-1', 1, 'mod-1')
    expect(runAndCaptureItem(result)).toEqual([[0, 1, 'mod-1', 'mod-1']])
  })

  it('within same module: move up (index 3 -> 1)', () => {
    const result = makeItemResult('item-b', 3, 'mod-1', 1, 'mod-1')
    expect(runAndCaptureItem(result)).toEqual([[3, 1, 'mod-1', 'mod-1']])
  })

  it('between modules: move to TOP (dest index 0)', () => {
    const result = makeItemResult('item-c', 2, 'mod-1', 0, 'mod-2')
    expect(runAndCaptureItem(result)).toEqual([[2, 0, 'mod-1', 'mod-2']])
  })

  it('between modules: move to MIDDLE (dest index 2)', () => {
    const result = makeItemResult('item-d', 1, 'mod-1', 2, 'mod-2')
    expect(runAndCaptureItem(result)).toEqual([[1, 2, 'mod-1', 'mod-2']])
  })

  it('between modules: move to BOTTOM (simulate large dest index)', () => {
    const result = makeItemResult('item-e', 0, 'mod-1', 99, 'mod-2')
    expect(runAndCaptureItem(result)).toEqual([[0, 99, 'mod-1', 'mod-2']])
  })

  it('no destination: does nothing', () => {
    const result = makeItemResult('item-f', 0, 'mod-1', null, null)
    expect(runAndCaptureItem(result)).toEqual([])
  })

  it('sourceIndex === destinationIndex → no-op but still calls handler', () => {
    const result = makeItemResult('item-g', 1, 'mod-1', 1, 'mod-1')
    expect(runAndCaptureItem(result)).toEqual([[1, 1, 'mod-1', 'mod-1']])
  })
})

describe('dndUtils.handleDragEnd (MODULE moves)', () => {
  const courseId = 'course-1'

  function runAndCaptureModule(result: DropResult, modules: Array<{_id: string}> = []) {
    const queryClient = new QueryClient()
    const mutateMock = vi.fn()
    const reorderModulesMutation = {mutate: mutateMock}
    const data: any = {pages: [{modules}]}

    queryClient.setQueryData([MODULES, courseId], data)

    dndHandleDragEnd(result, data, courseId, queryClient, reorderModulesMutation, vi.fn())

    return {mutateMock, queryClient}
  }

  it('moves module down (index 0 → 1)', () => {
    const modules = [{_id: 'm1'}, {_id: 'm2'}]
    const result = makeModuleResult('m1', 0, 1)
    const {mutateMock, queryClient} = runAndCaptureModule(result, modules)

    expect(mutateMock).toHaveBeenCalledWith({courseId, order: ['m2', 'm1']})

    const cached = queryClient.getQueryData<any>([MODULES, courseId])
    expect(cached.pages[0].modules.map((m: any) => m._id)).toEqual(['m2', 'm1'])
  })

  it('moves module up (index 2 → 0)', () => {
    const modules = [{_id: 'm1'}, {_id: 'm2'}, {_id: 'm3'}]
    const result = makeModuleResult('m3', 2, 0)
    const {mutateMock, queryClient} = runAndCaptureModule(result, modules)

    expect(mutateMock).toHaveBeenCalledWith({courseId, order: ['m3', 'm1', 'm2']})

    const cached = queryClient.getQueryData<any>([MODULES, courseId])
    expect(cached.pages[0].modules.map((m: any) => m._id)).toEqual(['m3', 'm1', 'm2'])
  })

  it('same source and destination index: no-op', () => {
    const modules = [{_id: 'm1'}, {_id: 'm2'}]
    const result = makeModuleResult('m1', 0, 0)
    const {mutateMock, queryClient} = runAndCaptureModule(result, modules)

    expect(mutateMock).toHaveBeenCalledWith({courseId, order: ['m1', 'm2']})
    const cached = queryClient.getQueryData<any>([MODULES, courseId])
    expect(cached.pages[0].modules.map((m: any) => m._id)).toEqual(['m1', 'm2'])
  })

  it('invalid source index (out of bounds): does nothing', () => {
    const modules = [{_id: 'm1'}]
    const result = makeModuleResult('mX', 5, 0)
    const {mutateMock} = runAndCaptureModule(result, modules)
    expect(mutateMock).not.toHaveBeenCalled()
  })

  it('no movedModule: does nothing', () => {
    const result = makeModuleResult('m1', 0, 0)
    const {mutateMock} = runAndCaptureModule(result, [])
    expect(mutateMock).not.toHaveBeenCalled()
  })

  it('no destination: does nothing', () => {
    const modules = [{_id: 'm1'}, {_id: 'm2'}]
    const result = makeModuleResult('m1', 0, null)
    const {mutateMock} = runAndCaptureModule(result, modules)
    expect(mutateMock).not.toHaveBeenCalled()
  })

  it('data is undefined: does nothing', () => {
    const result = makeModuleResult('m1', 0, 1)
    const mutateMock = vi.fn()
    const reorderModulesMutation = {mutate: mutateMock}
    dndHandleDragEnd(
      result,
      undefined,
      courseId,
      new QueryClient(),
      reorderModulesMutation,
      vi.fn(),
    )
    expect(mutateMock).not.toHaveBeenCalled()
  })

  it('data.pages is empty: does nothing', () => {
    const result = makeModuleResult('m1', 0, 1)
    const mutateMock = vi.fn()
    const reorderModulesMutation = {mutate: mutateMock}
    const data: any = {pages: []}
    dndHandleDragEnd(result, data, courseId, new QueryClient(), reorderModulesMutation, vi.fn())
    expect(mutateMock).not.toHaveBeenCalled()
  })
})
