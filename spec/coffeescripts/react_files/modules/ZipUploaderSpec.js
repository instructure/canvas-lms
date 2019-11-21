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

import ZipUploader from 'compiled/react_files/modules/ZipUploader'
import * as uploader from 'jsx/shared/upload_file'
import $ from 'jquery'
import 'jquery.ajaxJSON'

const mockFileOptions = function(name, type, size) {
  return {
    file: {
      name,
      type,
      size
    }
  }
}

QUnit.module('ZipUploader', {
  setup() {
    const folder = {id: 1}
    this.uploader = new ZipUploader(mockFileOptions('foo', 'bar', 1), folder, '1', 'courses')
  },
  teardown() {
    delete this.uploader
  }
})

test('posts to the files endpoint to kick off upload', function() {
  sandbox.stub($, 'ajaxJSON')
  this.uploader.upload()
  equal($.ajaxJSON.calledWith('/api/v1/courses/1/content_migrations'), true, 'kicks off upload')
})

test('stores params from preflight for actual upload', function() {
  const server = sinon.fakeServer.create()
  const payload = {
    pre_attachment: {
      upload_url: '/upload/url',
      upload_params: {
        key: 'value'
      }
    },
    id: 1
  }
  server.respondWith('POST', '/api/v1/courses/1/content_migrations', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(payload)
  ])
  sandbox.stub(this.uploader, '_actualUpload')
  this.uploader.upload()
  server.respond()
  equal(this.uploader.uploadData.upload_url, '/upload/url')
  equal(this.uploader.uploadData.upload_params.key, 'value')
  server.restore()
})

test('completes upload after preflight', function(assert) {
  const done = assert.async()
  const server = sinon.fakeServer.create()
  const response = {
    pre_attachment: {
      upload_url: '/s3/upload/url',
      upload_params: {
        success_url: '/success/url'
      }
    },
    id: 1
  }
  server.respondWith('POST', '/api/v1/courses/1/content_migrations', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(response)
  ])
  sandbox.stub(this.uploader, 'getContentMigration')
  sandbox.stub(uploader, 'completeUpload').returns(Promise.resolve({id: 's3-id'}))
  const promise = this.uploader.upload()
  server.respond()
  setTimeout(() => {
    this.uploader.deferred.resolve()
  }, 100)
  return promise.then(() => {
    ok(this.uploader.getContentMigration.calledOnce, 'got content migration')
    server.restore()
    done()
  })
})

test('tracks progress', function(assert) {
  const done = assert.async()
  const server = sinon.fakeServer.create()
  const post_response = {
    pre_attachment: {
      upload_url: '/s3/upload/url',
      upload_params: {
        success_url: '/success/url'
      }
    },
    id: 1
  }
  server.respondWith('POST', '/api/v1/courses/1/content_migrations', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(post_response)
  ])

  const cm_response = {
    progress_url: '/api/v1/progress/1'
  }

  const running_progress_response = {
    id: '1',
    context_id: '1',
    context_type: 'ContentMigration',
    user_id: '1',
    tag: 'content_migration',
    completion: 90.0,
    workflow_state: 'running',
    url: '/api/v1/progress/1'
  }

  const completed_progress_response = {
    id: '1',
    context_id: '1',
    context_type: 'ContentMigration',
    user_id: '1',
    tag: 'content_migration',
    completion: 100.0,
    workflow_state: 'completed',
    url: '/api/v1/progress/1'
  }

  sandbox.stub(this.uploader, 'trackProgress')
  sandbox.stub(uploader, 'completeUpload').returns(Promise.resolve({id: 's3-id'}))
  const promise = this.uploader.upload()

  let count = 0
  const getJSONstub = sinon.stub($, 'getJSON').callsFake(url => {
    if (url === '/api/v1/courses/1/content_migrations/1') {
      return Promise.resolve(cm_response)
    } else if (url === '/api/v1/progress/1' && count === 0) {
      count++
      return Promise.resolve(running_progress_response)
    } else if (url === '/api/v1/progress/1') {
      return Promise.resolve(completed_progress_response)
    }
  })

  setTimeout(() => {
    this.uploader.deferred.resolve()
  }, 100)
  server.respond()

  return promise.then(() => {
    ok(this.uploader.trackProgress.calledOnce, 'got track progress')
    server.restore()
    getJSONstub.restore()
    done()
  })
})

test('roundProgress returns back rounded values', function() {
  sandbox.stub(this.uploader, 'getProgress').returns(0.18) // progress is [0 .. 1]
  equal(this.uploader.roundProgress(), 18)
})

test('roundProgress returns back values no greater than 100', function() {
  sandbox.stub(this.uploader, 'getProgress').returns(1.1) // something greater than 100%
  equal(this.uploader.roundProgress(), 100)
})

test('getFileName returns back the option name if one exists', function() {
  const folder = {id: 1}
  const options = mockFileOptions('foo', 'bar', 1)
  options.name = 'use this one'
  this.uploader = new ZipUploader(options, folder)
  equal(this.uploader.getFileName(), 'use this one')
})

test('getFileName returns back the actual file if no optinal name is given', function() {
  const folder = {id: 1}
  const options = mockFileOptions('foo', 'bar', 1)
  this.uploader = new ZipUploader(options, folder)
  equal(this.uploader.getFileName(), 'foo')
})
