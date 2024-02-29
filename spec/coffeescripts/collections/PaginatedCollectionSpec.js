/* eslint-disable qunit/no-test-expect-argument */
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
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import getFakePage from 'helpers/getFakePage'

QUnit.module('PaginatedCollection', {
  setup() {
    this.server = sinon.fakeServer.create()
    this.collection = new PaginatedCollection(null, {
      params: {
        multi: ['foos', 'bars'],
        single: 1,
      },
    })
    this.collection.url = '/test'
    this.collection.urlWithParams = function () {
      return this.url + '?' + $.param(this.options.params)
    }
    this.collection.model = Backbone.Model.extend()
    this.server.sendPage = function (page, url) {
      return this.respond('GET', url, [
        200,
        {
          'Content-Type': 'application/json',
          Link: page.header,
        },
        JSON.stringify(page.data),
      ])
    }
  },

  teardown() {
    this.server.restore()
  },
})

test('fetch maintains parent API', 6, function () {
  const page = getFakePage()
  const dfd = this.collection.fetch({
    success: (self, response) => {
      equal(self, this.collection, 'passes itself into success handler')
      deepEqual(response, page.data, 'passes response into success handler')
    },
  })
  ok(dfd.promise, 'returns a deferred object (quacks like a deferred)')
  dfd.done((data, status, xhr) => {
    deepEqual(data, page.data, 'deferred is resolved with raw data')
    equal(status, 'success', 'text status is success')
    ok(xhr.abort('function', 'jQuery xhr is passed in (quacks like a xhr)'))
  })
  return this.server.sendPage(page, this.collection.urlWithParams())
})

test('fetch maintains error handler API', 2, function () {
  this.collection.fetch({
    error: (self, xhr) => {
      equal(self, this.collection, 'passes itself into fail handler')
      deepEqual(xhr.responseText, 'wah wah', 'passes response into fail handler')
    },
  })
  return this.server.respond('GET', this.collection.urlWithParams(), [
    400,
    {'Content-Type': 'application/json'},
    'wah wah',
  ])
})

test('fetch fires fetch event', 3, function () {
  const page = getFakePage()
  this.collection.on('fetch', (self, modelData) => {
    ok(true, 'triggers fetch')
    deepEqual(modelData, page.data, 'passes data in')
    equal(self, this.collection, 'passes self in')
  })
  this.collection.fetch()
  return this.server.sendPage(page, this.collection.urlWithParams())
})

test('fetches current page', 10, function () {
  const page1 = getFakePage(1)

  this.collection.fetch({
    success: () => {
      equal(this.collection.models.length, 2, 'added models to collection')
      equal(this.collection.models[0].get('id'), 1, 'added model to collection')
      equal(this.collection.models[1].get('id'), 2, 'added model to collection')
      equal(this.collection.urls.current, page1.urls.current, 'current url matches')
    },
  })
  this.server.sendPage(page1, this.collection.urlWithParams())
  this.collection.on('fetch:current', (self, modelData) => {
    ok(true, 'triggers fetch:current event')
    deepEqual(modelData, page1.data, 'passes data in')
  })
  this.collection.fetch({
    page: 'current',
    success: () => {
      equal(this.collection.models.length, 2, 'added models to collection')
      equal(this.collection.models[0].get('id'), 1, 'passed in model to current page handler')
      equal(this.collection.models[1].get('id'), 2, 'passed in model to current page handler')
      equal(this.collection.urls.current, page1.urls.current, 'current url matches')
    },
  })
  return this.server.sendPage(page1, this.collection.urls.current)
})

test('fetches next page', 8, function () {
  const page1 = getFakePage(1)
  const page2 = getFakePage(2)

  this.collection.fetch({
    success: () => {
      equal(this.collection.models[0].get('id'), 1, 'added model to collection')
      equal(this.collection.models[1].get('id'), 2, 'added model to collection')
      equal(this.collection.urls.next, page1.urls.next, 'next url matches')
    },
  })
  this.server.sendPage(page1, this.collection.urlWithParams())
  this.collection.on('fetch:next', (self, modelData) => {
    ok(true, 'triggers fetch:next event')
    deepEqual(modelData, page2.data, 'passes data in')
  })
  this.collection.fetch({
    page: 'next',
    success: () => {
      equal(this.collection.models[2].get('id'), 3, 'passed in model to next page handler')
      equal(this.collection.models[3].get('id'), 4, 'passed in model to next page handler')
      equal(this.collection.urls.next, page2.urls.next, 'next url matches')
    },
  })
  return this.server.sendPage(page2, this.collection.urls.next)
})

test('fetches previous page', 8, function () {
  const page1 = getFakePage(1)
  const page2 = getFakePage(2)

  this.collection.fetch({
    success: () => {
      equal(this.collection.models[0].get('id'), 3, 'added model to collection')
      equal(this.collection.models[1].get('id'), 4, 'added model to collection')
      equal(this.collection.urls.prev, page2.urls.prev, 'prev url matches')
    },
  })

  this.server.sendPage(page2, this.collection.urlWithParams())
  this.collection.on('fetch:prev', (self, modelData) => {
    ok(true, 'triggers fetch:prev event')
    deepEqual(modelData, page1.data, 'passes data in')
  })

  this.collection.fetch({
    page: 'prev',
    success: () => {
      equal(this.collection.models[2].get('id'), 1, 'passed in model to prev page handler')
      equal(this.collection.models[3].get('id'), 2, 'passed in model to prev page handler')
      equal(this.collection.urls.prev, undefined, 'prev url not set when there is not one')
    },
  })
  return this.server.sendPage(page1, this.collection.urls.prev)
})

test('fetches current, prev, next, top and bottom pages', 8, function () {
  const page1 = getFakePage(1)
  const page2 = getFakePage(2)
  const page3 = getFakePage(3)
  const page4 = getFakePage(4)

  this.collection.fetch({
    success: () => {
      equal(this.collection.models[0].get('id'), 5, 'added model to collection')
      const expectedUrls = page3.urls
      expectedUrls.top = page3.urls.prev
      expectedUrls.bottom = page3.urls.next
      deepEqual(this.collection.urls, expectedUrls, 'urls are as expected for fetch')
    },
  })
  this.server.sendPage(page3, this.collection.urlWithParams())

  this.collection.fetch({
    page: 'current',
    success: () => {
      const expectedUrls = page3.urls
      expectedUrls.top = page3.urls.prev
      expectedUrls.bottom = page3.urls.next
      deepEqual(this.collection.urls, expectedUrls, 'urls are as expected for fetch current')
    },
  })
  this.server.sendPage(page3, this.collection.urlWithParams())

  this.collection.fetch({
    page: 'prev',
    success: () => {
      equal(this.collection.models.length, 4, 'added models to collection')
      const expectedUrls = page2.urls
      expectedUrls.top = page2.urls.prev
      expectedUrls.bottom = page3.urls.next // shouldn't change
      deepEqual(this.collection.urls, expectedUrls, 'urls are as expected fetch prev')
    },
  })
  this.server.sendPage(page2, this.collection.urls.prev)

  this.collection.fetch({
    page: 'top',
    success: () => {
      equal(this.collection.models.length, 6, 'added models to collection')
      const expectedUrls = page1.urls
      expectedUrls.bottom = page3.urls.next // shouldn't change
      deepEqual(this.collection.urls, expectedUrls, 'urls are as expected for fetch top')
    },
  })
  this.server.sendPage(page1, this.collection.urls.top)

  this.collection.fetch({
    page: 'bottom',
    success: () => {
      equal(this.collection.models.length, 8, 'added models to collection')
      equal(this.collection.urls.bottom, page4.urls.next)
    },
  })
  return this.server.sendPage(page4, this.collection.urls.bottom)
})
