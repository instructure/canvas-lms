/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {enhanceUserContent} from 'instructure'

let elem
QUnit.module('Enhance User Content', {
  setup() {
    elem = document.createElement('div')
    document.body.appendChild(elem)
  },

  teardown() {
    document.body.removeChild(elem)
  }
})

test('youtube preview gets alt text from link data-preview-alt', function() {
  const alt = 'test alt string'
  elem.innerHTML = `
    <div class="user_content">
      <a href="#" class="instructure_video_link" data-preview-alt="${alt}">
        Link
      </a>
    </div>
  `
  sandbox.stub($, 'youTubeID').returns(47)
  enhanceUserContent()
  equal(elem.querySelector('.media_comment_thumbnail').alt, alt)
})

test('youtube preview ignores missing alt', function() {
  elem.innerHTML = `
    <div class="user_content">
      <a href="#" class="instructure_video_link">
        Link
      </a>
    </div>
  `
  sandbox.stub($, 'youTubeID').returns(47)
  enhanceUserContent()
  ok(elem.querySelector('.media_comment_thumbnail').outerHTML.match('alt=""'))
})

test("enhance '.instructure_inline_media_comment' in questions", function() {
  const mediaCommentThumbnailSpy = sandbox.spy($.fn, 'mediaCommentThumbnail')
  elem.innerHTML = `
    <div class="user_content"></div>
    <div class="answers">
      <a href="#" class="instructure_inline_media_comment instructure_video_link">
        link
      </a>
    </div>
  `
  enhanceUserContent()
  equal(mediaCommentThumbnailSpy.thisValues[0].length, 1) // for .instructure_inline_media_comment
  equal(mediaCommentThumbnailSpy.thisValues[1].length, 1) // for .instructure_video_link
  $.fn.mediaCommentThumbnail.restore()
})
