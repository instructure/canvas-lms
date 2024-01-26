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

import {ok, strictEqual} from 'assert'
import {
  absoluteToRelativeUrl,
  downloadToWrap,
  fixupFileUrl,
  prepEmbedSrc,
  prepLinkedSrc,
} from '../../src/common/fileUrl'

describe('Common file url utils', () => {
  describe('absoluteToRelativeUrl', () => {
    const canvasOrigin = 'http://mycanvas.com:3000'

    it('turns an absolute URL into a relative URL', () => {
      const absoluteUrl = 'https://mycanvas.com:3000/some/path/download?download_frd=1#hash_thing'
      strictEqual(
        absoluteToRelativeUrl(absoluteUrl, canvasOrigin),
        '/some/path/download?download_frd=1#hash_thing'
      )
    })

    it('leaves a relative URL as is', () => {
      const relativeUrl = '/some/path/download?download_frd=1#hash_thing'
      strictEqual(
        absoluteToRelativeUrl(relativeUrl, canvasOrigin),
        '/some/path/download?download_frd=1#hash_thing'
      )
    })

    it('leaves non-Canvas absolute URLs as absolute', () => {
      const absoluteUrl = 'https://yodawg.com:3001/some/path/download?download_frd=1#hash_thing'
      strictEqual(
        absoluteToRelativeUrl(absoluteUrl, canvasOrigin),
        'https://yodawg.com:3001/some/path/download?download_frd=1#hash_thing'
      )
    })
  })

  describe('downloadToWrap', () => {
    let url

    beforeEach(() => {
      const downloadUrl = '/some/path/download?download_frd=1'
      url = downloadToWrap(downloadUrl)
    })

    it('removes download_frd from the query params', () => {
      ok(!/download_frd/.test(url))
    })

    it('adds wrap=1 to the query params', () => {
      ok(/wrap=1/.test(url))
    })

    it('returns null if url is null', () => {
      strictEqual(downloadToWrap(null), null)
    })

    it('returns undefined if url is undefined', () => {
      strictEqual(downloadToWrap(undefined), undefined)
    })

    it('returns empty string for empty strings', () => {
      strictEqual(downloadToWrap(''), '')
    })

    it('skips swizzling the url if from a different host', () => {
      const testurl = 'http://instructure.com/some/path'
      url = downloadToWrap(testurl)
      strictEqual(url, testurl)
    })

    it('strips "preview" too', () => {
      const testurl = '/some/path/preview'
      url = downloadToWrap(testurl)
      strictEqual(url, '/some/path?wrap=1')
    })
  })

  describe('fixupFileUrl', () => {
    let fileInfo

    describe('for files with an href', () => {
      beforeEach(() => {
        fileInfo = {
          href: '/files/17/download?download_frd=1',
          uuid: 'xyzzy',
        }
      })

      it('skips swizzling the url if from a different host', () => {
        fileInfo.href = 'http://instructure.com/some/path'
        const result = fixupFileUrl('course', 2, fileInfo)
        strictEqual(result.href, fileInfo.href)
      })

      it('transforms urls if from the specified canvas origin', () => {
        fileInfo.href = 'http://instructure.com/files/17/download?download_frd=1'
        const result = fixupFileUrl('course', 2, fileInfo, 'http://instructure.com')
        strictEqual(result.href, 'http://instructure.com/courses/2/files/17?wrap=1')
      })

      it('transforms course file urls', () => {
        // removes download_frd and adds wrap
        const result = fixupFileUrl('course', 2, fileInfo)
        strictEqual(result.href, '/courses/2/files/17?wrap=1')
      })

      it('adds the verifier to user files', () => {
        // while removing download_frd
        const result = fixupFileUrl('user', 2, fileInfo)
        strictEqual(result.href, '/users/2/files/17?wrap=1&verifier=xyzzy')
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
        strictEqual(result.url, fileInfo.url)
      })

      it('transforms course file urls', () => {
        // removes download_frd and adds wrap
        const result = fixupFileUrl('course', 2, fileInfo)
        strictEqual(result.url, '/courses/2/files/17?wrap=1')
      })

      it('adds the verifier to user files', () => {
        // while removing download_frd and does not add wrap
        const result = fixupFileUrl('user', 2, fileInfo)
        strictEqual(result.url, '/users/2/files/17?wrap=1&verifier=xyzzy')
      })
    })
  })

  describe('prepEmbedSrc', () => {
    it('skips transforming the url if from a different host', () => {
      const url = 'http://instructure.com/some/path'
      const result = prepEmbedSrc(url)
      strictEqual(result, url)
    })

    it('transforms the url if from the current canvas host', () => {
      const url = 'http://instructure.com/some/path'
      const result = prepEmbedSrc(url, 'http://instructure.com')
      strictEqual(result, 'http://instructure.com/some/path/preview')
    })

    it('replaces /download?some_params with /preview?some_params', () => {
      const url = '/users/2/files/17/download?verifier=xyzzy'
      strictEqual(prepEmbedSrc(url), '/users/2/files/17/preview?verifier=xyzzy')
    })

    it('replaces /download and no params with /preview ', () => {
      const url = '/users/2/files/17/download'
      strictEqual(prepEmbedSrc(url), '/users/2/files/17/preview')
    })

    it('does not mess with a /preview URL', () => {
      const url = '/users/2/files/17/preview'
      strictEqual(prepEmbedSrc(url), '/users/2/files/17/preview')
    })

    it('does not indiscriminately replace /preview in a url', () => {
      const url = '/please/preview/me'
      strictEqual(prepEmbedSrc(url), '/please/preview/me/preview')
    })
  })

  describe('prepLinkedSrc', () => {
    it('skips transforming the url if from a different host', () => {
      const url = 'http://instructure.com/some/path'
      const result = prepLinkedSrc(url)
      strictEqual(url, result)
    })

    it('removes /preview', () => {
      const url = '/users/2/files/17/preview?verifier=xyzzy'
      strictEqual(prepLinkedSrc(url), '/users/2/files/17?verifier=xyzzy')
    })

    it('does not indiscriminately replace /download in a url', () => {
      const url = '/please/download/me'
      strictEqual(prepLinkedSrc(url), url)
    })
  })
})
