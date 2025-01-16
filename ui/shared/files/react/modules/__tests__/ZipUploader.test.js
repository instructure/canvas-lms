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
import moxios from 'moxios'

function setupMocks() {
  moxios.stubRequest('/api/v1/courses/1/content_migrations', {
    status: 200,
    response: {
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
    },
  })
  moxios.stubRequest('/upload/url', {
    status: 201,
    response: '<PostResponse></PostResponse>',
  })
  moxios.stubRequest('/api/v1/courses/1/content_migrations/17', {
    status: 200,
    response: {
      progress_url: '/api/v1/progress/35',
    },
  })
  moxios.stubRequest('/api/v1/progress/35', {
    status: 200,
    response: {
      workflow_state: undefined, // 'failed' if bad things happened
      completion: 90,
    },
  })
  moxios.stubRequest('/api/v1/progress/35#90', {
    status: 200,
    response: {
      workflow_state: undefined, // 'failed' if bad things happened
      completion: 100,
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
  const blob = new Blob(['hello world'], {type: 'text/plain'})
  const file = new File([blob], 'foo', {type: 'text/plain'})
  Object.defineProperty(file, 'size', {value: 123})
  return {
    file,
    name: file.name,
  }
}

describe('ZipUploader', () => {
  beforeEach(() => {
    moxios.install()
    setupMocks()

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
    moxios.uninstall()
    jest.restoreAllMocks()
  })

  test('posts to the files endpoint to kick off upload', function (done) {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    jest.spyOn(zuploader, 'onPreflightComplete').mockImplementation(() => {})

    moxios.wait(() => {
      return zuploader.upload().then(_response => {
        expect(moxios.requests.mostRecent().url).toBe('/api/v1/courses/1/content_migrations')
        // eslint-disable-next-line promise/no-callback-in-promise
        done()
      })
    })
  })

  test('stores params from preflight for actual upload', function (done) {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    jest.spyOn(zuploader, '_actualUpload').mockImplementation(() => {})

    moxios.wait(() => {
      return zuploader.upload().then(_response => {
        expect(zuploader.uploadData.upload_url).toBe('/upload/url')
        expect(zuploader.uploadData.upload_params.Filename).toBe('foo')
        // eslint-disable-next-line promise/no-callback-in-promise
        done()
      })
    })
  })

  test('completes upload after preflight', function (done) {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    const getContentMigrationSpy = jest.spyOn(zuploader, 'getContentMigration')

    moxios.wait(() => {
      zuploader
        .upload()
        .then(_response => {
          expect(getContentMigrationSpy).toHaveBeenCalled()
          done()
        })
        .catch(done)
    })
  })

  test('tracks progress', function (done) {
    const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
    const trackProgressSpy = jest.spyOn(zuploader, 'trackProgress')

    moxios.wait(() => {
      zuploader
        .upload()
        .then(_response => {
          expect(trackProgressSpy).toHaveBeenCalled()
          done()
        })
        .catch(done)
    })
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
