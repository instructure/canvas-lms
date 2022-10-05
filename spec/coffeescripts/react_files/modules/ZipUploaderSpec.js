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

import ZipUploader from '@canvas/files/react/modules/ZipUploader'
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
  // I realize type: 'text/plain' looks wrong for a zipuploader test,
  // but we need a File and we're never really unzipping
  return {
    file: new File(['hello world'], 'foo', {type: 'text/plain'}),
  }
}

QUnit.module('ZipUploader', {
  setup() {
    moxios.install()
    setupMocks()
  },
  teardown() {
    moxios.uninstall()
  },
})

test('posts to the files endpoint to kick off upload', function (assert) {
  const done = assert.async()
  const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
  sinon.stub(zuploader, 'onPreflightComplete')

  moxios.wait(() => {
    return zuploader.upload().then(_response => {
      equal(moxios.requests.mostRecent().url, '/api/v1/courses/1/content_migrations')
      done()
    })
  })
})

test('stores params from preflight for actual upload', function (assert) {
  const done = assert.async()
  const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
  sinon.stub(zuploader, '_actualUpload')

  moxios.wait(() => {
    return zuploader.upload().then(_response => {
      equal(zuploader.uploadData.upload_url, '/upload/url')
      equal(zuploader.uploadData.upload_params.Filename, 'foo')
      done()
    })
  })
})

test('completes upload after preflight', function (assert) {
  const done = assert.async()
  const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')

  sandbox.stub(zuploader, 'getContentMigration')

  moxios.wait(() => {
    return zuploader.upload().then(_response => {
      ok(zuploader.getContentMigration.calledOnce, 'got content migration')
      done()
    })
  })
})

test('tracks progress', function (assert) {
  const done = assert.async()
  const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
  sandbox.stub(zuploader, 'trackProgress')

  moxios.wait(() => {
    return zuploader.upload().then(_response => {
      ok(zuploader.trackProgress.calledOnce, 'got track progress')
      done()
    })
  })
})

test('roundProgress returns back rounded values', function () {
  const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
  sandbox.stub(zuploader, 'getProgress').returns(0.18) // progress is [0 .. 1]
  equal(zuploader.roundProgress(), 18)
})

test('roundProgress returns back values no greater than 100', function () {
  const zuploader = new ZipUploader(mockFileOptions(), folder, '1', 'courses')
  sandbox.stub(zuploader, 'getProgress').returns(1.1) // something greater than 100%
  equal(zuploader.roundProgress(), 100)
})

test('getFileName returns back the option name if one exists', function () {
  const options = mockFileOptions()
  options.name = 'use this one'
  const zuploader = new ZipUploader(options, folder, '1', 'courses')
  equal(zuploader.getFileName(), 'use this one')
})

test('getFileName returns back the actual file if no optinal name is given', function () {
  const options = mockFileOptions()
  const zuploader = new ZipUploader(options, folder, '1', 'courses')
  equal(zuploader.getFileName(), 'foo')
})
