/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import IndexView from 'compiled/views/announcements/IndexView'
import Announcement from 'compiled/models/Announcement'
import AnnouncementsCollection from 'compiled/collections/AnnouncementsCollection'
import fakePage from 'helpers/getFakePage'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

let server = null
let collection = null
let view = null
const fixtures = $('#fixtures')
let idCount = 0

function createServer() {
  server = sinon.fakeServer.create()
  server.sendPage = function(page, url) {
    const anns = []
    const id = idCount++
    for (let i = 0; i < 50; i++) {
      anns[i] = new Announcement({
        id: id + i,
        title: `announcement #${id + i}`
      })
    }

    return this.respond('GET', url, [
      200,
      {
        'Content-Type': 'application/json',
        Link: page.header
      },
      JSON.stringify(anns)
    ])
  }
}

QUnit.module('AnnouncementsIndexView', {
  setup() {
    fakeENV.setup({permissions: {manage_content: false}})
    $('<div id="content"></div>').appendTo(fixtures)
    createServer()
    collection = new AnnouncementsCollection()
    view = new IndexView({
      autoFetch: true,
      collection,
      permissions: {},
      scrollContainer: fixtures
    })
    view.$el.appendTo(fixtures)
    view.render()
  },

  teardown() {
    fakeENV.teardown()
    fixtures.empty()
    server.restore()
    view.remove()
  }
})

test('it should be accessible', assert => {
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('renders', () => {
  collection.fetch()
  server.sendPage(fakePage(), collection.url())

  ok(view)
})

test(`screen reader search status doesn't update text if status hasn't changed`, function(assert) {
  assert.expect(1)
  const done = assert.async(1)

  collection.fetch()
  server.sendPage(fakePage(), collection.url())

  let hasChanged = false

  const results = $('#searchResultCount', fixtures)
  const observer = new MutationObserver(mutations =>
    // text changes are of type `childList`
    mutations.forEach(mutation => (hasChanged = hasChanged || mutation.type === 'childList'))
  )

  observer.observe(results.get(0), {childList: true})

  // get next page which will update the results status
  view.fetchedNextPage()

  setTimeout(function() {
    assert.equal(hasChanged, false, 'status has not changed')
    done()
  }, 1000)
})
