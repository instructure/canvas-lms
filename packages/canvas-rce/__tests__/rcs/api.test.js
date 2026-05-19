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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import RceApiSource, {headerFor, originFromHost} from '../../src/rcs/api'
import * as fileUrl from '../../src/common/fileUrl'
import {ICON_MAKER_ICONS} from '../../src/rce/plugins/instructure_icon_maker/svg/constants'

const BASE = 'http://localhost'

const server = setupServer(http.get(`${BASE}/api/session`, () => HttpResponse.json({})))

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
  let noHostApiSource

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  beforeEach(() => {
    alertFuncSpy = jest.fn()
    apiSource = new RceApiSource({
      jwt: 'theJWT',
      host: 'localhost',
      refreshToken: callback => {
        callback('freshJWT')
      },
      alertFunc: alertFuncSpy,
    })
    noHostApiSource = new RceApiSource({
      jwt: 'theJWT',
      refreshToken: callback => {
        callback('freshJWT')
      },
      alertFunc: alertFuncSpy,
    })
  })

  afterEach(() => {
    server.resetHandlers()
    jest.restoreAllMocks()
  })

  afterAll(() => {
    server.close()
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
        `${window.location.protocol}//example.host/api/wikiPages?contextType=group&contextId=123&search_term=panda`,
      )
    })

    it('bookmark omits host if not in props', () => {
      const noHostProps = {...props, host: undefined}
      collection = noHostApiSource.initializeCollection(endpoint, noHostProps)
      expect(collection.bookmark).toEqual(
        '/api/wikiPages?contextType=group&contextId=123&search_term=panda',
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
      const uri = noHostApiSource.baseUri('files')
      expect(uri).toEqual('/api/files')
    })

    it('gets protocol from window if available', () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = apiSource.baseUri('files', 'example.instructure.com', fakeWindow)
      expect(uri).toEqual('https://example.instructure.com/api/files')
    })

    it('never applies protocol to path', () => {
      const fakeWindow = {location: {protocol: 'https:'}}
      const uri = noHostApiSource.baseUri('files', null, fakeWindow)
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
      const uri = noHostApiSource.uriFor('documents', setProps)
      expect(uri).toEqual(
        '/api/documents?contextType=course&contextId=17&exclude_content_types=image,video,audio&sort=name&order=asc&search_term=hello%20world',
      )
    })

    it('gets images', () => {
      const uri = noHostApiSource.uriFor('images', setProps)
      expect(uri).toEqual(
        '/api/documents?contextType=course&contextId=17&content_types=image&sort=name&order=asc&search_term=hello%20world',
      )
    })

    // this endpoint isn't actually used yet, but could be if media_objects all had associated Attachments
    it('gets media', () => {
      const uri = noHostApiSource.uriFor('media', setProps)
      expect(uri).toEqual(
        '/api/documents?contextType=course&contextId=17&content_types=video,audio&sort=name&order=asc&search_term=hello%20world',
      )
    })

    it('gets media_objects', () => {
      const uri = noHostApiSource.uriFor('media_objects', setProps)
      expect(uri).toEqual(
        '/api/media_objects?contextType=course&contextId=17&sort=title&order=asc&search_term=hello%20world',
      )
    })
  })

  describe('fetchPage', () => {
    const uri = `${BASE}/theURI`
    const fakePageBody = {
      bookmark: 'newBookmark',
      links: [
        {href: 'link1', title: 'Link 1'},
        {href: 'link2', title: 'Link 2'},
      ],
    }

    it('includes jwt in Authorization header', async () => {
      let capturedRequest
      server.use(
        http.get(uri, ({request}) => {
          capturedRequest = request
          return HttpResponse.json({})
        }),
      )
      await apiSource.fetchPage(uri)
      expect(capturedRequest.headers.get('Authorization')).toEqual('Bearer theJWT')
    })

    it('converts 400+ statuses to errors', async () => {
      server.use(
        http.get(uri, () => new HttpResponse(null, {status: 403, statusText: 'Forbidden'})),
      )
      await expect(apiSource.fetchPage(uri)).rejects.toThrow('Forbidden')
    })

    it('parses server response before handing it back', async () => {
      server.use(http.get(uri, () => HttpResponse.json(fakePageBody)))
      const page = await apiSource.fetchPage(uri)
      expect(page).toEqual(fakePageBody)
    })

    it('retries once on 401 with a renewed token', async () => {
      server.use(
        http.get(uri, ({request}) => {
          const auth = request.headers.get('Authorization')
          if (auth === 'Bearer theJWT') return new HttpResponse(null, {status: 401})
          return HttpResponse.json(fakePageBody)
        }),
      )
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
      const fetchUri = `${BASE}/files-uri`
      const body = await apiSource.fetchFiles(fetchUri)
      expect(apiSource.fetchPage).toHaveBeenCalledWith(fetchUri)
      expect(body.bookmark).toEqual(bookmark)
    })

    it('converts file urls from download to preview', async () => {
      const body = await apiSource.fetchFiles(`${BASE}/foo`)
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
        },
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
            },
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

    const subject = () =>
      apiSource.fetchBookmarkedData(fetchFunction, properties, onSuccess, onError)

    it('calls the "fetchFunction", passing "properties"', async () => {
      await subject()
      expect(fetchFunction).toHaveBeenCalledWith(properties, undefined)
      expect(fetchFunction).toHaveBeenCalledWith(
        properties,
        'https://canvas.rce/api/thing/1?page=2',
      )
      expect(fetchFunction).toHaveBeenCalledTimes(2)
    })

    it('calls "onSuccess" for each page', async () => {
      await subject()
      expect(onSuccess).toHaveBeenCalledTimes(2)
    })

    describe('when "fetchFunction" throws an exception', () => {
      beforeEach(() => {
        fetchFunction.mockReset()
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
            `${BASE}/api/folders/icon_maker?contextType=course&contextId=22`,
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
            `${BASE}/api/folders/media?contextType=course&contextId=22`,
          )
        })
    })
  })

  describe('preflightUpload', () => {
    const uri = `${BASE}/api/upload`
    const fileProps = {}
    const apiProps = {}

    it('includes "onDuplicate"', async () => {
      let capturedBody
      server.use(
        http.post(uri, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      await apiSource.preflightUpload(fileProps, {onDuplicate: 'overwrite'}, apiProps)
      expect(capturedBody.onDuplicate).toEqual('overwrite')
    })

    it('includes "category"', async () => {
      let capturedBody
      server.use(
        http.post(uri, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      await apiSource.preflightUpload(fileProps, {category: ICON_MAKER_ICONS}, apiProps)
      expect(capturedBody.category).toEqual(ICON_MAKER_ICONS)
    })

    it('includes jwt in Authorization header', async () => {
      let capturedRequest
      server.use(
        http.post(uri, ({request}) => {
          capturedRequest = request
          return HttpResponse.json({})
        }),
      )
      await apiSource.preflightUpload(fileProps, apiProps)
      expect(capturedRequest.headers.get('Authorization')).toEqual('Bearer theJWT')
    })

    it('retries once with fresh token on 401', async () => {
      server.use(
        http.post(uri, ({request}) => {
          const auth = request.headers.get('Authorization')
          if (auth === 'Bearer theJWT') return new HttpResponse(null, {status: 401})
          return HttpResponse.json({upload: 'done'})
        }),
      )
      const response = await apiSource.preflightUpload(fileProps, apiProps)
      expect(response.upload).toEqual('done')
    })

    it('notifies a provided callback when a new token is fetched', async () => {
      server.use(
        http.post(uri, ({request}) => {
          const auth = request.headers.get('Authorization')
          if (auth === 'Bearer theJWT') return new HttpResponse(null, {status: 401})
          return HttpResponse.json({upload: 'done'})
        }),
      )
      await apiSource.preflightUpload(fileProps, apiProps)
      expect(apiSource.jwt).toEqual('freshJWT')
    })

    it('calls alertFunc when an error occurs', async () => {
      jest.spyOn(console, 'error').mockImplementation(() => {})
      server.use(http.post(uri, () => HttpResponse.json({}, {status: 500})))
      await apiSource.preflightUpload(fileProps, apiProps).catch(() => {})
      expect(alertFuncSpy).toHaveBeenCalledWith({
        text: 'Something went wrong. Check your connection, reload the page, and try again.',
        variant: 'error',
      })
    })

    it('throws an exception when an error occurs', () => {
      server.use(
        http.post(
          uri,
          () => new HttpResponse(null, {status: 500, statusText: 'Internal Server Error'}),
        ),
      )
      return apiSource.preflightUpload(fileProps, apiProps).catch(e => {
        expect(e).not.toBeNull()
      })
    })

    describe('when the file storage quota is exceeded', () => {
      beforeEach(() => {
        server.use(
          http.post(uri, () =>
            HttpResponse.json({message: 'file size exceeds quota'}, {status: 413}),
          ),
        )
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
        }
      })
    })
  })

  describe('uploadFRD', () => {
    let fileDomObject, uploadUrl, preflightProps, file, wrapUrl

    beforeEach(() => {
      fileDomObject = new window.Blob()
      uploadUrl = 'http://upload-url/'
      preflightProps = {
        upload_params: {},
        upload_url: uploadUrl,
      }
      file = {url: 'file-url'}
      server.use(http.post(uploadUrl, () => HttpResponse.json(file)))
    })

    it('calls alertFunc if there is a problem', () => {
      server.use(
        http.post(
          uploadUrl,
          () => new HttpResponse(null, {status: 500, statusText: 'Internal Server Error'}),
        ),
      )
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

      it('includes credentials in non-S3 upload', async () => {
        // request.credentials is not available in MSW Node.js handlers; spy on fetch directly
        const fetchSpy = jest.spyOn(global, 'fetch')
        preflightProps.upload_params.success_url = undefined
        await apiSource.uploadFRD(fileDomObject, preflightProps)
        const uploadCall = fetchSpy.mock.calls.find(([url]) => String(url).includes('upload-url'))
        expect(uploadCall?.[1]?.credentials).toEqual('include')
      })

      it('does not include credentials in S3 upload', async () => {
        const fetchSpy = jest.spyOn(global, 'fetch')
        preflightProps.upload_params['x-amz-signature'] = 'success-url'
        preflightProps.upload_params.success_url = 'http://success-url/'
        const s3File = {url: 's3-file-url'}
        server.use(http.get('http://success-url/', () => HttpResponse.json(s3File)))
        await apiSource.uploadFRD(fileDomObject, preflightProps)
        const uploadCall = fetchSpy.mock.calls.find(([url]) => String(url).includes('upload-url'))
        expect(uploadCall?.[1]?.credentials).not.toEqual('include')
      })

      it('does not include credentials in a local cross-origin upload', async () => {
        const fetchSpy = jest.spyOn(global, 'fetch')
        preflightProps.upload_params.success_url = undefined
        const crossOriginUploadUrl = 'http://cross-origin.site/files_api'
        preflightProps.upload_url = crossOriginUploadUrl
        server.use(http.post(crossOriginUploadUrl, () => HttpResponse.json(file)))
        await apiSource.uploadFRD(fileDomObject, preflightProps)
        const uploadCall = fetchSpy.mock.calls.find(([url]) =>
          String(url).includes('cross-origin.site'),
        )
        expect(uploadCall?.[1]?.credentials).not.toEqual('include')
      })

      it('handles s3 post-flight', async () => {
        preflightProps.upload_params.success_url = 'http://success-url/'
        const s3File = {url: 's3-file-url'}
        server.use(http.get('http://success-url/', () => HttpResponse.json(s3File)))
        const result = await apiSource.uploadFRD(fileDomObject, preflightProps)
        expect(result).toEqual(s3File)
      })

      it('handles inst-fs post-flight', async () => {
        const fileId = '123'
        const instFsUrl = 'http://instfs-upload-url/'
        preflightProps.upload_url = instFsUrl
        const response = {
          location: `http://canvas/api/v1/files/${fileId}?foo=bar`,
          uuid: 'xyzzy',
        }
        server.use(http.post(instFsUrl, () => HttpResponse.json(response)))
        const resp = await apiSource.uploadFRD(fileDomObject, preflightProps)
        expect(apiSource.getFile).toHaveBeenCalledWith(fileId)
        expect(resp.uuid).toEqual('xyzzy')
        expect(resp.url).toEqual('file-url')
      })

      it('handles inst-fs post-flight with global file id', async () => {
        const fileId = '1023~789'
        const instFsUrl = 'http://instfs-upload-url/'
        preflightProps.upload_url = instFsUrl
        const response = {
          location: `http://canvas/api/v1/files/${fileId}?foo=bar`,
          uuid: 'xyzzy',
        }
        server.use(http.post(instFsUrl, () => HttpResponse.json(response)))
        const resp = await apiSource.uploadFRD(fileDomObject, preflightProps)
        expect(apiSource.getFile).toHaveBeenCalledWith(fileId)
        expect(resp.uuid).toEqual('xyzzy')
        expect(resp.url).toEqual('file-url')
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
      server.use(http.get(/\/api\/folders/, () => HttpResponse.json(body)))
      const page = await apiSource.fetchRootFolder(props)
      expect(page).toEqual(body)
    })

    it('requests images from API', async () => {
      server.use(http.get(/\/api\/documents/, () => HttpResponse.json(body)))
      const page = await apiSource.fetchImages(props)
      expect(page).toEqual({
        bookmark: 'mo.images',
        files: [{href: '/some/where?wrap=1', uuid: 'xyzzy'}],
        searchString: 'panda',
      })
    })

    it('requests subsequent page of images from API', async () => {
      props.images.group.bookmark = `${BASE}/api/documents?page=2`
      server.use(http.get(`${BASE}/api/documents`, () => HttpResponse.json(body)))
      const page = await apiSource.fetchImages(props)
      expect(page).toEqual({
        bookmark: 'mo.images',
        files: [{href: '/some/where?wrap=1', uuid: 'xyzzy'}],
        searchString: 'panda',
      })
    })
  })

  describe('getSession', () => {
    it('includes jwt in Authorization header', async () => {
      let capturedRequest
      server.use(
        http.get(`${BASE}/api/session`, ({request}) => {
          capturedRequest = request
          return HttpResponse.json({})
        }),
      )
      await apiSource.getSession()
      expect(capturedRequest.headers.get('Authorization')).toEqual('Bearer theJWT')
    })
  })

  describe('setUsageRights', () => {
    const uri = `${BASE}/api/usage_rights`
    const fileId = 47
    const usageRights = {usageRight: 'foo'}

    it('includes jwt in Authorization header', async () => {
      let capturedRequest
      server.use(
        http.post(uri, ({request}) => {
          capturedRequest = request
          return HttpResponse.json({})
        }),
      )
      await apiSource.setUsageRights(fileId, usageRights)
      expect(capturedRequest.headers.get('Authorization')).toEqual('Bearer theJWT')
    })

    it('posts file id and usage rights to the api', async () => {
      let capturedBody
      server.use(
        http.post(uri, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      await apiSource.setUsageRights(fileId, usageRights)
      expect(capturedBody).toEqual({
        fileId,
        usageRight: usageRights.usageRight,
      })
    })
  })

  describe('getFile', () => {
    const id = 47
    const uri = `${BASE}/api/file/${id}`
    let url = '/file/url'
    setProps = {}

    it('includes jwt in Authorization header', async () => {
      let capturedRequest
      server.use(
        http.get(uri, ({request}) => {
          capturedRequest = request
          return HttpResponse.json({url})
        }),
      )
      await apiSource.getFile(id, setProps)
      expect(capturedRequest.headers.get('Authorization')).toEqual('Bearer theJWT')
    })

    it('retries once with fresh token on 401', async () => {
      server.use(
        http.get(uri, ({request}) => {
          const auth = request.headers.get('Authorization')
          if (auth === 'Bearer theJWT') return new HttpResponse(null, {status: 401})
          return HttpResponse.json({upload: 'done', url})
        }),
      )
      const response = await apiSource.getFile(id, setProps)
      expect(response.upload).toEqual('done')
    })

    it('notifies a provided callback when a new token is fetched', async () => {
      server.use(
        http.get(uri, ({request}) => {
          const auth = request.headers.get('Authorization')
          if (auth === 'Bearer theJWT') return new HttpResponse(null, {status: 401})
          return HttpResponse.json({upload: 'done', url})
        }),
      )
      await apiSource.getFile(id, setProps)
      expect(apiSource.jwt).toEqual('freshJWT')
    })

    it('transforms file url with downloadToWrap', async () => {
      url = '/file/url?download_frd=1'
      const wrapUrl = '/file/url?wrap=1'
      server.use(http.get(uri, () => HttpResponse.json({url})))
      jest.spyOn(fileUrl, 'downloadToWrap').mockReturnValue(wrapUrl)
      const file = await apiSource.getFile(id)
      expect(fileUrl.downloadToWrap).toHaveBeenCalledWith(url)
      expect(file.href).toEqual(wrapUrl)
    })

    it('defaults display_name to name', async () => {
      url = '/file/url?download_frd=1'
      const name = 'filename'
      server.use(http.get(uri, () => HttpResponse.json({url, name})))
      jest.spyOn(fileUrl, 'downloadToWrap')
      const file = await apiSource.getFile(id)
      expect(file.display_name).toEqual(name)
    })
  })

  describe('media object apis', () => {
    describe('updateMediaObject', () => {
      it('PUTs to the media_object endpoint', async () => {
        const mediaId = 'm-id'
        const title = 'new title'
        let capturedRequest
        server.use(
          http.put(`${BASE}/api/media_objects/:mediaId`, ({request}) => {
            capturedRequest = request
            return HttpResponse.json({media_id: mediaId, title})
          }),
        )
        const response = await apiSource.updateMediaObject({}, {media_object_id: mediaId, title})
        expect(capturedRequest.headers.get('Authorization')).toEqual('Bearer theJWT')
        expect(response).toEqual({media_id: mediaId, title})
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
