/**
 * Copyright (C) 2016 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'jquery',
  'instructure'
], ($, instructure) => {
  let elem

  module("Enhance User Content", {
    setup () {
      elem = document.createElement('div')
      document.body.appendChild(elem)
    },

    teardown () {
      document.body.removeChild(elem)
    }
  });

  test("youtube preview gets alt text from link data-preview-alt", function () {
    const alt = 'test alt string'
    elem.innerHTML =
      `<div class="user_content">
        <a href="#" class="instructure_video_link" data-preview-alt="${alt}">
          Link
        </a>
      </div>`
    this.stub($, 'youTubeID').returns(47)
    instructure.enhanceUserContent()
    equal(elem.querySelector('.media_comment_thumbnail').alt, alt)
  }); 

  test("youtube preview ignores missing alt", function () {
    elem.innerHTML =
      `<div class="user_content">
        <a href="#" class="instructure_video_link">
          Link
        </a>
      </div>`
    this.stub($, 'youTubeID').returns(47)
    instructure.enhanceUserContent()
    equal(elem.querySelector('.media_comment_thumbnail').alt, "")
  }); 
})
