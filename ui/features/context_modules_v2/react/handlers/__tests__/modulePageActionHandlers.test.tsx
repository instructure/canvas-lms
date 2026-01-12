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
import {queryClient} from '@canvas/query'
import {render} from '@canvas/react'
import {handleOpeningEditItemModal} from '../modulePageActionHandlers'
import {MODULE_ITEMS} from '../../utils/constants'

vi.mock('@canvas/react', () => ({
  render: vi.fn(() => ({render: vi.fn(), unmount: vi.fn()})),
}))

const courseId = '1'
const moduleId = '2'

const mockItemsDataPage1 = {
  moduleItems: [
    {_id: '3', id: '3', title: 'Item P1', indent: 1, newTab: false, moduleItemUrl: '/p1'},
  ],
}
const mockItemsDataPage2 = {
  moduleItems: [
    {_id: '4', id: '4', title: 'Item P2', indent: 0, newTab: true, moduleItemUrl: '/p2'},
  ],
}
const mockItemsDataPage3 = {
  moduleItems: [
    {_id: '5', id: '5', title: 'Last Item P3', indent: 0, newTab: false, moduleItemUrl: '/p3'},
  ],
}

const mockRender = render as ReturnType<typeof vi.fn>

describe('handleOpeningEditItemModal', () => {
  beforeEach(() => {
    queryClient.clear()
    document.body.innerHTML = `<div id="module-item-mount-point"></div>`

    // Seed cache with three pages
    queryClient.setQueryData([MODULE_ITEMS, moduleId, null], mockItemsDataPage1)
    queryClient.setQueryData([MODULE_ITEMS, moduleId, btoa('10')], mockItemsDataPage2)
    queryClient.setQueryData([MODULE_ITEMS, moduleId, btoa('20')], mockItemsDataPage3)
    mockRender.mockClear()
  })

  afterEach(() => {
    mockRender.mockClear()
  })

  it('opens the Edit modal for an item on page 1', () => {
    handleOpeningEditItemModal(courseId, moduleId, '3')

    expect(mockRender).toHaveBeenCalledTimes(1)

    const renderArg = mockRender.mock.calls[0][0]
    expect(renderArg.props.isOpen).toBe(true)
    expect(renderArg.props.itemId).toBe('3')
    expect(renderArg.props.itemName).toBe('Item P1')
    expect(renderArg.props.itemURL).toBe('/p1')
  })

  it('opens the Edit modal for an item on page 2 (multi-page cache search)', () => {
    handleOpeningEditItemModal(courseId, moduleId, '4')

    expect(mockRender).toHaveBeenCalledTimes(1)

    const renderArg = mockRender.mock.calls[0][0]
    expect(renderArg.props.isOpen).toBe(true)
    expect(renderArg.props.itemId).toBe('4')
    expect(renderArg.props.itemName).toBe('Item P2')
    expect(renderArg.props.itemURL).toBe('/p2')
    expect(renderArg.props.itemNewTab).toBe(true)
  })

  it('opens the Edit modal for an item on page 3 (multi-page cache search)', () => {
    handleOpeningEditItemModal(courseId, moduleId, '5')

    expect(mockRender).toHaveBeenCalledTimes(1)

    const renderArg = mockRender.mock.calls[0][0]
    expect(renderArg.props.isOpen).toBe(true)
    expect(renderArg.props.itemId).toBe('5')
    expect(renderArg.props.itemName).toBe('Last Item P3')
    expect(renderArg.props.itemURL).toBe('/p3')
  })

  it('does nothing when the item is not found in any cached page', () => {
    handleOpeningEditItemModal(courseId, moduleId, 'does-not-exist')

    expect(mockRender).not.toHaveBeenCalled()
  })

  it('does nothing when there is no cache for the module', () => {
    queryClient.clear()

    handleOpeningEditItemModal(courseId, moduleId, '3')

    expect(mockRender).not.toHaveBeenCalled()
  })
})
