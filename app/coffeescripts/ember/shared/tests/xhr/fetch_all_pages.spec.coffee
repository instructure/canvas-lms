#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'ember'
  '../../xhr/fetch_all_pages'
  '../shared_ajax_fixtures'
], (Ember, fetchAllPages, fixtures) ->

  ArrayProxy = Ember.ArrayProxy

  QUnit.module 'Fetch all pages component',
    setup: ->
      # yes, this looks weird.  if you run
      # screenreader gradebook tests before this, it puts
      # ember into test mode, and everything dies here when we
      # try to do asynchronous work.  This spec was originally written
      # assuming that Ember was unmodified.  This will not impact the
      #  screenreader gradebook tests, because they call "setupForTesting"
      #  in every setup.
      Ember.testing = false
      fixtures.create()
      @server = sinon.createFakeServer()

    teardown: ->
      @server.restore()

  test 'passes records through by default', (assert) ->
    start = assert.async()
    fetchAllPages(ENV.numbers_url).promise.then (records) ->
      start()
      deepEqual(records.get('content'), [1, 2, 3])


  test 'populates existing array if provided', (assert) ->
    start = assert.async()
    myArray = ArrayProxy.create({content: []})
    fetchAllPages(ENV.numbers_url, records: myArray).promise.then ->
      start()
      deepEqual(myArray.get('content'), [1, 2, 3])

  test 'calls process if provided', (assert) ->
    start = assert.async()
    fetchAllPages(ENV.numbers_url, process: (response) ->
      response.map (x) -> x * 2
    ).promise.then (records) ->
      start()
      deepEqual(records.get('content'), [2, 4, 6])
