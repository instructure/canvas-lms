/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import Backbone from '@canvas/backbone'
import PaginatedCollection from '../PaginatedCollection'
import getFakePage from '@canvas/test-utils/getFakePage'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('PaginatedCollection', () => {
  let collection
  let server

  const sendPage = (page, url) => {
    const pathname = new URL(url, 'http://localhost').pathname
    server.use(
      http.get(
        pathname,
        ({request}) => {
          const requestUrl = new URL(request.url)
          if (requestUrl.href === new URL(url, 'http://localhost').href) {
            return new HttpResponse(JSON.stringify(page.data), {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
                Link: page.header,
              },
            })
          }
          return undefined
        },
        {once: true},
      ),
    )
  }

  beforeAll(() => {
    server = setupServer()
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    collection = new PaginatedCollection(null, {
      params: {
        multi: ['foos', 'bars'],
        single: 1,
      },
    })
    collection.url = '/test'
    collection.urlWithParams = function () {
      return this.url + '?' + $.param(this.options.params)
    }
    collection.model = Backbone.Model.extend()
  })

  test('fetch maintains parent API', () => {
    const page = getFakePage()
    sendPage(page, collection.urlWithParams())
    const dfd = collection.fetch({
      success: (self, response) => {
        expect(self).toBe(collection)
        expect(response).toEqual(page.data)
      },
    })
    expect(dfd.promise).toBeTruthy()
    dfd.done((data, status, xhr) => {
      expect(data).toEqual(page.data)
      expect(status).toBe('success')
      expect(typeof xhr.abort).toBe('function')
    })
  })

  test('fetch maintains error handler API', () => {
    const url = collection.urlWithParams()
    const pathname = new URL(url, 'http://localhost').pathname
    server.use(
      http.get(
        pathname,
        ({request}) => {
          const requestUrl = new URL(request.url)
          if (requestUrl.href === new URL(url, 'http://localhost').href) {
            return new HttpResponse('wah wah', {
              status: 400,
              headers: {
                'Content-Type': 'application/json',
              },
            })
          }
          return undefined
        },
        {once: true},
      ),
    )

    collection.fetch({
      error: (self, xhr) => {
        expect(self).toBe(collection)
        expect(xhr.responseText).toBe('wah wah')
      },
    })
  })

  test('fetch fires fetch event', () => {
    const page = getFakePage()
    sendPage(page, collection.urlWithParams())

    collection.on('fetch', (self, modelData) => {
      expect(true).toBe(true) // triggers fetch
      expect(modelData).toEqual(page.data)
      expect(self).toBe(collection)
    })
    collection.fetch()
  })

  test('fetches current page', () => {
    const page1 = getFakePage(1)
    sendPage(page1, collection.urlWithParams())

    collection.fetch({
      success: () => {
        expect(collection.models).toHaveLength(2)
        expect(collection.models[0].get('id')).toBe(1)
        expect(collection.models[1].get('id')).toBe(2)
        expect(collection.urls.current).toBe(page1.urls.current)
      },
    })

    collection.on('fetch:current', (_self, modelData) => {
      expect(true).toBe(true) // triggers fetch:current
      expect(modelData).toEqual(page1.data)
    })

    sendPage(page1, collection.urls.current)
    collection.fetch({
      page: 'current',
      success: () => {
        expect(collection.models).toHaveLength(2)
        expect(collection.models[0].get('id')).toBe(1)
        expect(collection.models[1].get('id')).toBe(2)
        expect(collection.urls.current).toBe(page1.urls.current)
      },
    })
  })

  test('fetches next page', () => {
    const page1 = getFakePage(1)
    const page2 = getFakePage(2)
    sendPage(page1, collection.urlWithParams())

    collection.fetch({
      success: () => {
        expect(collection.models[0].get('id')).toBe(1)
        expect(collection.models[1].get('id')).toBe(2)
        expect(collection.urls.next).toBe(page1.urls.next)
      },
    })

    collection.on('fetch:next', (_self, modelData) => {
      expect(true).toBe(true) // triggers fetch:next
      expect(modelData).toEqual(page2.data)
    })

    sendPage(page2, collection.urls.next)
    collection.fetch({
      page: 'next',
      success: () => {
        expect(collection.models[2].get('id')).toBe(3)
        expect(collection.models[3].get('id')).toBe(4)
        expect(collection.urls.next).toBe(page2.urls.next)
      },
    })
  })

  test('fetches previous page', () => {
    const page1 = getFakePage(1)
    const page2 = getFakePage(2)
    sendPage(page2, collection.urlWithParams())

    collection.fetch({
      success: () => {
        expect(collection.models[0].get('id')).toBe(3)
        expect(collection.models[1].get('id')).toBe(4)
        expect(collection.urls.prev).toBe(page2.urls.prev)
      },
    })

    collection.on('fetch:prev', (_self, modelData) => {
      expect(true).toBe(true) // triggers fetch:prev
      expect(modelData).toEqual(page1.data)
    })

    sendPage(page1, collection.urls.prev)
    collection.fetch({
      page: 'prev',
      success: () => {
        expect(collection.models[2].get('id')).toBe(1)
        expect(collection.models[3].get('id')).toBe(2)
        expect(collection.urls.prev).toBeUndefined()
      },
    })
  })

  test('fetches current, prev, next, top and bottom pages', () => {
    const page1 = getFakePage(1)
    const page2 = getFakePage(2)
    const page3 = getFakePage(3)
    const page4 = getFakePage(4)
    sendPage(page3, collection.urlWithParams())

    collection.fetch({
      success: () => {
        expect(collection.models[0].get('id')).toBe(5)
        const expectedUrls = page3.urls
        expectedUrls.top = page3.urls.prev
        expectedUrls.bottom = page3.urls.next
        expect(collection.urls).toEqual(expectedUrls)
      },
    })

    sendPage(page3, collection.urlWithParams())
    collection.fetch({
      page: 'current',
      success: () => {
        const expectedUrls = page3.urls
        expectedUrls.top = page3.urls.prev
        expectedUrls.bottom = page3.urls.next
        expect(collection.urls).toEqual(expectedUrls)
      },
    })

    sendPage(page2, collection.urls.prev)
    collection.fetch({
      page: 'prev',
      success: () => {
        expect(collection.models).toHaveLength(4)
        const expectedUrls = page2.urls
        expectedUrls.top = page2.urls.prev
        expectedUrls.bottom = page3.urls.next // shouldn't change
        expect(collection.urls).toEqual(expectedUrls)
      },
    })

    sendPage(page1, collection.urls.top)
    collection.fetch({
      page: 'top',
      success: () => {
        expect(collection.models).toHaveLength(6)
        const expectedUrls = page1.urls
        expectedUrls.bottom = page3.urls.next // shouldn't change
        expect(collection.urls).toEqual(expectedUrls)
      },
    })

    sendPage(page4, collection.urls.bottom)
    collection.fetch({
      page: 'bottom',
      success: () => {
        expect(collection.models).toHaveLength(8)
        expect(collection.urls.bottom).toBe(page4.urls.next)
      },
    })
  })
})
