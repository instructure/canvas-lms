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
  getIWorkType,
  isAudio,
  isAudioOrVideo,
  isImage,
  isIWork,
  isText,
  isVideo,
  mediaPlayerURLFromFile,
  getIconFromType,
} from '../fileTypeUtils'
import RCEGlobals from '../../../RCEGlobals'
import {
  IconAudioLine,
  IconDocumentLine,
  IconMsExcelLine,
  IconMsPptLine,
  IconMsWordLine,
  IconPdfLine,
  IconVideoLine,
} from '@instructure/ui-icons'

describe('fileTypeUtils', () => {
  describe('isImage', () => {
    it('detects image types', () => {
      expect(isImage('image')).toBe(true)
      expect(isImage('image/png')).toBe(true)
      expect(isImage('image/jpeg')).toBe(true)
      expect(isImage('image/gif')).toBe(true)
      expect(isImage('image/webp')).toBe(true)
    })

    it('rejects non-image types', () => {
      expect(isImage('text/plain')).toBe(false)
      expect(isImage('application/pdf')).toBe(false)
      expect(isImage('')).toBe(false)
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
      expect(isText('text/plain')).toBe(true)
      expect(isText('text/css')).toBe(true)
      expect(isText('text/javascript')).toBe(true)
    })

    it('rejects non-text types', () => {
      expect(isText('application/json')).toBe(false)
      expect(isText('image/png')).toBe(false)
      expect(isText('plain/text')).toBe(false)
      expect(isText('')).toBe(false)
    })
  })

  describe('isIWork', () => {
    it('detects all iWork types', () => {
      expect(isIWork('test.pages')).toBe(true)
      expect(isIWork('test.key')).toBe(true)
      expect(isIWork('test.numbers')).toBe(true)
    })

    it('does not match on non iWork file names', () => {
      expect(isIWork('bad.pages.test')).toBe(false)
      expect(isIWork('nota.keyfile')).toBe(false)
      expect(isIWork('.numbersisnotthisfiletype')).toBe(false)
    })

    it('ignores case', () => {
      expect(isIWork('TEST.PAGES')).toBe(true)
      expect(isIWork('TEST.KEY')).toBe(true)
      expect(isIWork('TEST.NUMBERS')).toBe(true)
    })
  })

  describe('getIWorkType', () => {
    it('returns the proper type for iWork files', () => {
      expect(getIWorkType('test.pages')).toEqual('application/vnd.apple.pages')
      expect(getIWorkType('test.key')).toEqual('application/vnd.apple.keynote')
      expect(getIWorkType('test.numbers')).toEqual('application/vnd.apple.numbers')
    })

    it('ignores case', () => {
      expect(getIWorkType('TEST.PAGES')).toEqual('application/vnd.apple.pages')
      expect(getIWorkType('TEST.KEY')).toEqual('application/vnd.apple.keynote')
      expect(getIWorkType('TEST.NUMBERS')).toEqual('application/vnd.apple.numbers')
    })

    it('returns empty string if there is no extension in filename', () => {
      expect(getIWorkType('badfilename')).toEqual('')
    })

    it('returns empty string if the extension is not iWork', () => {
      expect(getIWorkType('test.txt')).toEqual('')
    })
  })

  describe('getIconFromType', () => {
    it('returns video icon for video types', () => {
      expect(getIconFromType('video/mp4')).toBe(IconVideoLine)
      expect(getIconFromType('video/quicktime')).toBe(IconVideoLine)
    })

    it('returns audio icon for audio types', () => {
      expect(getIconFromType('audio/mp3')).toBe(IconAudioLine)
      expect(getIconFromType('audio/wav')).toBe(IconAudioLine)
    })

    it('returns word icon for word processing types', () => {
      expect(getIconFromType('application/msword')).toBe(IconMsWordLine)
      expect(
        getIconFromType('application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
      ).toBe(IconMsWordLine)
      expect(getIconFromType('application/vnd.apple.pages')).toBe(IconMsWordLine)
    })

    it('returns powerpoint icon for presentation types', () => {
      expect(getIconFromType('application/vnd.ms-powerpoint')).toBe(IconMsPptLine)
      expect(
        getIconFromType(
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        ),
      ).toBe(IconMsPptLine)
      expect(getIconFromType('application/vnd.apple.keynote')).toBe(IconMsPptLine)
    })

    it('returns excel icon for spreadsheet types', () => {
      expect(getIconFromType('application/vnd.ms-excel')).toBe(IconMsExcelLine)
      expect(
        getIconFromType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      ).toBe(IconMsExcelLine)
      expect(getIconFromType('application/vnd.apple.numbers')).toBe(IconMsExcelLine)
    })

    it('returns pdf icon for pdf type', () => {
      expect(getIconFromType('application/pdf')).toBe(IconPdfLine)
    })

    it('returns default document icon for unknown types', () => {
      expect(getIconFromType('application/unknown')).toBe(IconDocumentLine)
      expect(getIconFromType('')).toBe(IconDocumentLine)
    })
  })

  describe('mediaPlayerURLFromFile', () => {
    it("creates url from input file's embedded_iframe_url", () => {
      const file = {
        embedded_iframe_url: '/media_objects_iframe/m-media_object_id',
        type: 'video/mov',
      }
      const url = mediaPlayerURLFromFile(file, 'https://mycanvas.com')
      expect(url).toBe('/media_objects_iframe/m-media_object_id?type=video')
    })

    it('does not repeat type if already included in embedded_iframe_url', () => {
      const file = {
        embedded_iframe_url: '/media_objects_iframe/m-media_object_id?type=video',
        type: 'video/mov',
      }
      const url = mediaPlayerURLFromFile(file, 'https://mycanvas.com')
      expect(url).toBe('/media_objects_iframe/m-media_object_id?type=video')
    })

    it("creates url from file's media_entry_id", () => {
      const file = {
        media_entry_id: 'm-media_id',
        content_type: 'audio/mp3',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe/m-media_id?type=audio')
    })

    it("creates url from file's url", () => {
      const file = {
        'content-type': 'video/mov',
        url: 'http://origin/path/to/file',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe?mediahref=/path/to/file&type=video')
    })

    it("returns undefined if the file isn't media", () => {
      const file = {
        'content-type': 'text/palin',
        url: 'http://origin/path/to/file',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe(undefined)
    })

    it("includes the file verifier if it's part of the file's url", () => {
      const file = {
        'content-type': 'video/mov',
        url: 'http://origin/path/to/file?verifier=xyzzy',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe?mediahref=/path/to/file&verifier=xyzzy&type=video')
    })

    it('throws error if content_type is invalid', () => {
      const file = {
        type: undefined,
      }
      expect(() => mediaPlayerURLFromFile(file)).toThrow('Invalid content type')
    })

    it('throws error if href is not string when checking verifier', () => {
      const file = {
        'content-type': 'video/mov',
        href: 123,
      }
      // @ts-expect-error
      expect(() => mediaPlayerURLFromFile(file)).toThrow('Invalid URL')
    })

    it('handles file with no id and no media_entry_id but valid audio content_type', () => {
      const file = {
        'content-type': 'audio/mp3',
        url: 'http://origin/audio.mp3',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe?mediahref=/audio.mp3&type=audio')
    })

    it('handles file with no embedded_iframe_url but is video without verifier', () => {
      const file = {
        'content-type': 'video/mp4',
        url: 'http://origin/video.mp4',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe?mediahref=/video.mp4&type=video')
    })

    it('throws error if file url is not a string', () => {
      const file = {
        'content-type': 'video/mp4',
        url: 42,
      }
      // @ts-expect-error
      expect(() => mediaPlayerURLFromFile(file)).toThrow('Invalid URL')
    })

    it('uses attachment route if id is present', () => {
      const file = {
        id: '123',
        type: 'video/mov',
        uuid: 'abc',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_attachments_iframe/123?type=video&embedded=true')
    })

    it('adds the uuid if the context is User', () => {
      const file = {
        id: '123',
        type: 'video/mov',
        contextType: 'User',
        uuid: 'abc',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_attachments_iframe/123?type=video&embedded=true&verifier=abc')
    })

    it("adds the uuid if the window location doesn't match the RCE location origin and the feature flag is on", () => {
      RCEGlobals.getFeatures = jest.fn().mockReturnValue({
        file_verifiers_for_quiz_links: true,
      })
      const file = {
        id: '123',
        type: 'video/mov',
        contextType: 'Course',
        uuid: 'abc',
      }
      const url = mediaPlayerURLFromFile(file, 'http://quizzes')
      expect(url).toBe('/media_attachments_iframe/123?type=video&embedded=true&verifier=abc')
    })

    it("doesn't add the uuid if the window location doesn't match the RCE location origin and the feature flag is off", () => {
      RCEGlobals.getFeatures = jest.fn().mockReturnValue({
        file_verifiers_for_quiz_links: false,
      })
      const file = {
        id: '123',
        type: 'video/mov',
        contextType: 'Course',
        uuid: 'abc',
      }
      const url = mediaPlayerURLFromFile(file, 'http://quizzes')
      expect(url).toBe('/media_attachments_iframe/123?type=video&embedded=true')
    })

    it('uses the file verifier if present', () => {
      const file = {
        id: '123',
        type: 'video/mov',
        url: 'host?verifier=something',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe(
        '/media_attachments_iframe/123?type=video&embedded=true&verifier=something',
      )
    })

    it("includes the file verifier if it's part of the file's url", () => {
      RCEGlobals.getFeatures = jest.fn().mockReturnValue({
        file_verifiers_for_quiz_links: true,
      })
      const file = {
        id: '123',
        'content-type': 'video/mov',
        url: 'http://origin/path/to/file?verifier=xyzzy',
      }
      const url = mediaPlayerURLFromFile(file, 'https://mycanvas.com')
      expect(url).toBe('/media_attachments_iframe/123?type=video&embedded=true&verifier=xyzzy')
    })

    it('uses media_object route if no attachmentId exists', () => {
      const file = {
        media_entry_id: 'm-media_id',
        type: 'video/mov',
      }
      const url = mediaPlayerURLFromFile(file)
      expect(url).toBe('/media_objects_iframe/m-media_id?type=video')
    })
  })
})
