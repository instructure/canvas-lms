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

import {fileEmbed, mimeClass} from '../../src/common/mimeClass'

describe('fileEmbed', () => {
  const base_file = {preview_url: 'some_url'}

  function getBaseFile(...args) {
    return Object.assign({}, base_file, ...args)
  }

  it('defaults to file', () => {
    expect(fileEmbed({}).type).toEqual('file')
  })

  it('uses content-type to identify video and audio', () => {
    const video = fileEmbed(getBaseFile({'content-type': 'video/mp4'}))
    const audio = fileEmbed(getBaseFile({'content-type': 'audio/mpeg'}))
    const notaudio = fileEmbed(
      getBaseFile({'content-type': 'x-audio/mpeg', preview_url: undefined})
    )
    const notvideo = fileEmbed(getBaseFile({'content-type': 'x-video/mp4', preview_url: undefined}))

    expect(video.type).toEqual('video')
    expect(audio.type).toEqual('audio')
    expect(notaudio.type).toEqual('file')
    expect(notvideo.type).toEqual('file')
  })

  it('picks scribd if there is a preview_url', () => {
    const scribd = fileEmbed(getBaseFile({preview_url: 'some-url'}))
    expect(scribd.type).toEqual('scribd')
  })

  it('uses content-type to identify images', () => {
    const png = fileEmbed(getBaseFile({'content-type': 'image/png'}))
    const svg = fileEmbed(getBaseFile({'content-type': 'image/svg+xml'}))

    expect(png.type).toEqual('image')
    expect(svg.type).toEqual('image')
  })
})

describe('mimeClass', () => {
  it('returns mime_class attribute if present', () => {
    const mime_class = 'wooper'
    expect(mimeClass({mime_class})).toEqual(mime_class)
  })

  it('returns value corresponding to provided `content-type`', () => {
    expect(mimeClass({'content-type': 'video/mp4'})).toEqual('video')
    expect(mimeClass({'content-type': 'video/*'})).toEqual('video')
    expect(mimeClass({'content-type': 'video'})).toEqual('video')
    expect(mimeClass({'content-type': 'audio/webm'})).toEqual('audio')
    expect(mimeClass({'content-type': 'audio/*'})).toEqual('audio')
    expect(mimeClass({'content-type': 'audio'})).toEqual('audio')
    expect(mimeClass({'content-type': 'image/svg+xml'})).toEqual('image')
    expect(mimeClass({'content-type': 'image/webp'})).toEqual('image')
    expect(mimeClass({'content-type': 'application/vnd.ms-powerpoint'})).toEqual('ppt')
  })

  it('returns value corresponding to provided `type`', () => {
    expect(mimeClass({type: 'video/mp4'})).toEqual('video')
    expect(mimeClass({type: 'audio/webm'})).toEqual('audio')
    expect(mimeClass({type: 'image/svg+xml'})).toEqual('image')
    expect(mimeClass({type: 'image/webp'})).toEqual('image')
    expect(mimeClass({type: 'application/vnd.ms-powerpoint'})).toEqual('ppt')
  })
})
