/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import assert from 'assert'
import {fileEmbed, mimeClass} from '../../src/common/mimeClass'

describe('fileEmbed', () => {
  const base_file = {preview_url: 'some_url'}

  function getBaseFile(...args) {
    return Object.assign({}, base_file, ...args)
  }

  it('defaults to file', () => {
    assert.equal(fileEmbed({}).type, 'file')
  })

  it('uses content-type to identify video and audio', () => {
    const video = fileEmbed(getBaseFile({'content-type': 'video/mp4'}))
    const audio = fileEmbed(getBaseFile({'content-type': 'audio/mpeg'}))
    const notaudio = fileEmbed(
      getBaseFile({'content-type': 'x-audio/mpeg', preview_url: undefined})
    )
    const notvideo = fileEmbed(getBaseFile({'content-type': 'x-video/mp4', preview_url: undefined}))

    assert.equal(video.type, 'video')
    assert.equal(video.id, 'maybe')
    assert.equal(audio.type, 'audio')
    assert.equal(audio.id, 'maybe')
    assert.equal(notaudio.type, 'file')
    assert.equal(notvideo.type, 'file')
  })

  it('returns media entry id if provided', () => {
    const video = fileEmbed(
      getBaseFile({
        'content-type': 'video/mp4',
        media_entry_id: '42'
      })
    )
    assert.equal(video.id, '42')
  })

  it('returns maybe in place of media entry id if not provided', () => {
    const video = fileEmbed(getBaseFile({'content-type': 'video/mp4'}))
    assert.equal(video.id, 'maybe')
  })

  it('picks scribd if there is a preview_url', () => {
    const scribd = fileEmbed(getBaseFile({preview_url: 'some-url'}))
    assert.equal(scribd.type, 'scribd')
  })

  it('uses content-type to identify images', () => {
    const png = fileEmbed(getBaseFile({'content-type': 'image/png'}))
    const svg = fileEmbed(getBaseFile({'content-type': 'image/svg+xml'}))

    assert.equal(png.type, 'image')
    assert.equal(svg.type, 'image')
  })
})

describe('mimeClass', () => {
  it('returns mime_class attribute if present', () => {
    const mime_class = 'wooper'
    assert.equal(mimeClass({mime_class}), mime_class)
  })

  it('returns value corresponding to provided `content-type`', () => {
    assert.equal(mimeClass({'content-type': 'video/mp4'}), 'video')
    assert.equal(mimeClass({'content-type': 'audio/webm'}), 'audio')
    assert.equal(mimeClass({'content-type': 'image/svg+xml'}), 'image')
    assert.equal(mimeClass({'content-type': 'image/webp'}), 'file')
    assert.equal(mimeClass({'content-type': 'application/vnd.ms-powerpoint'}), 'ppt')
  })

  it('returns value corresponding to provided `type`', () => {
    assert.equal(mimeClass({type: 'video/mp4'}), 'video')
    assert.equal(mimeClass({type: 'audio/webm'}), 'audio')
    assert.equal(mimeClass({type: 'image/svg+xml'}), 'image')
    assert.equal(mimeClass({type: 'image/webp'}), 'file')
    assert.equal(mimeClass({type: 'application/vnd.ms-powerpoint'}), 'ppt')
  })
})
