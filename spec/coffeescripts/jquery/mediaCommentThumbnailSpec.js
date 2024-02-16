/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import 'jquery-migrate'
import '@canvas/media-comments/jquery/mediaCommentThumbnail'

const awhile = () => new Promise(resolve => setTimeout(resolve, 2))

QUnit.module('mediaCommentThumbnail', {
  setup() {
    window.INST.kalturaSettings = {
      resource_domain: 'example.com',
      partner_id: '12345',
    }
    const mediaComment = $(`
      <a
        id="media_comment_23"
        class="instructure_inline_media_comment video_comment"
        href="/media_objects/23"
        data-author="Tom"
        data-created_at="Oct 22 at 7:10pm"
      >
        this is a media comment
      </a>
    `)
    this.$fixtures = $('#fixtures')
    this.$fixtures.append(mediaComment)
  },

  teardown() {
    window.INST.kalturaSettings = null
    $('#fixtures').empty()
  },
})

test('creates a thumbnail span with a background image URL generated from kaltura settings and media id', async function () {
  // emulating the call from enhanceUserContent() in instructure.js
  $('.instructure_inline_media_comment', this.$fixtures).mediaCommentThumbnail('normal')
  await awhile()
  equal($('.media_comment_thumbnail', this.$fixtures).length, 1)
  ok(
    $('.media_comment_thumbnail', this.$fixtures)
      .first()
      .css('background-image')
      .indexOf(
        `https://example.com/p/12345/thumbnail/entry_id/23/width/140/height/100/bgcolor/000000/type/2/vid_sec/5`
      ) > 0
  )
})

test('creates screenreader text describing media comment', async function () {
  $('.instructure_inline_media_comment', this.$fixtures).mediaCommentThumbnail('normal')
  await awhile()
  const screenreaderText = document.querySelector(
    '.media_comment_thumbnail .screenreader-only'
  ).innerText
  strictEqual(screenreaderText, 'Play media comment by Tom from Oct 22 at 7:10pm.')
})

test('creates generic screenreader text if no authoring info provided', async function () {
  this.$fixtures.html('')
  this.$fixtures.append(
    $(`
    <a
      id="media_comment_23"
      class="instructure_inline_media_comment video_comment"
      href="/media_objects/23"
    >
      this is a media comment
    </a>
  `)
  )
  $('.instructure_inline_media_comment', this.$fixtures).mediaCommentThumbnail('normal')
  await awhile()
  const screenreaderText = document.querySelector(
    '.media_comment_thumbnail .screenreader-only'
  ).innerText
  strictEqual(screenreaderText, 'Play media comment.')
})
