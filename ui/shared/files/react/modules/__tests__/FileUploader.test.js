/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import FileUploader from '../FileUploader'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer(
  http.post('/api/v1/folders/1/files', () =>
    HttpResponse.json({
      file_param: 'file',
      upload_url: '/upload/url',
      upload_params: {
        Filename: 'foo',
        success_action_status: '201',
        'content-type': 'text/plain',
        success_url: '/create_success',
      },
    }),
  ),
  http.post('/upload/url', () => HttpResponse.json({}, {status: 201})),
  http.get('/create_success', () =>
    HttpResponse.json({
      id: '17',
      'content-type': 'text/plain',
    }),
  ),
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
  return {
    file: new File(['hello world'], 'foo', {type: 'text/plain'}),
  }
}

describe('FileUploader', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  test('posts to the files endpoint to kick off upload', async () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, 'onPreflightComplete').mockImplementation()

    await fuploader.upload()
    // The request is handled by MSW, so we just verify the method was called
    expect(fuploader.onPreflightComplete).toHaveBeenCalled()
  })

  test('stores params from preflight for actual upload', async () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, '_actualUpload').mockImplementation()

    await fuploader.upload()
    expect(fuploader.uploadData.upload_url).toBe('/upload/url')
    expect(fuploader.uploadData.upload_params.Filename).toBe('foo')
  })

  test('completes upload after preflight', async () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, 'addFileToCollection').mockImplementation()

    // Mock the actual upload to return a promise that resolves with the file data
    // The promise resolution will trigger onUploadPosted
    jest.spyOn(fuploader, '_actualUpload').mockImplementation(() => {
      // Simulate the promise chain that calls onUploadPosted
      return Promise.resolve({
        id: '17',
        'content-type': 'text/plain',
      }).then(result => {
        fuploader.onUploadPosted(result)
        return result
      })
    })

    await fuploader.upload()

    expect(fuploader.addFileToCollection).toHaveBeenCalledWith({
      id: '17',
      'content-type': 'text/plain',
    })
  })

  test('roundProgress returns back rounded values', () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, 'getProgress').mockReturnValue(0.18) // progress is [0 .. 1]
    expect(fuploader.roundProgress()).toBe(18)
  })

  test('roundProgress returns back values no greater than 100', () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, 'getProgress').mockReturnValue(1.1) // something greater than 100%
    expect(fuploader.roundProgress()).toBe(100)
  })

  test('getFileName returns back the option name if one exists', () => {
    const options = mockFileOptions()
    options.name = 'use this one'
    const fuploader = new FileUploader(options, folder)
    expect(fuploader.getFileName()).toBe('use this one')
  })

  test('getFileName returns back the actual file if no optional name is given', () => {
    const options = mockFileOptions()
    const fuploader = new FileUploader(options, folder)
    expect(fuploader.getFileName()).toBe('foo')
  })
})
