/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {
  isImage,
  isAudioOrVideo,
  isVideo,
  isAudio,
  isText,
  mediaFileUrlToEmbeddedIframeUrl,
  embedded_iframe_url_fromFile
} from '../fileTypeUtils'

describe('fileTypeUtils', () => {
  describe('isImage', () => {
    it('detects audio types', () => {
      expect(isImage('image')).toBe(true)
      expect(isImage('image/png')).toBe(true)
    })
  })

  describe('isAudioOrVideo', () => {
    it('detects audio types', () => {
      expect(isAudioOrVideo('audio')).toBe(true)
      expect(isAudioOrVideo('audio/mp3')).toBe(true)
    })

    it('detects video types', () => {
      expect(isAudioOrVideo('video')).toBe(true)
      expect(isAudioOrVideo('video/mov')).toBe(true)
    })
  })

  describe('isVideo', () => {
    it('detects video types', () => {
      expect(isVideo('video')).toBe(true)
      expect(isVideo('video/mov')).toBe(true)
    })
  })

  describe('isAudio', () => {
    it('detects audio types', () => {
      expect(isAudio('audio')).toBe(true)
      expect(isAudio('audio/mp3')).toBe(true)
    })
  })

  describe('isText', () => {
    it('detects text types', () => {
      expect(isText('text')).toBe(true)
      expect(isText('text/html')).toBe(true)
    })
  })

  describe('mediaFileUrlToEmbeddedIframeUrl', () => {
    it('creates iframe URL for audio', () => {
      const fileurl = 'http://host:port/path/to/file?query=1'
      const url = mediaFileUrlToEmbeddedIframeUrl(fileurl, 'audio')
      expect(url).toBe(`/media_objects_iframe/?type=audio&mediahref=${encodeURIComponent(fileurl)}`)
    })

    it('creates iframe URL for video', () => {
      const fileurl = 'http://host:port/path/to/file?query=1'
      const url = mediaFileUrlToEmbeddedIframeUrl(fileurl, 'video')
      expect(url).toBe(`/media_objects_iframe/?type=video&mediahref=${encodeURIComponent(fileurl)}`)
    })
  })

  describe('embedded_iframe_url_fromFile', () => {
    it("returns url from input file's embedded_iframe_url", () => {
      const file = {
        embedded_iframe_url: '/media_objects_iframe/m-media_object_id'
      }
      const url = embedded_iframe_url_fromFile(file)
      expect(url).toBe(file.embedded_iframe_url)
    })

    it("creates url from file's media_entry_id", () => {
      const file = {
        media_entry_id: 'm-media_id'
      }
      const url = embedded_iframe_url_fromFile(file)
      expect(url).toBe('/media_objects_iframe/m-media_id')
    })

    it("creates url from file's url", () => {
      const file = {
        'content-type': 'video/mov',
        url: 'http://origin/path/to/file'
      }
      const url = embedded_iframe_url_fromFile(file)
      expect(url).toBe(
        `/media_objects_iframe/?type=video&mediahref=${encodeURIComponent(file.url)}`
      )
    })

    it("returns undefined if the file isn't media", () => {
      const file = {
        'content-type': 'text/palin',
        url: 'http://origin/path/to/file'
      }
      const url = embedded_iframe_url_fromFile(file)
      expect(url).toBe(undefined)
    })
  })
})
