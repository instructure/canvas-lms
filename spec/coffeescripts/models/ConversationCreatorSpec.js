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
  'compiled/models/ConversationCreator'
], (ConversationCreator) ->

  QUnit.module "ConversationCreator",
    setup: ->
      @cc = new ConversationCreator(chunkSize: 2)
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()

  respond = (data) ->

  test "#validate passes through to Conversation", ->
    ok @cc.validate(body: '')
    ok @cc.validate(body: null).body
    ok @cc.validate(body: 'body', recipients: [{}]) == undefined

  test "#save calls save in batches", ->
    spy = @spy()
    @server.respondWith("POST", '/api/v1/conversations', (xhr) ->
      spy()
      xhr.respond([200, { "Content-Type": "application/json"}, JSON.stringify({})])
    )
    dfd = @cc.save(body: 'body', recipients: [1, 2, 3, 4])
    equal dfd.state(), "pending"
    @server.respond()
    equal dfd.state(), "resolved"
    ok spy.calledTwice
