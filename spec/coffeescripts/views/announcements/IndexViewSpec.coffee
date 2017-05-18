#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'Backbone'
  'compiled/views/announcements/IndexView'
  'compiled/models/Announcement'
  'compiled/collections/AnnouncementsCollection'
  'helpers/getFakePage'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
  ], ($, Backbone, IndexView, Announcement, AnnouncementsCollection, fakePage, fakeENV) ->

  server = null
  collection = null
  view = null
  fixtures = $('#fixtures')

  idCount = 0

  createServer = ->
    server = sinon.fakeServer.create()
    server.sendPage = (page, url) ->
      anns = []
      id = idCount++
      for i in [0...50]
        anns[i] = new Announcement
        id: id + i
        title: 'announcement #' + (id + i)

      @respond 'GET', url, [200, {
        'Content-Type': 'application/json'
        'Link': page.header
      }, JSON.stringify anns]


  QUnit.module 'AnnouncementsIndexView',
    setup: ->
      fakeENV.setup(permissions: { manage_content: false })
      $('<div id="content"></div>').appendTo fixtures
      createServer()
      collection = new AnnouncementsCollection
      view = new IndexView
        autoFetch: true
        collection: collection
        permissions: {}
        scrollContainer: fixtures
      view.$el.appendTo fixtures
      view.render()

    teardown: ->
      fakeENV.teardown()
      fixtures.empty()
      server.restore()
      view.remove()


  test 'renders', ->
    collection.fetch()
    server.sendPage fakePage(), collection.url()

    ok view


  test 'screen reader search status doesn\'t update text if status
  hasn\'t changed', (assert) ->
    assert.expect 1
    done = assert.async 1

    collection.fetch()
    server.sendPage fakePage(), collection.url()

    hasChanged = false

    results  = $('#searchResultCount', fixtures)
    observer = new MutationObserver (mutations) ->
      mutations.forEach (mutation) ->
        # text changes are of type `childList`
        hasChanged = hasChanged || mutation.type == 'childList'

    observer.observe results.get(0), childList: true

    # get next page which will update the results status
    view.fetchedNextPage()

    setTimeout ->
      assert.equal hasChanged, false, 'status has not changed'
      done()
    , 1000
