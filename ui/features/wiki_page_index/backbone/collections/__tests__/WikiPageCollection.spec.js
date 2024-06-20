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

const checkFrontPage = function (collection) {
  const total = collection.reduce((i, model) => (i += model.get('front_page') ? 1 : 0), 0)
  return total <= 1
}

describe('WikiPageCollection', () => {
  test('only a single front_page per collection', () => {
    const collection = new WikiPageCollection()
    for (let i = 0; i <= 2; i++) {
      collection.add(new WikiPage())
    }
    expect(checkFrontPage(collection)).toBeTruthy()
    collection.models[0].set('front_page', true)
    expect(checkFrontPage(collection)).toBeTruthy()
    collection.models[1].set('front_page', true)
    expect(checkFrontPage(collection)).toBeTruthy()
    collection.models[2].set('front_page', true)
    expect(checkFrontPage(collection)).toBeTruthy()
  })
})

describe('WikiPageCollection:sorting', () => {
  let collection

  beforeEach(() => {
    collection = new WikiPageCollection()
  })

  test('default sort is title', () => {
    expect(collection.currentSortField).toBe('title')
  })

  test('default sort orders', () => {
    expect(collection.sortOrders.title).toBe('asc')
    expect(collection.sortOrders.created_at).toBe('desc')
    expect(collection.sortOrders.updated_at).toBe('desc')
  })

  test('sort order toggles (sort on same field)', () => {
    collection.currentSortField = 'created_at'
    collection.sortOrders.created_at = 'desc'
    collection.setSortField('created_at')
    expect(collection.sortOrders.created_at).toBe('asc')
  })

  test('sort order does not toggle (sort on different field)', () => {
    collection.currentSortField = 'title'
    collection.sortOrders.created_at = 'desc'
    collection.setSortField('created_at')
    expect(collection.sortOrders.created_at).toBe('desc')
  })

  test('sort order can be forced', () => {
    collection.currentSortField = 'title'
    collection.setSortField('created_at', 'asc')
    expect(collection.currentSortField).toBe('created_at')
    expect(collection.sortOrders.created_at).toBe('asc')
    collection.setSortField('created_at', 'asc')
    expect(collection.currentSortField).toBe('created_at')
    expect(collection.sortOrders.created_at).toBe('asc')
  })

  test('setting sort triggers a sortChanged event', () => {
    const sortChangedSpy = jest.fn()
    collection.on('sortChanged', sortChangedSpy)
    collection.setSortField('created_at')
    expect(sortChangedSpy).toHaveBeenCalledTimes(1)
    expect(sortChangedSpy).toHaveBeenCalledWith(collection.currentSortField, collection.sortOrders)
  })

  test('setting sort sets fetch parameters', () => {
    collection.setSortField('created_at', 'desc')
    expect(collection.options).toBeTruthy()
    expect(collection.options.params).toBeTruthy()
    expect(collection.options.params.sort).toBe('created_at')
    expect(collection.options.params.order).toBe('desc')
  })

  test('sortByField delegates to setSortField', () => {
    const setSortFieldStub = jest.spyOn(collection, 'setSortField').mockImplementation()
    const fetchStub = jest.spyOn(collection, 'fetch').mockImplementation()
    collection.sortByField('created_at', 'desc')
    expect(setSortFieldStub).toHaveBeenCalledTimes(1)
    expect(setSortFieldStub).toHaveBeenCalledWith('created_at', 'desc')
    setSortFieldStub.mockRestore()
    fetchStub.mockRestore()
  })

  test('sortByField triggers a fetch', () => {
    const fetchStub = jest.spyOn(collection, 'fetch').mockImplementation()
    collection.sortByField('created_at', 'desc')
    expect(fetchStub).toHaveBeenCalledTimes(1)
    fetchStub.mockRestore()
  })
})
