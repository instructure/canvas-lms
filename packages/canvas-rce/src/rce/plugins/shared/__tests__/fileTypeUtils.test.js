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
  mediaPlayerURLFromFile
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

  describe('mediaPlayerURLFromFile', () => {
    it("creates url from input file's embedded_iframe_url", () => {
      const file = {
        embedded_iframe_url: '/media_objects_iframe/m-media_object_id',
        type: 'video/mov'
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe/m-media_object_id?type=video')
    })

    it("creates url from file's media_entry_id", () => {
      const file = {
        media_entry_id: 'm-media_id',
        content_type: 'audio/mp3'
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe/m-media_id?type=audio')
    })

    it("creates url from file's url", () => {
      const file = {
        'content-type': 'video/mov',
        url: 'http://origin/path/to/file'
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe?mediahref=/path/to/file&type=video')
    })

    it("returns undefined if the file isn't media", () => {
      const file = {
        'content-type': 'text/palin',
        url: 'http://origin/path/to/file'
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe(undefined)
    })

    it("includes the file verifier if it's part of the file's url", () => {
      const file = {
        'content-type': 'video/mov',
        url: 'http://origin/path/to/file?verifier=xyzzy'
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe?mediahref=/path/to/file&verifier=xyzzy&type=video')
    })
  })
})
