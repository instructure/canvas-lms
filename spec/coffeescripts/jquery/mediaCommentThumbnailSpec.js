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
  'jquery'
  'underscore'
  'compiled/jquery/mediaCommentThumbnail'
], ($, _)->
  # fragile spec

  QUnit.module 'mediaCommentThumbnail',
    setup: ->
      # flop out the _.defer function to just call directly down to the passed
      # function reference. this helps the tests run in a synchronous order
      # internally so asserts can work like we expect.
      @stub(_, 'defer').callsFake((func, args...) -> func(args...))
      @$fixtures = $('#fixtures')

    teardown: ->
      window.INST.kalturaSettings = null
      $("#fixtures").empty()

  test "creates a thumbnail span with a background image URL generated from kaltura settings and media id", ->
    resourceDomain = 'resources.example.com'
    mediaId        = 'someExternalId'
    partnerId      = '12345'
    mediaComment   = $("""
      <a id="media_comment_#{mediaId}" class="instructure_inline_media_comment video_comment" href="/media_objects/#{mediaId}">
        this is a media comment
      </a>
      """)
    window.INST.kalturaSettings = {
      resource_domain: resourceDomain
      partner_id:      partnerId
    }
    @$fixtures.append mediaComment

    # emulating the call from enhanceUserContent() in instructure.js
    $('.instructure_inline_media_comment', @$fixtures).mediaCommentThumbnail('normal')

    equal $('.media_comment_thumbnail', @$fixtures).length, 1
    ok $('.media_comment_thumbnail', @$fixtures).first().css('background-image').indexOf("https://#{resourceDomain}/p/#{partnerId}/thumbnail/entry_id/#{mediaId}/width/140/height/100/bgcolor/000000/type/2/vid_sec/5") > 0
