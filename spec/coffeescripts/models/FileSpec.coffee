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
  'compiled/models/File'
  'Backbone'
], ($, File, {Model}) ->

  server = null
  model = null

  QUnit.module 'File',
    setup: ->
      server = sinon.fakeServer.create()
      $el = $('<input type="file">')
      model = new File(null, preflightUrl: '/preflight')
      model.set file: $el[0]

    teardown: ->
      server.restore()

  test 'hits the preflight and then does a saveFrd', ->
    server.respondWith("POST", "/preflight", [200, {"Content-Type": "application/json"}, '{"upload_params": {}, "file_param": "file", "upload_url": "/upload"}'])
    # can't fake the upload with the server, since it's a hidden iframe post, not XHR
    stub = @stub Model.prototype, 'save'
    model.save()
    ok !stub.called
    server.respond()
    ok stub.called

  test 'returns a useful deferred', ->
    server.respondWith("POST", "/preflight", [500, {}, ""])

    dfrd = model.save()
    equal dfrd.state(), "pending"
    server.respond()
    equal dfrd.state(), "rejected"

  test 'saveFrd handles attachments wrapped in array per JSON API style', ->
    server.respondWith("POST", "/preflight", [200, {"Content-Type": "application/json"}, '{"attachments": [{"upload_url": "/upload", "upload_params": {"Policy": "TEST"}, "file_param": "file"}]}'])

    # can't fake the upload with the server, since it's a hidden iframe post, not XHR
    @stub Model.prototype, 'save'
    model.save()
    server.respond()
    strictEqual model.get("Policy"), "TEST"
