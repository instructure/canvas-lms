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
  'compiled/models/Entry'
  'helpers/fakeENV'
], (Entry, fakeENV) ->

  QUnit.module 'Entry',
    setup: ->
      fakeENV.setup()
      @user_id = 1
      @server = sinon.fakeServer.create()
      ENV.DISCUSSION = {
        CURRENT_USER:
          id: @user_id
        DELETE_URL: 'discussions/:id/'
        PERMISSIONS:
          CAN_ATTACH: true
          CAN_MANAGE_OWN: true
      }
      @entry = new Entry(id: 1, message: 'a comment, wooper', user_id: @user_id)

    teardown: ->
      fakeENV.teardown()
      @server.restore()

  # sync
  test 'should persist replies locally, and call provided onComplete callback', ->
    @server.respondWith([200, {}, ''])
    replies = [new Entry(id: 2, message: 'a reply', parent_id: 1)]
    @entry.set('replies', replies)
    @setSpy = @spy(@entry, 'set')
    onCompleteCallback = @spy()

    @entry.sync('update', @entry, {
      complete: onCompleteCallback
    })
    @server.respond()

    ok @setSpy.calledWith('replies', [])
    ok @setSpy.calledWith('replies', replies)
    ok onCompleteCallback.called
