/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import ZipUploader from '../ZipUploader'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer(
  http.post('/api/v1/courses/1/content_migrations', () =>
    HttpResponse.json({
      id: 17,
      pre_attachment: {
        upload_url: '/upload/url',
        upload_params: {
          Filename: 'foo',
          success_action_status: '201',
          'content-type': 'text/plain',
        },
        file_param: 'file',
      },
      progress_url: '/api/v1/progress/35',
    }),
  ),
  http.post(
    '/upload/url',
    () =>
      new HttpResponse('<PostResponse></PostResponse>', {
        status: 201,
        headers: {'content-type': 'text/html'},
      }),
  ),
  http.get('/api/v1/courses/1/content_migrations/17', () =>
    HttpResponse.json({
      progress_url: '/api/v1/progress/35',
    }),
  ),
  http.get('/api/v1/progress/35', () =>
    HttpResponse.json({
      workflow_state: undefined, // 'failed' if bad things happened
      completion: 90,
    }),
  ),
  http.get('/api/v1/progress/35', ({request}) => {
    const url = new URL(request.url)
    // Check if fragment or query param indicates 90% completion
    return HttpResponse.json({
      workflow_state: undefined, // 'failed' if bad things happened
      completion: 100,
    })
  }),
)

const folder = {
  id: 1,
  folders: {
    fetch: () => Promise.resolve(),
  },
  files: {
    fetch: () => Promise.resolve(),
  },
}

const mockFileOptions = function () {
  const blob = new Blob(['hello world'], {type: 'text/plain'})
  const file = new File([blob], 'foo', {type: 'text/plain'})
  Object.defineProperty(file, 'size', {value: 123})
  return {
    file,
    name: file.name,
  }
}

describe('ZipUploader', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    URL.createObjectURL = jest.fn(blob => {
      return `blob:mock-url-${blob.name || 'unnamed'}`
    })

    global.FormData = class FormData {
      constructor() {
        this.data = new Map()
      }
      append(key, value) {
        this.data.set(key, value)
      }
    }
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('posts to the files endpoint to kick off upload', async function () {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    jest.spyOn(zuploader, 'onPreflightComplete').mockImplementation(() => Promise.resolve())

    await zuploader.upload()
    // The request should have been made to the correct endpoint
    // (handled by our mock server)
  })

  test('stores params from preflight for actual upload', async function () {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    jest.spyOn(zuploader, '_actualUpload').mockImplementation(() => Promise.resolve())

    await zuploader.upload()
    expect(zuploader.uploadData.upload_url).toBe('/upload/url')
    expect(zuploader.uploadData.upload_params.Filename).toBe('foo')
  })

  test('completes upload after preflight', async function () {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    const getContentMigrationSpy = jest
      .spyOn(zuploader, 'getContentMigration')
      .mockImplementation(() => Promise.resolve())
    jest.spyOn(zuploader, 'trackProgress').mockImplementation(() => Promise.resolve())

    await zuploader.upload()
    expect(getContentMigrationSpy).toHaveBeenCalled()
  })

  test('tracks progress', async function () {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    const trackProgressSpy = jest
      .spyOn(zuploader, 'trackProgress')
      .mockImplementation(() => Promise.resolve())
    jest.spyOn(zuploader, 'getContentMigration').mockImplementation(() => Promise.resolve())

    await zuploader.upload()
    expect(trackProgressSpy).toHaveBeenCalled()
  })

  test('roundProgress returns back rounded values', function () {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    jest.spyOn(zuploader, 'getProgress').mockReturnValue(0.18) // progress is [0 .. 1]
    expect(zuploader.roundProgress()).toBe(18)
  })

  test('roundProgress returns back values no greater than 100', function () {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    jest.spyOn(zuploader, 'getProgress').mockReturnValue(1.1) // something greater than 100%
    expect(zuploader.roundProgress()).toBe(100)
  })

  test('getFileName returns back the option name if one exists', function () {
    const options = mockFileOptions()
    options.name = 'use this one'
    const zuploader = new ZipUploader(options, folder, '1', 'courses')
    expect(zuploader.getFileName()).toBe('use this one')
  })

  test('getFileName returns back the actual file if no optinal name is given', function () {
    const options = mockFileOptions()
    const zuploader = new ZipUploader(options, folder, '1', 'courses')
    expect(zuploader.getFileName()).toBe('foo')
  })
})
