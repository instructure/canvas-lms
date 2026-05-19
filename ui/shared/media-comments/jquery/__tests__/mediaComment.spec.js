//
// Copyright (C) 2023 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {getSourcesAndTracks} from '../mediaComment'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

describe('getSourcesAndTracks', () => {
  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    vi.resetAllMocks()
  })

  it('with no attachment id', async () => {
    let requestUrl = null
    server.use(
      http.get('/media_objects/:id/info', ({request}) => {
        requestUrl = request.url
        return HttpResponse.json({
          media_sources: [],
          media_tracks: [],
        })
      }),
    )

    getSourcesAndTracks(1)
    await new Promise(resolve => setTimeout(resolve, 10))

    expect(requestUrl).toContain('/media_objects/1/info')
  })

  it('with an attachment id', async () => {
    let requestUrl = null
    server.use(
      http.get('/media_attachments/:id/info', ({request}) => {
        requestUrl = request.url
        return HttpResponse.json({
          media_sources: [],
          media_tracks: [],
        })
      }),
    )

    getSourcesAndTracks(1, 4)
    await new Promise(resolve => setTimeout(resolve, 10))

    expect(requestUrl).toContain('/media_attachments/4/info')
  })

  it('should return sources and tracks in the new format ', async () => {
    const mockResponse = {
      media_sources: [
        {
          url: 'http://example.com/video.mp4',
          content_type: 'video/mp4',
          width: 640,
          height: 360,
          bitrate: 500000,
        },
        {
          url: 'http://example.com/video_low.mp4',
          content_type: 'video/mp4',
          width: 320,
          height: 180,
          bitrate: 250000,
        },
      ],
      media_tracks: [{url: 'http://example.com/track.vtt', kind: 'subtitles', locale: 'en'}],
      can_add_captions: true,
    }

    // Setup MSW to return the mock response
    server.use(
      http.get('/media_objects/:id/info', () => {
        return HttpResponse.json(mockResponse)
      }),
    )

    const id = '123'
    const result = await getSourcesAndTracks(id)

    expect(result.sources).toEqual([
      {
        src: 'http://example.com/video_low.mp4',
        label: '320x180 244 kbps',
        height: 180,
        width: 320,
      },
      {
        src: 'http://example.com/video.mp4',
        label: '640x360 488 kbps',
        height: 360,
        width: 640,
      },
    ])
    expect(result.tracks).toEqual([
      {
        id: '123',
        type: 'subtitles',
        label: 'English',
        src: '/track.vtt',
        language: 'en',
      },
    ])
  })
})
