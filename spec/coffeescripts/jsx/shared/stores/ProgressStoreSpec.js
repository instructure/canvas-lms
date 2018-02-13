#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'underscore',
  'jsx/shared/stores/ProgressStore'
], (_, ProgressStore, I18n) ->

  QUnit.module 'ProgressStoreSpec',
    setup: ->
      @progress_id = 2
      @progress = {
        id: @progress_id,
        context_id: 1,
        context_type: 'EpubExport',
        user_id: 1,
        tag: 'epub_export',
        completion: 0,
        workflow_state: 'queued'
      }

      @server = sinon.fakeServer.create()

    teardown: ->
      ProgressStore.clearState()
      @server.restore()

  test 'get', ->
    @server.respondWith('GET', '/api/v1/progress/' + @progress_id, [
      200, {'Content-Type': 'application/json'},
      JSON.stringify(@progress)
    ])
    ok _.isEmpty(ProgressStore.getState()), 'precondition'
    ProgressStore.get(@progress_id)
    @server.respond()

    state = ProgressStore.getState()
    deepEqual state[@progress.id], @progress
