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
  'jquery'
  'underscore'
  'compiled/behaviors/instructure_inline_media_comment'
], ($, _, inlineMediaComment) ->

  oldTrackEvent = null

  QUnit.module 'inlineMediaComment',
    setup: ->
      oldTrackEvent = $.trackEvent
      @fixtures = document.getElementById('fixtures')
      @fixtures.innerHTML = "<a data-media_comment_id=42 class='instructure_inline_media_comment' href='42' tabindex=0></a>"
      window.INST.kalturaSettings = "settings set"
    teardown: ->
      $.trackEvent = oldTrackEvent
      @fixtures.innerHTML = ""
      window.INST.kalturaSettings = null

  test 'anchor tag with proper class triggers media load when clicked', ->
    $.trackEvent = (()-> null)
    $link = $(@fixtures).find('a')
    $link.click()
    ok($link.next().html().match(/Loading media/))

  test "buildMinimizerLink generates a destinationless a tag", ->
    link = inlineMediaComment.buildMinimizerLink()
    ok(link.is("a"))
    equal(link.attr('href'), "#")

  test "buildHolder contains a tabindex for better tab navigation", ->
    holder = inlineMediaComment.buildCommentHolder()
    ok(holder.html().match(/tabindex="0"/))

  test "getMediaCommentId pulls straight from data element", ->
    $link = $("<a data-media_comment_id='42'></a>")
    id = inlineMediaComment.getMediaCommentId($link)
    equal("42", id)

  test "getMediaCommentId can pull from an inner element in an html block", ->
    $link = $("<a><span class='media_comment_id'>24</span></a>")
    id = inlineMediaComment.getMediaCommentId($link)
    equal("24", id)
