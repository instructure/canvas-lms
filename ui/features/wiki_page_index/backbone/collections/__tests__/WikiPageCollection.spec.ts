/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import WikiPage from '@canvas/wiki/backbone/models/WikiPage'
import WikiPageCollection from '../WikiPageCollection'

const checkFrontPage = function (collection: WikiPageCollection): boolean {
  const total = (collection as any).reduce(
    (i: number, model: any) => (i += model.get('front_page') ? 1 : 0),
    0,
  )
  return total <= 1
}

describe('WikiPageCollection', () => {
  test('only a single front_page per collection', () => {
    const collection = new WikiPageCollection()
    for (let i = 0; i <= 2; i++) {
      ;(collection as any).add(new (WikiPage as any)())
    }
    expect(checkFrontPage(collection)).toBeTruthy()
    ;(collection as any).models[0].set('front_page', true)
    expect(checkFrontPage(collection)).toBeTruthy()
    ;(collection as any).models[1].set('front_page', true)
    expect(checkFrontPage(collection)).toBeTruthy()
    ;(collection as any).models[2].set('front_page', true)
    expect(checkFrontPage(collection)).toBeTruthy()
  })
})

describe('WikiPageCollection:sorting', () => {
  let collection: WikiPageCollection

  beforeEach(() => {
    collection = new WikiPageCollection()
  })

  test('default sort is title', () => {
    expect(collection.currentSortField).toBe('title')
  })

  test('default sort orders', () => {
    expect(collection.sortOrders?.title).toBe('asc')
    expect(collection.sortOrders?.created_at).toBe('desc')
    expect(collection.sortOrders?.updated_at).toBe('desc')
  })

  test('sort order toggles (sort on same field)', () => {
    collection.currentSortField = 'created_at'
    if (collection.sortOrders) collection.sortOrders.created_at = 'desc'
    collection.setSortField('created_at')
    expect(collection.sortOrders?.created_at).toBe('asc')
  })

  test('sort order does not toggle (sort on different field)', () => {
    collection.currentSortField = 'title'
    if (collection.sortOrders) collection.sortOrders.created_at = 'desc'
    collection.setSortField('created_at')
    expect(collection.sortOrders?.created_at).toBe('desc')
  })

  test('sort order can be forced', () => {
    collection.currentSortField = 'title'
    ;(collection as any).setSortField('created_at', 'asc')
    expect(collection.currentSortField).toBe('created_at')
    expect(collection.sortOrders?.created_at).toBe('asc')
    ;(collection as any).setSortField('created_at', 'asc')
    expect(collection.currentSortField).toBe('created_at')
    expect(collection.sortOrders?.created_at).toBe('asc')
  })

  test('setting sort triggers a sortChanged event', () => {
    const sortChangedSpy = vi.fn()
    ;(collection as any).on('sortChanged', sortChangedSpy)
    collection.setSortField('created_at')
    expect(sortChangedSpy).toHaveBeenCalledTimes(1)
    expect(sortChangedSpy).toHaveBeenCalledWith(collection.currentSortField, collection.sortOrders)
  })

  test('setting sort sets fetch parameters', () => {
    ;(collection as any).setSortField('created_at', 'desc')
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore - Backbone collection options property not in type definition
    expect(collection.options).toBeTruthy()
    expect((collection as any).options?.params).toBeTruthy()
    expect((collection as any).options?.params.sort).toBe('created_at')
    expect((collection as any).options?.params.order).toBe('desc')
  })

  test('sortByField delegates to setSortField', () => {
    const setSortFieldStub = vi.spyOn(collection, 'setSortField').mockImplementation(() => {})
    const fetchStub = vi.spyOn(collection, 'fetch' as any).mockImplementation(() => {})
    ;(collection as any).sortByField('created_at', 'desc')
    expect(setSortFieldStub).toHaveBeenCalledTimes(1)
    expect(setSortFieldStub).toHaveBeenCalledWith('created_at', 'desc')
    setSortFieldStub.mockRestore()
    fetchStub.mockRestore()
  })

  test('sortByField triggers a fetch', () => {
    const fetchStub = vi.spyOn(collection, 'fetch' as any).mockImplementation(() => {})
    ;(collection as any).sortByField('created_at', 'desc')
    expect(fetchStub).toHaveBeenCalledTimes(1)
    fetchStub.mockRestore()
  })
})
