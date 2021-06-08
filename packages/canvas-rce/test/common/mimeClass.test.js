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
    assert.strictEqual(fileEmbed({}).type, 'file')
  })

  it('uses content-type to identify video and audio', () => {
    const video = fileEmbed(getBaseFile({'content-type': 'video/mp4'}))
    const audio = fileEmbed(getBaseFile({'content-type': 'audio/mpeg'}))
    const notaudio = fileEmbed(
      getBaseFile({'content-type': 'x-audio/mpeg', preview_url: undefined})
    )
    const notvideo = fileEmbed(getBaseFile({'content-type': 'x-video/mp4', preview_url: undefined}))

    assert.strictEqual(video.type, 'video')
    assert.strictEqual(audio.type, 'audio')
    assert.strictEqual(notaudio.type, 'file')
    assert.strictEqual(notvideo.type, 'file')
  })

  it('picks scribd if there is a preview_url', () => {
    const scribd = fileEmbed(getBaseFile({preview_url: 'some-url'}))
    assert.strictEqual(scribd.type, 'scribd')
  })

  it('uses content-type to identify images', () => {
    const png = fileEmbed(getBaseFile({'content-type': 'image/png'}))
    const svg = fileEmbed(getBaseFile({'content-type': 'image/svg+xml'}))

    assert.strictEqual(png.type, 'image')
    assert.strictEqual(svg.type, 'image')
  })
})

describe('mimeClass', () => {
  it('returns mime_class attribute if present', () => {
    const mime_class = 'wooper'
    assert.strictEqual(mimeClass({mime_class}), mime_class)
  })

  it('returns value corresponding to provided `content-type`', () => {
    assert.strictEqual(mimeClass({'content-type': 'video/mp4'}), 'video')
    assert.strictEqual(mimeClass({'content-type': 'video/*'}), 'video')
    assert.strictEqual(mimeClass({'content-type': 'video'}), 'video')
    assert.strictEqual(mimeClass({'content-type': 'audio/webm'}), 'audio')
    assert.strictEqual(mimeClass({'content-type': 'audio/*'}), 'audio')
    assert.strictEqual(mimeClass({'content-type': 'audio'}), 'audio')
    assert.strictEqual(mimeClass({'content-type': 'image/svg+xml'}), 'image')
    assert.strictEqual(mimeClass({'content-type': 'image/webp'}), 'file')
    assert.strictEqual(mimeClass({'content-type': 'application/vnd.ms-powerpoint'}), 'ppt')
  })

  it('returns value corresponding to provided `type`', () => {
    assert.strictEqual(mimeClass({type: 'video/mp4'}), 'video')
    assert.strictEqual(mimeClass({type: 'audio/webm'}), 'audio')
    assert.strictEqual(mimeClass({type: 'image/svg+xml'}), 'image')
    assert.strictEqual(mimeClass({type: 'image/webp'}), 'file')
    assert.strictEqual(mimeClass({type: 'application/vnd.ms-powerpoint'}), 'ppt')
  })
})
