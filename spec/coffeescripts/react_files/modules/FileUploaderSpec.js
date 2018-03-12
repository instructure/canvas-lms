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

import FileUploader from 'compiled/react_files/modules/FileUploader'
import * as uploader from 'jsx/shared/upload_file'
import $ from 'jquery'
import 'jquery.ajaxJSON'

const mockFileOptions = function(name, type, size) {
  let fileOptions
  return (fileOptions = {
    file: {
      name,
      type,
      size
    }
  })
}

QUnit.module('FileUploader', {
  setup() {
    const folder = {id: 1}
    this.uploader = new FileUploader(mockFileOptions('foo', 'bar', 1), folder)
  },
  teardown() {
    delete this.uploader
  }
})

test('posts to the files endpoint to kick off upload', function() {
  this.stub($, 'ajaxJSON')
  this.uploader.upload()
  equal($.ajaxJSON.calledWith('/api/v1/folders/1/files'), true, 'kicks off upload')
})

test('stores params from preflight for actual upload', function() {
  const server = sinon.fakeServer.create()
  server.respondWith('POST', '/api/v1/folders/1/files', [
    200,
    {'Content-Type': 'application/json'},
    '{"upload_url": "/upload/url", "upload_params": {"key": "value"}}'
  ])
  this.stub(this.uploader, '_actualUpload')
  this.uploader.upload()
  server.respond()
  equal(this.uploader.uploadData.upload_url, '/upload/url')
  equal(this.uploader.uploadData.upload_params.key, 'value')
  server.restore()
})

test('completes upload after preflight', function(assert) {
  const done = assert.async()
  const server = sinon.fakeServer.create()
  server.respondWith('POST', '/api/v1/folders/1/files', [
    200,
    {'Content-Type': 'application/json'},
    '{"upload_url": "/s3/upload/url", "upload_params": {"success_url": "/success/url"}}'
  ])
  this.stub(this.uploader, 'addFileToCollection')
  this.stub(uploader, 'completeUpload').returns(Promise.resolve({id: 's3-id'}))
  const promise = this.uploader.upload()
  server.respond()
  return promise.then(() => {
    ok(this.uploader.addFileToCollection.calledWith({id: 's3-id'}), 'got metadata from success_url')
    server.restore()
    done()
  })
})

test('roundProgress returns back rounded values', function() {
  this.stub(this.uploader, 'getProgress').returns(0.18) // progress is [0 .. 1]
  equal(this.uploader.roundProgress(), 18)
})

test('roundProgress returns back values no greater than 100', function() {
  this.stub(this.uploader, 'getProgress').returns(1.1) // something greater than 100%
  equal(this.uploader.roundProgress(), 100)
})

test('getFileName returns back the option name if one exists', function() {
  const folder = {id: 1}
  const options = mockFileOptions('foo', 'bar', 1)
  options.name = 'use this one'
  this.uploader = new FileUploader(options, folder)
  equal(this.uploader.getFileName(), 'use this one')
})

test('getFileName returns back the actual file if no optinal name is given', function() {
  const folder = {id: 1}
  const options = mockFileOptions('foo', 'bar', 1)
  this.uploader = new FileUploader(options, folder)
  equal(this.uploader.getFileName(), 'foo')
})
