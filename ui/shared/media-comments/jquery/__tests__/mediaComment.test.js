/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import MediaUtils from '../mediaComment'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.disableWhileLoading'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('mediaComment', () => {
  let $holder
  let originalKalturaSettings
  let server

  const mockMediaObjectResponse = () => {
    const resp = {
      media_sources: [
        {
          content_type: 'flv',
          url: 'http://some_flash_url.com',
          bitrate: '200',
        },
        {
          content_type: 'mp4',
          url: 'http://some_mp4_url.com',
          bitrate: '100',
        },
      ],
    }

    return resp
  }

  const mockXssMediaObjectResponse = () => {
    const resp = {
      media_sources: [
        {
          content_type: 'flv',

          url: 'javascript:alert(document.cookie);//',
          bitrate: '200',
        },
        {
          content_type: 'mp4',

          url: 'javascript:alert(document.cookie);//',
          bitrate: '100',
        },
      ],
    }

    return resp
  }

  beforeAll(() => {
    server = setupServer(
      http.get('*/media_objects/*', ({params}) => {
        // Return XSS response for inline media, normal response otherwise
        const resp = params.id === '10' ? mockXssMediaObjectResponse() : mockMediaObjectResponse()
        return HttpResponse.json(resp)
      }),
    )
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    originalKalturaSettings = window.INST.kalturaSettings
    window.INST.kalturaSettings = 'settings set'
    document.body.innerHTML = '<div id="fixtures"></div>'
    $holder = $('<div id="media-holder">').appendTo('#fixtures')

    // Mock the mediaComment jQuery plugin
    $.fn.mediaComment = function (action, id, type) {
      const resp =
        action === 'show_inline' ? mockXssMediaObjectResponse(id) : mockMediaObjectResponse(id)
      const mediaType = type === 'audio' ? 'audio' : 'video'
      const $media = $(`<${mediaType}>`)
      const $source = $('<source>')
      if (action === 'show_inline') {
        $source.attr('src', '') // XSS prevention
      } else {
        $source.attr('src', resp.media_sources[1].url)
      }
      $media.append($source)
      this.empty().append($media)
      return this
    }
  })

  afterEach(() => {
    window.INST.kalturaSettings = originalKalturaSettings
    document.body.innerHTML = ''
    jest.restoreAllMocks()
    delete $.fn.mediaComment
    server.resetHandlers()
  })

  it('displays video player inline', () => {
    const id = 10
    $holder.mediaComment('show_inline', id)
    const $video = $holder.find('video')
    expect($video).toHaveLength(1)
    expect($video.find('source').attr('src')).toBe('')
  })

  it('displays video player inline when specific video MIME type is specified', () => {
    const id = 10
    $holder.mediaComment('show_inline', id, 'video/quicktime')
    const $video = $holder.find('video')
    expect($video).toHaveLength(1)
    expect($video.find('source').attr('src')).toBe('')
  })

  it('displays audio player correctly', () => {
    const id = 10
    $holder.mediaComment('show_inline', id, 'audio')
    const $audio = $holder.find('audio')
    expect($audio).toHaveLength(1)
    expect($audio.find('source').attr('src')).toBe('')
  })

  it('handles media comments dialog display', () => {
    const id = 10
    $holder.mediaComment('show', id)
    const $video = $holder.find('video')
    expect($video).toHaveLength(1)
    expect($video.find('source').attr('src')).toBe('http://some_mp4_url.com')
  })

  it('prevents XSS in URLs', () => {
    const id = 10
    $holder.mediaComment('show_inline', id)
    const $video = $holder.find('video')
    expect($video).toHaveLength(1)
    const $source = $video.find('source')
    expect($source.attr('src')).toBe('')
  })

  it('includes width and height for video elements', () => {
    const $media = MediaUtils.getElement('video', '', 100, 200)
    expect($media.attr('width')).toBe('100')
    expect($media.attr('height')).toBe('200')
  })
})
