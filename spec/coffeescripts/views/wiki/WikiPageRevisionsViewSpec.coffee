#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'compiled/collections/WikiPageRevisionsCollection'
  'compiled/views/wiki/WikiPageRevisionsView'
], ($, WikiPageRevisionsCollection, WikiPageRevisionsView) ->

  QUnit.module 'WikiPageRevisionsView',
    setup: ->
    teardown: ->
      document.getElementById("fixtures").innerHTML = ""

  test 'selecting a model/view sets the selected attribute on the model', ->
    fixture = $('<div id="main"><div id="content"></div></div>').appendTo('#fixtures')

    collection = new WikiPageRevisionsCollection
    view = new WikiPageRevisionsView collection: collection
    view.$el.appendTo('#content')
    view.render()

    collection.add(revision_id: 21)
    collection.add(revision_id: 37)
    strictEqual collection.models.length, 2, 'models added to collection'

    view.setSelectedModelAndView(collection.models[0], collection.models[0].view)
    strictEqual collection.models[0].get('selected'), true, 'selected attribute set'
    strictEqual collection.models[1].get('selected'), false, 'selected attribute not set'

    view.setSelectedModelAndView(collection.models[1], collection.models[1].view)
    strictEqual collection.models[0].get('selected'), false, 'selected attribute not set'
    strictEqual collection.models[1].get('selected'), true, 'selected attribute set'

    fixture.remove()

  test 'prevPage fetches previous page from collection', ->
    collection = new WikiPageRevisionsCollection
    @mock(collection).expects('fetch').atLeast(1).withArgs(page: 'prev', reset: true).returns($.Deferred())
    view = new WikiPageRevisionsView collection: collection
    view.prevPage()

  test 'nextPage fetches next page from collection', ->
    collection = new WikiPageRevisionsCollection
    @mock(collection).expects('fetch').atLeast(1).withArgs(page: 'next', reset: true).returns($.Deferred())
    view = new WikiPageRevisionsView collection: collection
    view.nextPage()

  test 'toJSON - CAN.FETCH_PREV', ->
    collection = new WikiPageRevisionsCollection
    view = new WikiPageRevisionsView collection: collection
    @stub(collection, 'canFetch').callsFake((arg) -> arg == 'prev')

    strictEqual view.toJSON().CAN?.FETCH_PREV, true, 'can fetch previous'

  test 'toJSON - CAN.FETCH_NEXT', ->
    collection = new WikiPageRevisionsCollection
    view = new WikiPageRevisionsView collection: collection
    @stub(collection, 'canFetch').callsFake((arg) -> arg == 'next')

    strictEqual view.toJSON().CAN?.FETCH_NEXT, true, 'can fetch next'
