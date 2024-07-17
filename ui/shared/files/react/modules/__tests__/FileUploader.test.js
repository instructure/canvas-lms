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
import moxios from 'moxios'

function setupMocks() {
  moxios.stubRequest('/api/v1/folders/1/files', {
    status: 200,
    response: {
      file_param: 'file',
      upload_url: '/upload/url',
      upload_params: {
        Filename: 'foo',
        success_action_status: '201',
        'content-type': 'text/plain',
        success_url: '/create_success',
      },
    },
  })
  moxios.stubRequest('/upload/url', {
    status: 201,
    response: {},
  })
  moxios.stubRequest('/create_success', {
    status: 200,
    response: {
      id: '17',
      'content-type': 'text/plain',
    },
  })
}

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
  beforeEach(() => {
    moxios.install()
    setupMocks()
  })

  afterEach(() => {
    moxios.uninstall()
  })

  test('posts to the files endpoint to kick off upload', async () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, 'onPreflightComplete').mockImplementation()

    moxios.wait(async () => {
      await fuploader.upload()
      expect(moxios.requests.mostRecent().url).toBe('/api/v1/folders/1/files')
    })
  })

  test('stores params from preflight for actual upload', async () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, '_actualUpload').mockImplementation()

    moxios.wait(async () => {
      await fuploader.upload()
      expect(fuploader.uploadData.upload_url).toBe('/upload/url')
      expect(fuploader.uploadData.upload_params.Filename).toBe('foo')
    })
  })

  test('completes upload after preflight', async () => {
    const fuploader = new FileUploader(mockFileOptions(), folder)
    jest.spyOn(fuploader, 'addFileToCollection').mockImplementation()

    moxios.wait(async () => {
      await fuploader.upload()
      expect(fuploader.addFileToCollection).toHaveBeenCalledWith({
        id: '17',
        'content-type': 'text/plain',
      })
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
