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

import {
  absoluteToRelativeUrl,
  downloadToWrap,
  fixupFileUrl,
  prepEmbedSrc,
  prepLinkedSrc,
} from '../fileUrl'
import RCEGlobals from '../../rce/RCEGlobals'

describe('Common file url utils', () => {
  describe('absoluteToRelativeUrl', () => {
    const canvasOrigin = 'http://mycanvas.com:3000'

    it('turns an absolute URL into a relative URL', () => {
      const absoluteUrl = 'https://mycanvas.com:3000/some/path/download?download_frd=1#hash_thing'
      expect(absoluteToRelativeUrl(absoluteUrl, canvasOrigin)).toEqual(
        '/some/path/download?download_frd=1#hash_thing',
      )
    })

    it('leaves a relative URL as is', () => {
      const relativeUrl = '/some/path/download?download_frd=1#hash_thing'
      expect(absoluteToRelativeUrl(relativeUrl, canvasOrigin)).toEqual(
        '/some/path/download?download_frd=1#hash_thing',
      )
    })

    it('leaves non-Canvas absolute URLs as absolute', () => {
      const absoluteUrl = 'https://yodawg.com:3001/some/path/download?download_frd=1#hash_thing'
      expect(absoluteToRelativeUrl(absoluteUrl, canvasOrigin)).toEqual(
        'https://yodawg.com:3001/some/path/download?download_frd=1#hash_thing',
      )
    })

    it('returns original if no url given', () => {
      expect(absoluteToRelativeUrl('', canvasOrigin)).toEqual('')
      expect(absoluteToRelativeUrl(null, canvasOrigin)).toEqual(null)
      expect(absoluteToRelativeUrl(undefined, canvasOrigin)).toEqual(undefined)
    })

    it('returns original url if the protocol is mailto', () => {
      const mailtoUrl = 'mailto:admin@instructure.com'
      expect(absoluteToRelativeUrl(mailtoUrl, canvasOrigin)).toEqual(mailtoUrl)
    })

    it('returns original url if the protocol is tel', () => {
      const telUrl = 'tel:555-555-5555'
      expect(absoluteToRelativeUrl(telUrl, canvasOrigin)).toEqual(telUrl)
    })

    it('returns original url if the protocol is skype', () => {
      const skypeUrl = 'skype:instructure'
      expect(absoluteToRelativeUrl(skypeUrl, canvasOrigin)).toEqual(skypeUrl)
    })

    it('handles URLs with special characters in query params', () => {
      const absoluteUrl = 'https://mycanvas.com:3000/path?param=hello%20world#hash'
      expect(absoluteToRelativeUrl(absoluteUrl, canvasOrigin)).toEqual(
        '/path?param=hello%20world#hash',
      )
    })

    it('handles URLs with multiple query parameters', () => {
      const absoluteUrl = 'https://mycanvas.com:3000/path?a=1&b=2&c=3'
      expect(absoluteToRelativeUrl(absoluteUrl, canvasOrigin)).toEqual('/path?a=1&b=2&c=3')
    })
  })

  describe('downloadToWrap', () => {
    let url

    beforeEach(() => {
      const downloadUrl = '/some/path/download?download_frd=1'
      url = downloadToWrap(downloadUrl)
    })

    it('removes download_frd from the query params', () => {
      expect(/download_frd/.test(url)).toBeFalsy()
    })

    it('adds wrap=1 to the query params', () => {
      expect(/wrap=1/.test(url)).toBeTruthy()
    })

    it('returns null if url is null', () => {
      expect(downloadToWrap(null)).toBeNull()
    })

    it('returns undefined if url is undefined', () => {
      expect(downloadToWrap(undefined)).toBeUndefined()
    })

    it('returns empty string for empty strings', () => {
      expect(downloadToWrap('')).toEqual('')
    })

    it('skips swizzling the url if from a different host', () => {
      const testurl = 'http://instructure.com/some/path'
      url = downloadToWrap(testurl)
      expect(url).toEqual(testurl)
    })

    it('strips "preview" too', () => {
      const testurl = '/some/path/preview'
      url = downloadToWrap(testurl)
      expect(url).toEqual('/some/path?wrap=1')
    })

    it('preserves other query parameters', () => {
      const testurl = '/some/path/download?download_frd=1&foo=bar'
      url = downloadToWrap(testurl)
      expect(url).toEqual('/some/path?foo=bar&wrap=1')
    })

    it('adds wrap=1 if no query parameters present', () => {
      const testurl = '/some/path/download'
      url = downloadToWrap(testurl)
      expect(url).toEqual('/some/path?wrap=1')
    })

    it('preserves hash fragments in URLs', () => {
      const testurl = '/path/download?download_frd=1#section'
      url = downloadToWrap(testurl)
      expect(url).toEqual('/path?wrap=1#section')
    })
  })

  describe('fixupFileUrl', () => {
    let fileInfo

    describe('for files with an href', () => {
      beforeEach(() => {
        fileInfo = {
          href: '/files/17/download?download_frd=1&verifier=u17',
          uuid: 'xyzzy',
        }
        RCEGlobals.getFeatures = jest.fn().mockReturnValue({file_verifiers_for_quiz_links: true})
      })

      afterEach(() => {
        RCEGlobals.getFeatures.mockRestore()
      })

      it('skips swizzling the url if from a different host', () => {
        fileInfo.href = 'http://instructure.com/some/path'
        const result = fixupFileUrl('course', 2, fileInfo)
        expect(result.href).toEqual(fileInfo.href)
      })

      it('does not add file verifiers to Canvas file URLs if the origin is not Canvas and the feature flag is off', () => {
        RCEGlobals.getFeatures = jest.fn().mockReturnValue({file_verifiers_for_quiz_links: false})
        fileInfo.href = 'http://instructure.com/files/17/download?download_frd=1'
        const result = fixupFileUrl('course', 2, fileInfo, 'http://instructure.com')
        expect(result.href).toEqual('http://instructure.com/courses/2/files/17?wrap=1')
      })

      it('adds file verifiers to all Canvas file URLs if the origin is not Canvas and the feature flag is on', () => {
        fileInfo.href = 'http://instructure.com/files/17/download?download_frd=1'
        const result = fixupFileUrl('course', 2, fileInfo, 'http://instructure.com')
        expect(result.href).toEqual(
          'http://instructure.com/courses/2/files/17?wrap=1&verifier=xyzzy',
        )
      })

      it('transforms course file urls', () => {
        // removes download_frd and adds wrap
        const result = fixupFileUrl('course', 2, fileInfo)
        expect(result.href).toEqual('/courses/2/files/17?wrap=1')
      })

      it('adds the verifier to user files', () => {
        // while removing download_frd
        const result = fixupFileUrl('user', 2, fileInfo)
        expect(result.href).toEqual('/users/2/files/17?verifier=xyzzy&wrap=1')
      })

      it('does nothing if there is no href/url property', () => {
        const emptyInfo = {}
        const result = fixupFileUrl('course', 2, emptyInfo)
        expect(result).toEqual(emptyInfo)
      })

      it('preserves hash fragments in course file urls', () => {
        fileInfo.href = '/files/17/download?download_frd=1#section'
        const result = fixupFileUrl('course', 2, fileInfo)
        expect(result.href).toEqual('/courses/2/files/17?wrap=1#section')
      })

      it('handles file paths with special characters', () => {
        fileInfo.href = '/files/17/my%20file.pdf/download?download_frd=1'
        const result = fixupFileUrl('course', 2, fileInfo)
        expect(result.href).toEqual('/courses/2/files/17/my%20file.pdf?wrap=1')
      })
    })

    describe('for files with a url', () => {
      beforeEach(() => {
        fileInfo = {
          url: '/files/17/download?download_frd=1',
          uuid: 'xyzzy',
        }
      })

      it('skips transforming the url if from a different host', () => {
        fileInfo.url = 'http://instructure.com/some/path'
        const result = fixupFileUrl('course', 2, fileInfo)
        expect(result.url).toEqual(fileInfo.url)
      })

      it('transforms course file urls', () => {
        // removes download_frd and adds wrap
        const result = fixupFileUrl('course', 2, fileInfo)
        expect(result.url).toEqual('/courses/2/files/17?wrap=1')
      })

      it('adds the verifier to user files', () => {
        // while removing download_frd and does not add wrap
        const result = fixupFileUrl('user', 2, fileInfo)
        expect(result.url).toEqual('/users/2/files/17?wrap=1&verifier=xyzzy')
      })

      it('removes download_frd but preserves other query params', () => {
        fileInfo.url = '/files/17/download?download_frd=1&foo=bar'
        const result = fixupFileUrl('course', 2, fileInfo)
        expect(result.url).toEqual('/courses/2/files/17?foo=bar&wrap=1')
      })
    })
  })

  describe('prepEmbedSrc', () => {
    it('skips transforming the url if from a different host', () => {
      const url = 'http://instructure.com/some/path'
      const result = prepEmbedSrc(url)
      expect(result).toEqual(url)
    })

    it('transforms the url if from the current canvas host', () => {
      const url = 'http://instructure.com/some/path'
      const result = prepEmbedSrc(url, 'http://instructure.com')
      expect(result).toEqual('http://instructure.com/some/path/preview')
    })

    it('replaces /download?some_params with /preview?some_params', () => {
      const url = '/users/2/files/17/download?verifier=xyzzy'
      expect(prepEmbedSrc(url)).toEqual('/users/2/files/17/preview?verifier=xyzzy')
    })

    it('replaces /download and no params with /preview ', () => {
      const url = '/users/2/files/17/download'
      expect(prepEmbedSrc(url)).toEqual('/users/2/files/17/preview')
    })

    it('does not mess with a /preview URL', () => {
      const url = '/users/2/files/17/preview'
      expect(prepEmbedSrc(url)).toEqual('/users/2/files/17/preview')
    })

    it('does not indiscriminately replace /preview in a url', () => {
      const url = '/please/preview/me'
      expect(prepEmbedSrc(url)).toEqual('/please/preview/me/preview')
    })

    it('adds /preview if the URL ends with the file id but no download or preview', () => {
      const url = '/users/2/files/17'
      expect(prepEmbedSrc(url)).toEqual('/users/2/files/17/preview')
    })

    it('removes wrap=1 if present', () => {
      const url = '/users/2/files/17/download?wrap=1&foo=bar'
      expect(prepEmbedSrc(url)).toEqual('/users/2/files/17/preview?foo=bar')
    })

    it('handles URLs with special characters in path', () => {
      const url = '/users/2/files/17/my%20document.pdf/preview'
      expect(prepEmbedSrc(url)).toEqual('/users/2/files/17/my%20document.pdf/preview')
    })

    it('handles multiple query parameters correctly', () => {
      const url = '/users/2/files/17/download?param1=value1&param2=value2&wrap=1'
      expect(prepEmbedSrc(url)).toEqual('/users/2/files/17/preview?param1=value1&param2=value2')
    })
  })

  describe('prepLinkedSrc', () => {
    it('skips transforming the url if from a different host', () => {
      const url = 'http://instructure.com/some/path'
      const result = prepLinkedSrc(url)
      expect(url).toEqual(result)
    })

    it('removes /preview', () => {
      const url = '/users/2/files/17/preview?verifier=xyzzy'
      expect(prepLinkedSrc(url)).toEqual('/users/2/files/17?verifier=xyzzy')
    })

    it('does not indiscriminately replace /download in a url', () => {
      const url = '/please/download/me'
      expect(prepLinkedSrc(url)).toEqual(url)
    })

    it('preserves query parameters and hash after removing /preview', () => {
      const url = '/users/2/files/17/preview?foo=bar#section'
      expect(prepLinkedSrc(url)).toEqual('/users/2/files/17?foo=bar#section')
    })

    it('handles URLs with encoded characters', () => {
      const url = '/users/2/files/17/preview?name=test%20file.pdf'
      expect(prepLinkedSrc(url)).toEqual('/users/2/files/17?name=test%20file.pdf')
    })

    it('handles empty query parameters', () => {
      const url = '/users/2/files/17/preview?'
      expect(prepLinkedSrc(url)).toEqual('/users/2/files/17')
    })
  })
})
