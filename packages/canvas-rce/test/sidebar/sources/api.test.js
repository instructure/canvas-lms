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
import sinon from 'sinon'
import RceApiSource from '../../../src/sidebar/sources/api'
import fetchMock from 'fetch-mock'
import * as fileUrl from '../../../src/common/fileUrl'
import jsdom from 'mocha-jsdom'

describe('sources/api', () => {
  const endpoint = 'wikiPages'
  const props = {
    host: 'example.host',
    contextType: 'group',
    contextId: 123
  }
  let apiSource

  beforeEach(() => {
    apiSource = new RceApiSource({
      jwt: 'theJWT',
      refreshToken: callback => {
        callback('freshJWT')
      }
    })
  })

  afterEach(() => {
    fetchMock.restore()
  })

  describe('initializeCollection', () => {
    let collection
    beforeEach(() => {
      collection = apiSource.initializeCollection(endpoint, props)
    })

    it('creates a collection with no links', () => {
      assert.deepEqual(collection.links, [])
    })

    it('creates a collection with a bookmark derived from props', () => {
      assert.equal(
        collection.bookmark,
        '//example.host/api/wikiPages?contextType=group&contextId=123'
      )
    })

    it('bookmark omits host if not in props', () => {
      let noHostProps = Object.assign({}, props, {host: undefined})
      collection = apiSource.initializeCollection(endpoint, noHostProps)
      assert.equal(collection.bookmark, '/api/wikiPages?contextType=group&contextId=123')
    })

    it('creates a collection that is not initially loading', () => {
      assert.equal(collection.loading, false)
    })
  })

  describe('initializeImages', () => {
    it('sets requested to false', () => {
      assert.equal(apiSource.initializeImages().requested, false)
    })
  })

  describe('URI construction', () => {
    it('uses a protocol relative url when no window', () => {
      let uri = apiSource.baseUri('files', 'example.instructure.com')
      assert.equal(uri, '//example.instructure.com/api/files')
    })

    it('uses a path for no-host url construction', () => {
      let uri = apiSource.baseUri('files')
      assert.equal(uri, '/api/files')
    })

    it('gets protocol from window if available', () => {
      let fakeWindow = {location: {protocol: 'https:'}}
      let uri = apiSource.baseUri('files', 'example.instructure.com', fakeWindow)
      assert.equal(uri, 'https://example.instructure.com/api/files')
    })

    it('never applies protocol to path', () => {
      let fakeWindow = {location: {protocol: 'https:'}}
      let uri = apiSource.baseUri('files', null, fakeWindow)
      assert.equal(uri, '/api/files')
    })

    it("will replace protocol if there's a mismatch from http to https", () => {
      let fakeWindow = {location: {protocol: 'https:'}}
      let uri = apiSource.normalizeUriProtocol('http://something.com', fakeWindow)
      assert.equal(uri, 'https://something.com')
    })
  })

  describe('fetchPage', () => {
    const fakePageBody =
      '{"bookmark":"newBookmark","links":[' +
      '{"href":"link1","title":"Link 1"},' +
      '{"href":"link2","title":"Link 2"}]}'

    it('includes jwt in Authorization header', done => {
      const uri = 'theURI'
      fetchMock.mock(uri, '{}')
      apiSource
        .fetchPage(uri)
        .then(() => {
          assert.equal(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
          done()
        })
        .catch(done)
    })

    it('converts 400+ statuses to errors', done => {
      const uri = 'theURI'
      fetchMock.mock(uri, 403)
      apiSource
        .fetchPage(uri)
        .then(() => {
          throw new Error('No error raised')
        })
        .catch(error => {
          assert.equal(error.message, 'Forbidden')
          done()
        })
        .catch(done)
    })

    it('parses server response before handing it back', () => {
      const uri = 'theURI'
      fetchMock.mock(uri, fakePageBody)
      return apiSource.fetchPage(uri).then(page => {
        assert.deepEqual(page, {
          bookmark: 'newBookmark',
          links: [{href: 'link1', title: 'Link 1'}, {href: 'link2', title: 'Link 2'}]
        })
      })
    })

    it('can parse while-wrapped page data', () => {
      let whileFakePageBody = 'while(1);' + fakePageBody
      const uri = 'theURI'
      fetchMock.mock(uri, whileFakePageBody)
      return apiSource.fetchPage(uri).then(page => {
        assert.deepEqual(page, {
          bookmark: 'newBookmark',
          links: [{href: 'link1', title: 'Link 1'}, {href: 'link2', title: 'Link 2'}]
        })
      })
    })

    it('retries once on 401 with a renewed token', () => {
      const uri = 'theURI'

      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer theJWT'
      }, 401)

      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer freshJWT'
      }, fakePageBody)

      return apiSource.fetchPage(uri, 'theJWT').then(page => {
        assert.equal(page.bookmark, 'newBookmark')
        assert.equal(apiSource.jwt, 'freshJWT')
      })
    })
  })

  describe('fetchFiles', () => {
    let bookmark, files, wrapUrl

    beforeEach(() => {
      bookmark = 'some-bookmark'
      files = [{url: '/url1'}, {url: '/url2'}]
      wrapUrl = '/path?preview=1'
      const body = {bookmark, files}
      sinon.stub(apiSource, 'fetchPage').returns(Promise.resolve(body))
      sinon.stub(fileUrl, 'downloadToWrap').returns(wrapUrl)
    })

    afterEach(() => {
      apiSource.fetchPage.restore()
      fileUrl.downloadToWrap.restore()
    })

    it('proxies the call to fetchPage', () => {
      const uri = 'files-uri'
      return apiSource.fetchFiles(uri).then(body => {
        sinon.assert.calledWith(apiSource.fetchPage, uri)
        assert.equal(body.bookmark, bookmark)
      })
    })

    it('converts file urls from download to preview', () => {
      return apiSource.fetchFiles('foo').then(body => {
        files.forEach((file, i) => {
          sinon.assert.calledWith(fileUrl.downloadToWrap, file.url)
          assert.equal(body.files[i].url, wrapUrl)
        })
      })
    })
  })

  describe('preflightUpload', () => {
    const uri = '/api/upload'
    let fileProps = {}
    let apiProps = {}

    it('includes jwt in Authorization header', () => {
      fetchMock.mock(uri, '{}')

      return apiSource.preflightUpload(fileProps, apiProps).then(() => {
        assert.equal(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
      })
    })

    it('retries once with fresh token on 401', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer theJWT'
      }, 401)

      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer freshJWT'
      }, '{"upload": "done"}')

      return apiSource.preflightUpload(fileProps, apiProps).then(response => {
        assert.equal(response.upload, 'done')
      })
    })

    it('notifies a provided callback when a new token is fetched', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer theJWT'
      }, 401)

      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer freshJWT'
      }, '{"upload": "done"}')

      return apiSource.preflightUpload(fileProps, apiProps).then(() => {
        assert.equal(apiSource.jwt, 'freshJWT')
      })
    })
  })

  describe('uploadFRD', () => {
    let fileDomObject, uploadUrl, preflightProps, file, wrapUrl
    jsdom()

    beforeEach(() => {
      fileDomObject = new window.Blob()
      uploadUrl = 'upload-url'
      preflightProps = {
        upload_params: {},
        upload_url: uploadUrl
      }
      file = {url: 'file-url'}
      fetchMock.mock(uploadUrl, file)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    describe('files', () => {
      beforeEach(() => {
        wrapUrl = '/path?wrap=1'
        sinon.stub(fileUrl, 'downloadToWrap').returns(wrapUrl)
        sinon.stub(apiSource, 'getFile').returns(Promise.resolve(file))
      })

      afterEach(() => {
        fileUrl.downloadToWrap.restore()
        apiSource.getFile.restore()
      })

      it('includes credentials in non-S3 upload', () => {
        preflightProps.upload_params.success_url = undefined
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          assert.equal(fetchMock.lastOptions(uploadUrl).credentials, 'include')
        })
      })

      it('does not include credentials in S3 upload', () => {
        preflightProps.upload_params['x-amz-signature'] = 'success-url'
        preflightProps.upload_params.success_url = 'success-url'
        const s3File = {url: 's3-file-url'}
        fetchMock.mock(preflightProps.upload_params.success_url, s3File)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          assert.equal(fetchMock.lastOptions(uploadUrl).credentials, undefined)
        })
      })

      it('converts returned file url from download to wrap', () => {
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(body => {
          sinon.assert.calledWith(fileUrl.downloadToWrap, file.url)
          assert.equal(body.url, wrapUrl)
        })
      })

      it('handles s3 post-flight', () => {
        preflightProps.upload_params.success_url = 'success-url'
        const s3File = {url: 's3-file-url'}
        fetchMock.mock(preflightProps.upload_params.success_url, s3File)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          sinon.assert.calledWith(fileUrl.downloadToWrap, s3File.url)
        })
      })

      it('handles inst-fs post-flight', () => {
        preflightProps.upload_url = 'instfs-upload-url'
        const fileId = '123'
        const response = {
          location: `http://canvas/api/v1/files/${fileId}?foo=bar`
        }
        fetchMock.mock(preflightProps.upload_url, response)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          sinon.assert.calledWith(fileUrl.downloadToWrap, file.url)
          sinon.assert.calledWith(apiSource.getFile, fileId)
        })
      })
    })

    describe('images', () => {
      let tabContext

      beforeEach(() => {
        tabContext = 'images'
        wrapUrl = '/path?wrap=1'
        sinon.stub(fileUrl, 'downloadToWrap').returns(wrapUrl)
      })

      afterEach(() => {
        fileUrl.downloadToWrap.restore()
      })

      it('converts returned image url from download to wrap', () => {
        return apiSource.uploadFRD(fileDomObject, preflightProps, tabContext).then(body => {
          sinon.assert.calledWith(fileUrl.downloadToWrap, file.url)
          assert.equal(body.url, wrapUrl)
        })
      })
    })
  })

  describe('api mapping', () => {
    const body = {foo: 'bar'}

    it('can fetch folders', () => {
      fetchMock.mock(/\/folders\?/, {body})
      return apiSource.fetchRootFolder(props).then(page => {
        assert.deepEqual(page, body)
        fetchMock.restore()
      })
    })

    it('requests images from API', () => {
      fetchMock.mock(/\/images\?/, {body})
      return apiSource.fetchImages(props).then(page => {
        assert.deepEqual(page, body)
        fetchMock.restore()
      })
    })
  })

  describe('getSession', () => {
    const uri = '/api/session'

    beforeEach(() => {
      fetchMock.mock(uri, '{}')
    })

    it('includes jwt in Authorization header', () => {
      return apiSource.getSession().then(() => {
        assert.equal(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
      })
    })
  })

  describe('setUsageRights', () => {
    const uri = '/api/usage_rights'
    const fileId = 47
    const usageRights = {usageRight: 'foo'}

    beforeEach(() => {
      fetchMock.mock(uri, '{}')
    })

    it('includes jwt in Authorization header', () => {
      return apiSource.setUsageRights(fileId, usageRights).then(() => {
        assert.equal(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
      })
    })

    it('posts file id and usage rights to the api', () => {
      return apiSource.setUsageRights(fileId, usageRights).then(() => {
        const postBody = JSON.parse(fetchMock.lastOptions(uri).body)
        assert.deepEqual(postBody, {
          fileId,
          usageRight: usageRights.usageRight
        })
      })
    })
  })

  describe('getFile', () => {
    const id = 47
    const uri = `/api/file/${id}`
    const url = '/file/url'
    let props = {}

    it('includes jwt in Authorization header', () => {
      fetchMock.mock(uri, {url})

      return apiSource.getFile(id, props).then(() => {
        assert.equal(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
      })
    })

    it('retries once with fresh token on 401', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer theJWT'
      }, 401)

      fetchMock.mock(
        (fetchUrl, opts) => {
          return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer freshJWT'
        },
        {upload: 'done', url}
      )

      return apiSource.getFile(id, props).then(response => {
        assert.equal(response.upload, 'done')
      })
    })

    it('notifies a provided callback when a new token is fetched', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer theJWT'
      }, 401)

      fetchMock.mock(
        (fetchUrl, opts) => {
          return uri == fetchUrl && opts.headers['Authorization'] == 'Bearer freshJWT'
        },
        {upload: 'done', url}
      )

      return apiSource.getFile(id, props).then(() => {
        assert.equal(apiSource.jwt, 'freshJWT')
      })
    })

    it('transforms file url with downloadToWrap', () => {
      const url = '/file/url?download_frd=1'
      const wrapUrl = '/file/url?wrap=1'
      fetchMock.mock('*', {url})
      sinon.stub(fileUrl, 'downloadToWrap').returns(wrapUrl)
      return apiSource.getFile(id).then(file => {
        sinon.assert.calledWith(fileUrl.downloadToWrap, url)
        assert.equal(file.url, wrapUrl)
        fileUrl.downloadToWrap.restore()
        fetchMock.restore()
      })
    })

    it("defaults display_name to name", () => {
      const url = "/file/url?download_frd=1"
      const name = "filename"
      fetchMock.mock("*", {url, name})
      sinon.stub(fileUrl, "downloadToWrap")
      return apiSource.getFile(id).then(file => {
        assert.equal(file.display_name, name)
        fileUrl.downloadToWrap.restore()
        fetchMock.restore()
      })
    })
  })
})
