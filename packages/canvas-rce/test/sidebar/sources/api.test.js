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

describe('sources/api', () => {
  const endpoint = 'wikiPages'
  const props = {
    host: 'example.host',
    contextType: 'group',
    contextId: 123,
    sortBy: {sort: 'date_added', dir: 'desc'},
    searchString: ''
  }
  let apiSource
  let alertFuncSpy

  beforeEach(() => {
    alertFuncSpy = sinon.spy()
    apiSource = new RceApiSource({
      jwt: 'theJWT',
      refreshToken: callback => {
        callback('freshJWT')
      },
      alertFunc: alertFuncSpy
    })
    fetchMock.mock('/api/session', '{}')
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
      assert.strictEqual(
        collection.bookmark,
        `${window.location.protocol}//example.host/api/wikiPages?contextType=group&contextId=123`
      )
    })

    it('bookmark omits host if not in props', () => {
      const noHostProps = {...props, host: undefined}
      collection = apiSource.initializeCollection(endpoint, noHostProps)
      assert.strictEqual(collection.bookmark, '/api/wikiPages?contextType=group&contextId=123')
    })

    it('creates a collection that is not initially loading', () => {
      assert.strictEqual(collection.isLoading, false)
    })

    it('creates a collection that initially has more', () => {
      assert.strictEqual(collection.hasMore, true)
    })
  })

  describe('initializeImages', () => {
    it('sets hasMore to true', () => {
      assert.strictEqual(apiSource.initializeImages(props)[props.contextType].hasMore, true)
    })
  })

  describe('URI construction (baseUri)', () => {
    it('uses a protocol relative url when no window', () => {
      const uri = apiSource.baseUri('files', 'example.instructure.com', {})
      assert.strictEqual(uri, '//example.instructure.com/api/files')
    })

    it('uses a path for no-host url construction', () => {
      const uri = apiSource.baseUri('files')
      assert.strictEqual(uri, '/api/files')
    })

    it('gets protocol from window if available', () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = apiSource.baseUri('files', 'example.instructure.com', fakeWindow)
      assert.strictEqual(uri, 'https://example.instructure.com/api/files')
    })

    it('never applies protocol to path', () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = apiSource.baseUri('files', null, fakeWindow)
      assert.strictEqual(uri, '/api/files')
    })

    it("will replace protocol if there's a mismatch from http to https", () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = apiSource.normalizeUriProtocol('http://something.com', fakeWindow)
      assert.strictEqual(uri, 'https://something.com')
    })
  })

  describe('more URI construction (uriFor)', () => {
    let props = {}
    beforeEach(() => {
      props = {
        host: undefined,
        contextType: 'course',
        contextId: '17',
        sortBy: {sort: 'alphabetical', dir: 'asc'},
        searchString: 'hello world'
      }
    })

    it('gets documents', () => {
      const uri = apiSource.uriFor('documents', props)
      assert.strictEqual(
        uri,
        '/api/documents?contextType=course&contextId=17&exclude_content_types=image,video,audio&sort=name&order=asc&search_term=hello%20world'
      )
    })

    it('gets images', () => {
      const uri = apiSource.uriFor('images', props)
      assert.strictEqual(
        uri,
        '/api/documents?contextType=course&contextId=17&content_types=image&sort=name&order=asc&search_term=hello%20world'
      )
    })

    // this endpoint isn't actually used yet, but could be if media_objects all had associated Attachments
    it('gets media', () => {
      const uri = apiSource.uriFor('media', props)
      assert.strictEqual(
        uri,
        '/api/documents?contextType=course&contextId=17&content_types=video,audio&sort=name&order=asc&search_term=hello%20world'
      )
    })

    it('gets media_objects', () => {
      const uri = apiSource.uriFor('media_objects', props)
      assert.strictEqual(
        uri,
        '/api/media_objects?contextType=course&contextId=17&sort=title&order=asc&search_term=hello%20world'
      )
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
          assert.strictEqual(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
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
          assert.strictEqual(error.message, 'Forbidden')
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
          links: [
            {href: 'link1', title: 'Link 1'},
            {href: 'link2', title: 'Link 2'}
          ]
        })
      })
    })

    it('can parse while-wrapped page data', () => {
      const whileFakePageBody = 'while(1);' + fakePageBody
      const uri = 'theURI'
      fetchMock.mock(uri, whileFakePageBody)
      return apiSource.fetchPage(uri).then(page => {
        assert.deepEqual(page, {
          bookmark: 'newBookmark',
          links: [
            {href: 'link1', title: 'Link 1'},
            {href: 'link2', title: 'Link 2'}
          ]
        })
      })
    })

    it('retries once on 401 with a renewed token', () => {
      const uri = 'theURI'

      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer theJWT'
      }, 401)

      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer freshJWT'
      }, fakePageBody)

      return apiSource.fetchPage(uri, 'theJWT').then(page => {
        assert.strictEqual(page.bookmark, 'newBookmark')
        assert.strictEqual(apiSource.jwt, 'freshJWT')
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
        assert.strictEqual(body.bookmark, bookmark)
      })
    })

    it('converts file urls from download to preview', () => {
      return apiSource.fetchFiles('foo').then(body => {
        files.forEach((file, i) => {
          sinon.assert.calledWith(fileUrl.downloadToWrap, file.url)
          assert.strictEqual(body.files[i].href, wrapUrl)
        })
      })
    })
  })

  describe('fetchMediaFolder', () => {
    let files
    beforeEach(() => {
      files = [{id: 24}]
      const body = {files}
      sinon.stub(apiSource, 'fetchPage').returns(Promise.resolve(body))
    })

    afterEach(() => {
      apiSource.fetchPage.restore()
    })
    it('calls fetchPage with the proper params', () => {
      return apiSource
        .fetchMediaFolder({
          contextType: 'course',
          contextId: '22'
        })
        .then(() => {
          sinon.assert.calledWith(
            apiSource.fetchPage,
            '/api/folders/media?contextType=course&contextId=22'
          )
        })
    })
  })

  describe('preflightUpload', () => {
    const uri = '/api/upload'
    const fileProps = {}
    const apiProps = {}

    it('includes jwt in Authorization header', () => {
      fetchMock.mock(uri, '{}')

      return apiSource.preflightUpload(fileProps, apiProps).then(() => {
        assert.strictEqual(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
      })
    })

    it('retries once with fresh token on 401', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer theJWT'
      }, 401)

      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer freshJWT'
      }, '{"upload": "done"}')

      return apiSource.preflightUpload(fileProps, apiProps).then(response => {
        assert.strictEqual(response.upload, 'done')
      })
    })

    it('notifies a provided callback when a new token is fetched', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer theJWT'
      }, 401)

      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer freshJWT'
      }, '{"upload": "done"}')

      return apiSource.preflightUpload(fileProps, apiProps).then(() => {
        assert.strictEqual(apiSource.jwt, 'freshJWT')
      })
    })

    it('calls alertFunc when an error occurs', () => {
      fetchMock.mock(uri, 500)
      return apiSource
        .preflightUpload(fileProps, apiProps)
        .then(() => {
          sinon.assert.calledWith(alertFuncSpy, {
            text: 'Something went wrong uploading, check your connection and try again.',
            variant: 'error'
          })
        })
        .catch(() => {
          // This will re-throw so we just catch it here.
        })
    })

    it('throws an exception when an error occurs', () => {
      fetchMock.mock(uri, 500)
      return apiSource.preflightUpload(fileProps, apiProps).catch(e => {
        assert(e)
      })
    })
  })

  describe('uploadFRD', () => {
    let fileDomObject, uploadUrl, preflightProps, file, wrapUrl

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

    it('calls alertFunc if there is a problem', () => {
      fetchMock.once(uploadUrl, 500, {overwriteRoutes: true})
      return apiSource
        .uploadFRD(fileDomObject, preflightProps)
        .then(() => {
          sinon.assert.calledWith(alertFuncSpy, {
            text: 'Something went wrong uploading, check your connection and try again.',
            variant: 'error'
          })
        })
        .catch(() => {})
    })

    describe('files', () => {
      beforeEach(() => {
        wrapUrl = '/groups/123/path?wrap=1'
        sinon.stub(fileUrl, 'downloadToWrap').returns(wrapUrl)
        sinon.stub(fileUrl, 'fixupFileUrl').returns(wrapUrl)
        sinon.stub(apiSource, 'getFile').returns(Promise.resolve(file))
      })

      afterEach(() => {
        fileUrl.downloadToWrap.restore()
        fileUrl.fixupFileUrl.restore()
        apiSource.getFile.restore()
      })

      it('includes credentials in non-S3 upload', () => {
        preflightProps.upload_params.success_url = undefined
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          assert.strictEqual(fetchMock.lastOptions(uploadUrl).credentials, 'include')
        })
      })

      it('does not include credentials in S3 upload', () => {
        preflightProps.upload_params['x-amz-signature'] = 'success-url'
        preflightProps.upload_params.success_url = 'success-url'
        const s3File = {url: 's3-file-url'}
        fetchMock.mock(preflightProps.upload_params.success_url, s3File)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          assert.strictEqual(fetchMock.lastOptions(uploadUrl).credentials, undefined)
        })
      })

      it('handles s3 post-flight', async () => {
        preflightProps.upload_params.success_url = 'success-url'
        const s3File = {url: 's3-file-url'}
        fetchMock.mock(preflightProps.upload_params.success_url, s3File)
        const result = await apiSource.uploadFRD(fileDomObject, preflightProps)
        assert.deepEqual(result, s3File)
      })

      it('handles inst-fs post-flight', () => {
        preflightProps.upload_url = 'instfs-upload-url'
        const fileId = '123'
        const response = {
          location: `http://canvas/api/v1/files/${fileId}?foo=bar`,
          uuid: 'xyzzy'
        }
        fetchMock.mock(preflightProps.upload_url, response)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(response => {
          sinon.assert.calledWith(apiSource.getFile, fileId)
          assert.strictEqual(response.uuid, 'xyzzy')
          assert.strictEqual(response.url, 'file-url')
        })
      })
    })
  })

  describe('api mapping', () => {
    const body = {
      bookmark: 'mo.images',
      files: [{href: '/some/where', uuid: 'xyzzy'}]
    }
    props.images = {
      group: {
        isLoading: false,
        hasMore: true,
        bookmark: null,
        files: []
      }
    }

    it('can fetch folders', () => {
      fetchMock.mock(/\/folders\?/, {body})
      return apiSource.fetchRootFolder(props).then(page => {
        assert.deepEqual(page, body)
        fetchMock.restore()
      })
    })

    it('requests images from API', () => {
      fetchMock.mock(/\/documents\?.*content_types=image/, {body})
      return apiSource.fetchImages(props).then(page => {
        assert.deepStrictEqual(page, {
          bookmark: 'mo.images',
          files: [{href: '/some/where?wrap=1', uuid: 'xyzzy'}]
        })
        fetchMock.restore()
      })
    })

    it('requests subsequent page of images from API', () => {
      props.images.group.bookmark = 'mo.images'
      fetchMock.mock(/\/documents\?.*content_types=image/, 'should not get here')
      fetchMock.mock(/mo.images/, {body})
      return apiSource.fetchImages(props).then(page => {
        assert.deepEqual(page, {
          bookmark: 'mo.images',
          files: [{href: '/some/where?wrap=1', uuid: 'xyzzy'}]
        })
        fetchMock.restore()
      })
    })
  })

  describe('getSession', () => {
    const uri = '/api/session' // already mocked

    it('includes jwt in Authorization header', () => {
      return apiSource.getSession().then(() => {
        assert.strictEqual(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
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
        assert.strictEqual(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
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
    const props = {}

    it('includes jwt in Authorization header', () => {
      fetchMock.mock(uri, {url})

      return apiSource.getFile(id, props).then(() => {
        assert.strictEqual(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
      })
    })

    it('retries once with fresh token on 401', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer theJWT'
      }, 401)

      fetchMock.mock(
        (fetchUrl, opts) => {
          return uri === fetchUrl && opts.headers.Authorization === 'Bearer freshJWT'
        },
        {upload: 'done', url}
      )

      return apiSource.getFile(id, props).then(response => {
        assert.strictEqual(response.upload, 'done')
      })
    })

    it('notifies a provided callback when a new token is fetched', () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer theJWT'
      }, 401)

      fetchMock.mock(
        (fetchUrl, opts) => {
          return uri === fetchUrl && opts.headers.Authorization === 'Bearer freshJWT'
        },
        {upload: 'done', url}
      )

      return apiSource.getFile(id, props).then(() => {
        assert.strictEqual(apiSource.jwt, 'freshJWT')
      })
    })

    it('transforms file url with downloadToWrap', () => {
      const url = '/file/url?download_frd=1'
      const wrapUrl = '/file/url?wrap=1'
      fetchMock.mock('*', {url})
      sinon.stub(fileUrl, 'downloadToWrap').returns(wrapUrl)
      return apiSource.getFile(id).then(file => {
        sinon.assert.calledWith(fileUrl.downloadToWrap, url)
        assert.strictEqual(file.href, wrapUrl)
        fileUrl.downloadToWrap.restore()
        fetchMock.restore()
      })
    })

    it('defaults display_name to name', () => {
      const url = '/file/url?download_frd=1'
      const name = 'filename'
      fetchMock.mock('*', {url, name})
      sinon.stub(fileUrl, 'downloadToWrap')
      return apiSource.getFile(id).then(file => {
        assert.strictEqual(file.display_name, name)
        fileUrl.downloadToWrap.restore()
        fetchMock.restore()
      })
    })
  })

  describe('pingbackUnsplash', () => {
    it('sends the given id to the proper route', () => {
      const expectedUrl = '/api/unsplash/pingback?id=123'
      fetchMock.mock(expectedUrl, 200)
      return apiSource.pingbackUnsplash(123).then(() => {
        assert.ok(fetchMock.done())
        assert.ok(fetchMock.lastUrl() === expectedUrl)
        fetchMock.restore()
      })
    })
  })

  describe('media object apis', () => {
    describe('updateMediaObject', () => {
      it('PUTs to the media_object endpoint', async () => {
        const uri = `/api/media_objects/m-id?user_entered_title=${encodeURIComponent('new title')}`
        fetchMock.put(uri, '{"media_id": "m-id", "title": "new title"}')
        const response = await apiSource.updateMediaObject(
          {},
          {media_object_id: 'm-id', title: 'new title'}
        )
        assert.strictEqual(fetchMock.lastOptions(uri).headers.Authorization, 'Bearer theJWT')
        assert.deepEqual(response, {media_id: 'm-id', title: 'new title'})
      })
    })
  })
})
