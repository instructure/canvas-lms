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

import $ from 'jquery'
import 'jquery-migrate'
import Backbone from '@canvas/backbone'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import fakePage from 'helpers/getFakePage'
import fakeENV from 'helpers/fakeENV'

let server = null
let clock = null
let collection = null
let view = null
const fixtures = $('#fixtures')

function createServer() {
  server = sinon.fakeServer.create()
  return (server.sendPage = function (page, url) {
    return this.respond('GET', url, [
      200,
      {
        'Content-Type': 'application/json',
        Link: page.header,
      },
      JSON.stringify(page.data),
    ])
  })
}
class ItemView extends Backbone.View {
  tagName = 'li'

  template({id}) {
    return id
  }

  initialize() {
    super.initialize(...arguments)
    // make some scrolly happen
    this.$el.css('height', 500)
  }
}
class TestCollection extends PaginatedCollection {
  url = '/test'
}

QUnit.module('PaginatedCollectionView', {
  setup() {
    fakeENV.setup()
    fixtures.css({
      height: 500,
      overflow: 'auto',
    })
    createServer()
    clock = sinon.useFakeTimers()
    collection = new TestCollection()
    view = new PaginatedCollectionView({
      collection,
      itemView: ItemView,
      scrollContainer: fixtures,
    })
    view.$el.appendTo(fixtures)
    view.render()
  },
  teardown() {
    fakeENV.teardown()
    server.restore()
    clock.restore()
    fixtures.attr('style', '')
    view.remove()
  },
})

function assertItemRendered(id) {
  const $match = view.$list.children().filter((i, el) => el.innerHTML === id)
  ok($match.length, 'item found')
}

function scrollToBottom() {
  // scroll within 100px of the bottom of the current list (<500 triggers a fetch)
  fixtures[0].scrollTop =
    view.$el.position().top + view.$el.height() - fixtures.position().top - 100
  ok(fixtures[0].scrollTop > 0)
}
test('renders items', () => {
  collection.add({id: 1})
  assertItemRendered('1')
})

test('renders items on collection fetch and fetch next', () => {
  collection.fetch()
  server.sendPage(fakePage(), collection.url)
  assertItemRendered('1')
  assertItemRendered('2')
  collection.fetch({page: 'next'})
  server.sendPage(fakePage(2), collection.urls.next)
  assertItemRendered('3')
  assertItemRendered('4')
})

test('fetches the next page on scroll', () => {
  collection.fetch()
  server.sendPage(fakePage(), collection.url)
  scrollToBottom()
  // scroll event isn't firing in the test :( manually calling checkScroll
  view.checkScroll()
  ok(collection.fetchingNextPage, 'collection is fetching')
  server.sendPage(fakePage(2), collection.urls.next)
  assertItemRendered('3')
  assertItemRendered('4')
})

test("doesn't fetch if already fetching", () => {
  sandbox.spy(collection, 'fetch')
  sandbox.spy(view, 'hideLoadingIndicator')
  collection.fetch()
  view.checkScroll()
  ok(collection.fetch.calledOnce, 'fetch called once')
  ok(!view.hideLoadingIndicator.called, 'hideLoadingIndicator not called')
})

test('auto-fetches visible pages', () => {
  view.remove()
  view = new PaginatedCollectionView({
    collection,
    itemView: ItemView,
    scrollContainer: fixtures,
    autoFetch: true,
  })
  view.$el.appendTo(fixtures)
  view.render()
  fixtures.css({height: 1000}) // it will autofetch the second page, since we're within the threshold
  collection.fetch()
  server.sendPage(fakePage(), collection.url)
  assertItemRendered('1')
  assertItemRendered('2')
  clock.tick(0)
  server.sendPage(fakePage(2), collection.urls.next)
  assertItemRendered('3')
  assertItemRendered('4')
})

test('fetches every page until it reaches the last when fetchItAll is set', () => {
  view.remove()
  view = new PaginatedCollectionView({
    collection,
    itemView: ItemView,
    scrollContainer: fixtures,
    fetchItAll: true,
  })
  view.$el.appendTo(fixtures)
  view.render()
  fixtures.css({height: 1}) // to show that it will continue to load in the background even if it's filled the current view height
  collection.fetch()
  server.sendPage(fakePage(), collection.url)
  assertItemRendered('1')
  assertItemRendered('2')
  clock.tick(0)
  server.sendPage(fakePage(2), collection.urls.next)
  assertItemRendered('3')
  assertItemRendered('4')
})

test('stops fetching pages after the last page', () => {
  // see later in the test why this exists
  const fakeEvent = `foo.pagination:${view.cid}`
  fixtures.on(fakeEvent, () => ok(false, 'this should never run'))
  collection.fetch()
  server.sendPage(fakePage(), collection.url)
  for (let i = 2; i <= 10; i++) {
    collection.fetch({page: 'next'})
    server.sendPage(fakePage(i), collection.urls.next)
  }
  assertItemRendered('1')
  assertItemRendered('20')

  // this is ghetto, but data('events') is no longer around and I can't get
  // the scroll events to trigger, but this works because the
  // ".pagination:#{view.cid}" events are all wipe out on last fetch, so the
  // assertion at the beginning of the test in the handler shouldn't fire
  fixtures.trigger(fakeEvent)
})
