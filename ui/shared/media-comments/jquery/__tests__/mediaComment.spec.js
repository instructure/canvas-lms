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
import $ from 'jquery'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

describe('getSourcesAndTracks', () => {
  beforeAll(() => {
    $.getJSON = jest.fn()
  })

  beforeEach(() => {
    jest.resetModules()
  })

  afterAll(() => {
    $.getJSON.mockRestore()
  })

  it('with no attachment id', () => {
    getSourcesAndTracks(1)
    expect($.getJSON).toHaveBeenCalledWith('/media_objects/1/info', expect.anything())
  })

  it('with an attachment id', () => {
    getSourcesAndTracks(1, 4)
    expect($.getJSON).toHaveBeenCalledWith('/media_attachments/4/info', expect.anything())
  })

  it('should return sources and tracks in the old format when studio_media_capture_enabled is false', async () => {
    ENV.studio_media_capture_enabled = false
    // Mock response
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

    // Mock $.getJSON to return the mock response
    jest.spyOn($, 'getJSON').mockImplementation((url, callback) => {
      callback(mockResponse)
      return $.Deferred().resolve(mockResponse).promise()
    })

    const id = '123'
    const result = await getSourcesAndTracks(id)

    expect(result.sources).toEqual([
      "<source type='video&#x2F;mp4' src='http:&#x2F;&#x2F;example.com&#x2F;video_low.mp4' title='320x180 244 kbps' />",
      "<source type='video&#x2F;mp4' src='http:&#x2F;&#x2F;example.com&#x2F;video.mp4' title='640x360 488 kbps' />",
    ])
    expect(result.tracks).toEqual([
      "<track kind='subtitles' label='English' src='http:&#x2F;&#x2F;example.com&#x2F;track.vtt' srclang='en' data-inherited-track='' />",
    ])
  })

  it('should return sources and tracks in the new format when studio_media_capture_enabled is true', async () => {
    ENV.studio_media_capture_enabled = true
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

    // Mock $.getJSON to return the mock response
    jest.spyOn($, 'getJSON').mockImplementation((url, callback) => {
      callback(mockResponse)
      return $.Deferred().resolve(mockResponse).promise()
    })

    const id = '123'
    const result = await getSourcesAndTracks(id)

    expect(result.sources).toEqual([
      {
        src: 'http://example.com/video_low.mp4',
        label: '320x180 244 kbps',
      },
      {
        src: 'http://example.com/video.mp4',
        label: '640x360 488 kbps',
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
