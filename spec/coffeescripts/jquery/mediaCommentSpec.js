/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import MediaUtils from 'compiled/jquery/mediaComment'

QUnit.module('mediaComment', {
  setup() {
    this.server = sinon.fakeServer.create()
    window.INST.kalturaSettings = 'settings set'
    this.$holder = $('<div id="media-holder">').appendTo('#fixtures')
  },
  teardown() {
    window.INST.kalturaSettings = null
    this.server.restore()
    this.$holder.remove()
    $('#fixtures').empty()
  }
})
const mockServerResponse = (server, id, type = 'video') => {
  const resp = {
    media_sources: [
      {
        content_type: 'flv',
        url: 'http://some_flash_url.com'
      },
      {
        content_type: 'mp4',
        url: 'http://some_mp4_url.com'
      }
    ]
  }
  return server.respond('GET', `/media_objects/${id}/info`, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(resp)
  ])
}
test('video player is displayed inline', function() {
  const id = 10 // ID doesn't matter since we mock out the server
  this.$holder.mediaComment('show_inline', id)
  mockServerResponse(this.server, id)
  const video_tag_exists = this.$holder.find('video').length === 1
  ok(video_tag_exists, 'There should be a video tag')
})

test('audio player is displayed correctly', function() {
  const id = 10 // ID doesn't matter since we mock out the server
  this.$holder.mediaComment('show_inline', id, 'audio')
  mockServerResponse(this.server, id, 'audio')
  equal(this.$holder.find('audio').length, 1, 'There should be a audio tag')
  equal(this.$holder.find('video').length, 0, 'There should not be a video tag')
})

test('video player includes url sources provided by the server', function() {
  const id = 10
  this.$holder.mediaComment('show_inline', id)
  mockServerResponse(this.server, id)
  equal(
    this.$holder.find('source[type=flv]').attr('src'),
    'http://some_flash_url.com',
    'Video contains the flash source'
  )
  equal(
    this.$holder.find('source[type=mp4]').attr('src'),
    'http://some_mp4_url.com',
    'Video contains the mp4 source'
  )
})

QUnit.module('MediaCommentUtils functions', {
  setup() {},
  teardown() {}
})

test('getElement includes width and height for video elements', () => {
  const $media = MediaUtils.getElement('video', '', 100, 200)
  equal($media.attr('width'), 100)
  equal($media.attr('height'), 200)
})

test('getElement doesnt care about width and height for audio elements', () => {
  const $media = MediaUtils.getElement('audio', '', 100, 200)
  equal($media.attr('width'), null)
  equal($media.attr('height'), null)
})

test("getElement adds preload='metadata' to both types", () => {
  const $video = MediaUtils.getElement('video', '', 100, 200)
  const $audio = MediaUtils.getElement('audio', '', 100, 200)
  equal($video.attr('preload'), 'metadata')
  equal($audio.attr('preload'), 'metadata')
})

test('getElement puts source tags inside the element', () => {
  const st_tag = "<source src='something'></source>"
  const $audio = MediaUtils.getElement('audio', st_tag)
  equal($audio.html(), '<source src="something">')
})
