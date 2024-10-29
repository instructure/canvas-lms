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

import RceApiSource, {headerFor, originFromHost} from '../../src/rcs/api'
import fetchMock from 'fetch-mock'
import * as fileUrl from '../../src/common/fileUrl'
import {ICON_MAKER_ICONS} from '../../src/rce/plugins/instructure_icon_maker/svg/constants'

describe('sources/api', () => {
  const endpoint = 'wikiPages'
  const props = {
    host: 'example.host',
    contextType: 'group',
    contextId: 123,
    sortBy: {sort: 'date_added', dir: 'desc'},
    searchString: '',
  }
  let setProps = {}
  let apiSource
  let alertFuncSpy

  beforeEach(() => {
    alertFuncSpy = jest.fn()
    apiSource = new RceApiSource({
      jwt: 'theJWT',
      refreshToken: callback => {
        callback('freshJWT')
      },
      alertFunc: alertFuncSpy,
    })
    fetchMock.mock('/api/session', '{}')
  })

  afterEach(() => {
    fetchMock.restore()
    jest.resetAllMocks()
  })

  describe('initializeCollection', () => {
    let collection
    beforeEach(() => {
      collection = apiSource.initializeCollection(endpoint, props)
    })

    it('creates a collection with no links', () => {
      expect(collection.links).toEqual([])
    })

    it('creates a collection with a bookmark derived from props', () => {
      expect(collection.bookmark).toEqual(
        `${window.location.protocol}//example.host/api/wikiPages?contextType=group&contextId=123&search_term=panda`
      )
    })

    it('bookmark omits host if not in props', () => {
      const noHostProps = {...props, host: undefined}
      collection = apiSource.initializeCollection(endpoint, noHostProps)
      expect(collection.bookmark).toEqual(
        '/api/wikiPages?contextType=group&contextId=123&search_term=panda'
      )
    })

    it('creates a collection that is not initially loading', () => {
      expect(collection.isLoading).toEqual(false)
    })

    it('creates a collection that initially has more', () => {
      expect(collection.hasMore).toEqual(true)
    })
  })

  describe('initializeImages', () => {
    it('sets hasMore to true', () => {
      expect(apiSource.initializeImages(props)[props.contextType].hasMore).toEqual(true)
    })

    it('sets searchString to an empty string', () => {
      expect(apiSource.initializeImages(props).searchString).toEqual('')
    })
  })

  describe('URI construction (baseUri)', () => {
    it('uses a protocol relative url when no window', () => {
      const uri = apiSource.baseUri('files', 'example.instructure.com', {})
      expect(uri).toEqual('//example.instructure.com/api/files')
    })

    it('uses a path for no-host url construction', () => {
      const uri = apiSource.baseUri('files')
      expect(uri).toEqual('/api/files')
    })

    it('gets protocol from window if available', () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = apiSource.baseUri('files', 'example.instructure.com', fakeWindow)
      expect(uri).toEqual('https://example.instructure.com/api/files')
    })

    it('never applies protocol to path', () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = apiSource.baseUri('files', null, fakeWindow)
      expect(uri).toEqual('/api/files')
    })

    it("will replace protocol if there's a mismatch from http to https", () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = apiSource.normalizeUriProtocol('http://something.com', fakeWindow)
      expect(uri).toEqual('https://something.com')
    })
  })

  describe('more URI construction (uriFor)', () => {
    beforeEach(() => {
      setProps = {
        host: undefined,
        contextType: 'course',
        contextId: '17',
        sortBy: {sort: 'alphabetical', dir: 'asc'},
        searchString: 'hello world',
      }
    })

    it('gets documents', () => {
      const uri = apiSource.uriFor('documents', setProps)
      expect(uri).toEqual(
        '/api/documents?contextType=course&contextId=17&exclude_content_types=image,video,audio&sort=name&order=asc&search_term=hello%20world'
      )
    })

    it('gets images', () => {
      const uri = apiSource.uriFor('images', setProps)
      expect(uri).toEqual(
        '/api/documents?contextType=course&contextId=17&content_types=image&sort=name&order=asc&search_term=hello%20world'
      )
    })

    // this endpoint isn't actually used yet, but could be if media_objects all had associated Attachments
    it('gets media', () => {
      const uri = apiSource.uriFor('media', setProps)
      expect(uri).toEqual(
        '/api/documents?contextType=course&contextId=17&content_types=video,audio&sort=name&order=asc&search_term=hello%20world'
      )
    })

    it('gets media_objects', () => {
      const uri = apiSource.uriFor('media_objects', setProps)
      expect(uri).toEqual(
        '/api/media_objects?contextType=course&contextId=17&sort=title&order=asc&search_term=hello%20world'
      )
    })
  })

  describe('fetchPage', () => {
    const uri = 'theURI'
    const fakePageBody =
      '{"bookmark":"newBookmark","links":[' +
      '{"href":"link1","title":"Link 1"},' +
      '{"href":"link2","title":"Link 2"}]}'

    it('includes jwt in Authorization header', async () => {
      fetchMock.mock(uri, '{}')
      await apiSource.fetchPage(uri)
      expect(fetchMock.lastOptions(uri).headers.Authorization).toEqual('Bearer theJWT')
    })

    it('converts 400+ statuses to errors', async () => {
      fetchMock.mock(uri, 403)
      await expect(apiSource.fetchPage(uri)).rejects.toThrow('Forbidden')
    })

    it('parses server response before handing it back', async () => {
      fetchMock.mock(uri, fakePageBody)
      const page = await apiSource.fetchPage(uri)
      expect(page).toEqual({
        bookmark: 'newBookmark',
        links: [
          {href: 'link1', title: 'Link 1'},
          {href: 'link2', title: 'Link 2'},
        ],
      })
    })

    it('retries once on 401 with a renewed token', async () => {
      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer theJWT'
      }, 401)

      fetchMock.mock((fetchUrl, opts) => {
        return uri === fetchUrl && opts.headers.Authorization === 'Bearer freshJWT'
      }, fakePageBody)

      const page = await apiSource.fetchPage(uri, 'theJWT')
      expect(page.bookmark).toEqual('newBookmark')
      expect(apiSource.jwt).toEqual('freshJWT')
    })
  })

  describe('fetchFiles', () => {
    let bookmark, files, wrapUrl

    beforeEach(() => {
      bookmark = 'some-bookmark'
      files = [{url: '/url1'}, {url: '/url2'}]
      wrapUrl = '/path?preview=1'
      const body = {bookmark, files}
      jest.spyOn(apiSource, 'fetchPage').mockReturnValue(Promise.resolve(body))
      jest.spyOn(fileUrl, 'downloadToWrap').mockReturnValue(wrapUrl)
    })

    it('proxies the call to fetchPage', async () => {
      const uri = 'files-uri'
      const body = await apiSource.fetchFiles(uri)
      expect(apiSource.fetchPage).toHaveBeenCalledWith(uri)
      expect(body.bookmark).toEqual(bookmark)
    })

    it('converts file urls from download to preview', async () => {
      const body = await apiSource.fetchFiles('foo')
      files.forEach((file, i) => {
        expect(fileUrl.downloadToWrap).toHaveBeenCalledWith(file.url)
        expect(body.files[i].href).toEqual(wrapUrl)
      })
    })
  })

  describe('fetchSubFolders()', () => {
    let bookmark

    beforeEach(() => {
      setProps = {host: 'canvas.rce', folderId: 2}
      bookmark = undefined
      jest.spyOn(apiSource, 'apiFetch').mockReturnValue(Promise.resolve({}))
    })

    it('makes a request to the folders api with the given host and ID', () => {
      apiSource.fetchSubFolders(setProps, bookmark)
      expect(apiSource.apiFetch).toHaveBeenCalledWith(
        `${window.location.protocol}//canvas.rce/api/folders/2`,
        {
          Authorization: 'Bearer theJWT',
        }
      )
    })

    describe('fetchFilesForFolder()', () => {
      beforeEach(() => {
        setProps = {host: 'canvas.rce', filesUrl: 'https://canvas.rce/api/files/2'}
        bookmark = undefined
      })

      it('makes a request to the files api with given host and folder ID', () => {
        apiSource.fetchFilesForFolder(setProps, bookmark)
        expect(apiSource.apiFetch).toHaveBeenCalledWith('https://canvas.rce/api/files/2', {
          Authorization: 'Bearer theJWT',
        })
      })

      describe('with perPage set', () => {
        beforeEach(() => {
          setProps.perPage = 50
        })

        it('includes the "per_page" query param', () => {
          apiSource.fetchFilesForFolder(setProps, bookmark)
          expect(apiSource.apiFetch).toHaveBeenCalledWith(
            'https://canvas.rce/api/files/2?per_page=50',
            {
              Authorization: 'Bearer theJWT',
            }
          )
        })
      })
    })

    describe('with a provided bookmark', () => {
      beforeEach(() => (bookmark = 'https://canvas.rce/api/folders/2?page=2'))

      it('makes a request to the bookmark', () => {
        apiSource.fetchSubFolders(props, bookmark)
        expect(apiSource.apiFetch).toHaveBeenCalledWith(bookmark, {
          Authorization: 'Bearer theJWT',
        })
      })
    })
  })

  describe('fetchBookmarkedData', () => {
    let fetchFunction, properties, onSuccess, onError

    beforeEach(() => {
      fetchFunction = jest
        .fn()
        .mockReturnValueOnce(Promise.resolve({bookmark: 'https://canvas.rce/api/thing/1?page=2'}))
        .mockReturnValueOnce(Promise.resolve({data: 'foo'}))
      properties = {foo: 'bar'}
      onSuccess = jest.fn()
      onError = jest.fn()
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    const subject = () =>
      apiSource.fetchBookmarkedData(fetchFunction, properties, onSuccess, onError)

    it('calls the "fetchFunction", passing "properties"', async () => {
      await subject()
      expect(fetchFunction).toHaveBeenCalledWith(properties, undefined)
      expect(fetchFunction).toHaveBeenCalledWith(
        properties,
        'https://canvas.rce/api/thing/1?page=2'
      )
      expect(fetchFunction).toHaveBeenCalledTimes(2)
    })

    it('calls "onSuccess" for each page', async () => {
      await subject()
      expect(onSuccess).toHaveBeenCalledTimes(2)
    })

    describe('when "fetchFunction" throws an exception', () => {
      beforeEach(() => {
        jest.resetAllMocks()
        fetchFunction.mockRejectedValue('error')
      })

      it('calls "onError"', () => {
        return subject().then(() => {
          expect(onError).toHaveBeenCalledTimes(1)
        })
      })
    })
  })

  describe('fetchIconMakerFolder', () => {
    let folders

    beforeEach(() => {
      folders = [{id: 24}]
      const body = {folders}
      jest.spyOn(apiSource, 'fetchPage').mockReturnValue(Promise.resolve(body))
    })

    it('calls fetchPage with the proper params', () => {
      return apiSource
        .fetchIconMakerFolder({
          contextType: 'course',
          contextId: '22',
        })
        .then(() => {
          expect(apiSource.fetchPage).toHaveBeenCalledWith(
            '/api/folders/icon_maker?contextType=course&contextId=22'
          )
        })
    })
  })

  describe('fetchMediaFolder', () => {
    let files
    beforeEach(() => {
      files = [{id: 24}]
      const body = {files}
      jest.spyOn(apiSource, 'fetchPage').mockReturnValue(Promise.resolve(body))
    })

    it('calls fetchPage with the proper params', () => {
      return apiSource
        .fetchMediaFolder({
          contextType: 'course',
          contextId: '22',
        })
        .then(() => {
          expect(apiSource.fetchPage).toHaveBeenCalledWith(
            '/api/folders/media?contextType=course&contextId=22'
          )
        })
    })
  })

  describe('preflightUpload', () => {
    const uri = '/api/upload'
    const fileProps = {}
    const apiProps = {}

    afterEach(() => {
      fetchMock.restore()
    })

    it('includes "onDuplicate"', () => {
      fetchMock.mock(uri, '{}')

      return apiSource.preflightUpload(fileProps, {onDuplicate: 'overwrite'}, apiProps).then(() => {
        const body = JSON.parse(fetchMock.lastOptions(uri).body)
        expect(body.onDuplicate).toEqual('overwrite')
      })
    })

    it('includes "category"', () => {
      fetchMock.mock(uri, '{}')

      return apiSource
        .preflightUpload(fileProps, {category: ICON_MAKER_ICONS}, apiProps)
        .then(() => {
          const body = JSON.parse(fetchMock.lastOptions(uri).body)
          expect(body.category).toEqual(ICON_MAKER_ICONS)
        })
    })

    it('includes jwt in Authorization header', () => {
      fetchMock.mock(uri, '{}')

      return apiSource.preflightUpload(fileProps, apiProps).then(() => {
        expect(fetchMock.lastOptions(uri).headers.Authorization).toEqual('Bearer theJWT')
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
        expect(response.upload).toEqual('done')
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
        expect(apiSource.jwt).toEqual('freshJWT')
      })
    })

    it('calls alertFunc when an error occurs', () => {
      fetchMock.mock(uri, 500)
      return apiSource
        .preflightUpload(fileProps, apiProps)
        .then(() => {
          expect(alertFuncSpy).toHaveBeenCalledWith({
            text: 'Something went wrong uploading, check your connection and try again.',
            variant: 'error',
          })
        })
        .catch(() => {
          // This will re-throw so we just catch it here.
        })
    })

    it('throws an exception when an error occurs', () => {
      fetchMock.mock(uri, 500)
      return apiSource.preflightUpload(fileProps, apiProps).catch(e => {
        expect(e).not.toBeNull()
      })
    })

    describe('when the file storage quota is exceeded', () => {
      beforeEach(() => {
        const error = new Error('file size exceeds quota')
        error.response = {json: async () => ({message: 'file size exceeds quota'})}

        fetchMock.mock(uri, {throws: error}, {overwriteRoutes: true})
      })

      it('gives a "quota" error if quota is full', async () => {
        try {
          await apiSource.preflightUpload(fileProps, apiProps)
          expect(alertFuncSpy).toHaveBeenCalledWith({
            text: 'File storage quota exceeded',
            variant: 'error',
          })
        } catch (e) {
          return e
        } // This will re-throw so we just catch it here/
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
        upload_url: uploadUrl,
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
          expect(alertFuncSpy).toHaveBeenCalledWith({
            text: 'Something went wrong uploading, check your connection and try again.',
            variant: 'error',
          })
        })
        .catch(() => {})
    })

    describe('files', () => {
      beforeEach(() => {
        wrapUrl = '/groups/123/path?wrap=1'
        jest.spyOn(fileUrl, 'downloadToWrap').mockReturnValue(wrapUrl)
        jest.spyOn(fileUrl, 'fixupFileUrl').mockReturnValue(wrapUrl)
        jest.spyOn(apiSource, 'getFile').mockReturnValue(Promise.resolve(file))
      })

      afterEach(() => {
        jest.restoreAllMocks()
      })

      it('includes credentials in non-S3 upload', () => {
        preflightProps.upload_params.success_url = undefined
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          expect(fetchMock.lastOptions(uploadUrl).credentials).toEqual('include')
        })
      })

      it('does not include credentials in S3 upload', () => {
        preflightProps.upload_params['x-amz-signature'] = 'success-url'
        preflightProps.upload_params.success_url = 'success-url'
        const s3File = {url: 's3-file-url'}
        fetchMock.mock(preflightProps.upload_params.success_url, s3File)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          expect(fetchMock.lastOptions(uploadUrl).credentials).toBeUndefined()
        })
      })

      it('does not include credentials in a local cross-origin upload', () => {
        preflightProps.upload_params.success_url = undefined
        const crossOriginUploadUrl = 'cross-origin.site/files_api'
        preflightProps.upload_url = crossOriginUploadUrl
        fetchMock.mock(crossOriginUploadUrl, file)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(() => {
          expect(fetchMock.lastOptions(crossOriginUploadUrl).credentials).toBeUndefined()
        })
      })

      it('handles s3 post-flight', async () => {
        preflightProps.upload_params.success_url = 'success-url'
        const s3File = {url: 's3-file-url'}
        fetchMock.mock(preflightProps.upload_params.success_url, s3File)
        const result = await apiSource.uploadFRD(fileDomObject, preflightProps)
        expect(result).toEqual(s3File)
      })

      it('handles inst-fs post-flight', () => {
        preflightProps.upload_url = 'instfs-upload-url'
        const fileId = '123'
        const response = {
          location: `http://canvas/api/v1/files/${fileId}?foo=bar`,
          uuid: 'xyzzy',
        }
        fetchMock.mock(preflightProps.upload_url, response)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(resp => {
          expect(apiSource.getFile).toHaveBeenCalledWith(fileId)
          expect(resp.uuid).toEqual('xyzzy')
          expect(resp.url).toEqual('file-url')
        })
      })

      it('handles inst-fs post-flight with global file id', () => {
        preflightProps.upload_url = 'instfs-upload-url'
        const fileId = '1023~789'
        const response = {
          location: `http://canvas/api/v1/files/${fileId}?foo=bar`,
          uuid: 'xyzzy',
        }
        fetchMock.mock(preflightProps.upload_url, response)
        return apiSource.uploadFRD(fileDomObject, preflightProps).then(resp => {
          expect(apiSource.getFile).toHaveBeenCalledWith(fileId)
          expect(resp.uuid).toEqual('xyzzy')
          expect(resp.url).toEqual('file-url')
        })
      })
    })
  })

  describe('api mapping', () => {
    const body = {
      bookmark: 'mo.images',
      files: [{href: '/some/where', uuid: 'xyzzy'}],
    }
    props.images = {
      group: {
        isLoading: false,
        hasMore: true,
        bookmark: null,
        files: [],
      },
    }
    props.searchString = 'panda'

    it('can fetch folders', async () => {
      fetchMock.mock(/\/folders\?/, {body})
      const page = await apiSource.fetchRootFolder(props)
      expect(page).toEqual(body)
    })

    it('requests images from API', async () => {
      fetchMock.mock(/\/documents\?.*content_types=image/, {body})
      const page = await apiSource.fetchImages(props)
      expect(page).toEqual({
        bookmark: 'mo.images',
        files: [{href: '/some/where?wrap=1', uuid: 'xyzzy'}],
        searchString: 'panda',
      })
    })

    it('requests subsequent page of images from API', async () => {
      props.images.group.bookmark = 'mo.images'
      fetchMock.mock(/\/documents\?.*content_types=image/, 'should not get here')
      fetchMock.mock(/mo.images/, {body})
      const page = await apiSource.fetchImages(props)
      expect(page).toEqual({
        bookmark: 'mo.images',
        files: [{href: '/some/where?wrap=1', uuid: 'xyzzy'}],
        searchString: 'panda',
      })
    })
  })

  describe('getSession', () => {
    const uri = '/api/session' // already mocked

    it('includes jwt in Authorization header', () => {
      return apiSource.getSession().then(() => {
        expect(fetchMock.lastOptions(uri).headers.Authorization).toEqual('Bearer theJWT')
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
        expect(fetchMock.lastOptions(uri).headers.Authorization).toEqual('Bearer theJWT')
      })
    })

    it('posts file id and usage rights to the api', () => {
      return apiSource.setUsageRights(fileId, usageRights).then(() => {
        const postBody = JSON.parse(fetchMock.lastOptions(uri).body)
        expect(postBody).toEqual({
          fileId,
          usageRight: usageRights.usageRight,
        })
      })
    })
  })

  describe('getFile', () => {
    const id = 47
    const uri = `/api/file/${id}`
    let url = '/file/url'
    setProps = {}

    it('includes jwt in Authorization header', () => {
      fetchMock.mock(uri, {url})

      return apiSource.getFile(id, setProps).then(() => {
        expect(fetchMock.lastOptions(uri).headers.Authorization).toEqual('Bearer theJWT')
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

      return apiSource.getFile(id, setProps).then(response => {
        expect(response.upload).toEqual('done')
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

      return apiSource.getFile(id, setProps).then(() => {
        expect(apiSource.jwt).toEqual('freshJWT')
      })
    })

    it('transforms file url with downloadToWrap', () => {
      url = '/file/url?download_frd=1'
      const wrapUrl = '/file/url?wrap=1'
      fetchMock.mock('*', {url})
      jest.spyOn(fileUrl, 'downloadToWrap').mockReturnValue(wrapUrl)
      return apiSource.getFile(id).then(file => {
        expect(fileUrl.downloadToWrap).toHaveBeenCalledWith(url)
        expect(file.href).toEqual(wrapUrl)
        fetchMock.restore()
      })
    })

    it('defaults display_name to name', () => {
      url = '/file/url?download_frd=1'
      const name = 'filename'
      fetchMock.mock('*', {url, name})
      jest.spyOn(fileUrl, 'downloadToWrap')
      return apiSource.getFile(id).then(file => {
        expect(file.display_name).toEqual(name)
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
        expect(fetchMock.lastOptions(uri).headers.Authorization).toEqual('Bearer theJWT')
        expect(response).toEqual({media_id: 'm-id', title: 'new title'})
      })
    })
  })

  describe('headerFor', () => {
    it('returns an authorization header', () => {
      expect(headerFor('the_jwt')).toEqual({
        Authorization: 'Bearer the_jwt',
      })
    })
  })

  describe('originFromHost', () => {
    // this logic was factored out from baseUri, so the logic is tested
    // there too.
    it('uses the incoming http protocol if present', () => {
      expect(originFromHost('http://host:port')).toEqual('http://host:port')
    })

    it('uses the incoming https protocol if present', () => {
      expect(originFromHost('https://host:port')).toEqual('https://host:port')
    })

    it('uses the provided protocol if present', () => {
      const win = {
        location: {
          protocol: 'https:',
        },
      }
      expect(originFromHost('http://host:port', win)).toEqual('http://host:port')
    })

    it('uses the window protocol if not present', () => {
      const win = {
        location: {
          protocol: 'https:',
        },
      }
      expect(originFromHost('host:port', win)).toEqual('https://host:port')
    })
  })
})
