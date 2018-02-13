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
  'jquery',
  'helpers/util',
  'helpers/fakeENV',
  'compiled/views/conversations/MessageFormDialog',
  'compiled/collections/FavoriteCourseCollection',
  'compiled/collections/CourseCollection',
  'compiled/collections/GroupCollection'
], ($, util, fakeENV, MessageFormDialog, FavoriteCourseCollection, CourseCollection, GroupCollection) ->
  recipients = [
    {
      id: '9010000000000001', # rounds to 9010000000000000
      common_courses: [{0: 'FakeEnrollment'}],
      avatar_url: 'http://example.com',
      common_groups: {},
      name: 'first person'
    },
    {
      id: '9010000000000003', # rounds to 9010000000000004
      common_courses: [{0: 'FakeEnrollment'}],
      avatar_url: 'http://example.com',
      common_groups: {},
      name: 'second person'
    }
  ]

  dialog = null

  QUnit.module 'MessageFormDialog',
    setup: ->
      @server = sinon.fakeServer.create()
      @clock = sinon.useFakeTimers()
      util.useOldDebounce()

      fakeENV.setup
        CONVERSATIONS:
          CAN_MESSAGE_ACCOUNT_CONTEXT: false

    teardown: ->
      # $(".ui-dialog").remove()
      fakeENV.teardown()
      util.useNormalDebounce()
      @clock.restore()
      @server.restore()
      dialog.recipientView.remove()
      dialog.remove()

  test 'recipient ids are not parsed as numbers', ->
    dialog = new MessageFormDialog
      courses:
        favorites: new FavoriteCourseCollection()
        all: new CourseCollection()
        groups: new GroupCollection()
    dialog.show(null, {})

    dialog.recipientView.$input.val('person')
    dialog.recipientView.$input.trigger('input')
    @clock.tick(250)

    @server.respond 'GET', /recipients/, [
      200
      'Content-Type': 'application/json'
      JSON.stringify(recipients)
    ]

    equal dialog.recipientView.selectedModel.id, '9010000000000001'

    dialog.recipientView.$el.find('.ac-result:eq(1)').trigger($.Event('mousedown', button: 0));
    deepEqual(dialog.recipientView.tokens, ['9010000000000003'])
    parent = dialog.$el.parent()[0]
    document.body.removeChild(parent)
