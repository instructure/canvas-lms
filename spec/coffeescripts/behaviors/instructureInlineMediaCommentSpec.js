/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import inlineMediaComment from 'compiled/behaviors/instructure_inline_media_comment'

let oldTrackEvent = null

QUnit.module('inlineMediaComment', {
  setup() {
    oldTrackEvent = $.trackEvent
    this.fixtures = document.getElementById('fixtures')
    this.fixtures.innerHTML = "<a data-media_comment_id=42 class='instructure_inline_media_comment' href='42' tabindex=0></a>"
    window.INST.kalturaSettings = 'settings set'
  },
  teardown() {
    $.trackEvent = oldTrackEvent
    this.fixtures.innerHTML = ''
    window.INST.kalturaSettings = null
  }
})

test('anchor tag with proper class triggers media load when clicked', function() {
  $.trackEvent = () => null
  const $link = $(this.fixtures).find('a')
  $link.click()
  ok(
    $link
      .next()
      .html()
      .match(/Loading media/)
  )
})

test('buildMinimizerLink generates a destinationless a tag', () => {
  const link = inlineMediaComment.buildMinimizerLink()
  ok(link.is('a'))
  equal(link.attr('href'), '#')
})

test('buildHolder does not contain a tabindex for better tab navigation', () => {
  const holder = inlineMediaComment.buildCommentHolder()
  ok(holder.html().match(/tabindex="-1"/))
})

test('getMediaCommentId pulls straight from data element', () => {
  const $link = $("<a data-media_comment_id='42'></a>")
  const id = inlineMediaComment.getMediaCommentId($link)
  equal('42', id)
})

test('getMediaCommentId can pull from an inner element in an html block', () => {
  const $link = $("<a><span class='media_comment_id'>24</span></a>")
  const id = inlineMediaComment.getMediaCommentId($link)
  equal('24', id)
})

test('video in td has minimum size of 300', function() {
  $.trackEvent = () => null
  this.fixtures.innerHTML =
    "<table><tbody><tr><td><a data-media_comment_id=42 class='instructure_inline_media_comment' href='42' tabindex=0></a></td></tr></tbody></table>"
  const $link = $(this.fixtures).find('a')
  $link.click()
  equal('300px', $link.closest('td').css('width'))
})
