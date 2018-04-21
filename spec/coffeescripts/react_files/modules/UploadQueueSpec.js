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

import UploadQueue from 'compiled/react_files/modules/UploadQueue'
import $ from 'jquery'

const mockFileOptions = (name = 'foo', type = 'bar') => ({
  file: {
    size: 1,
    name,
    type
  }
})
const mockFileUploader = file => ({
  upload() {
    const promise = $.Deferred()
    window.setTimeout(() => promise.resolve(), 2)
    return promise
  },
  file
})
const mockAttemptNext = function() {}

QUnit.module('UploadQueue', {
  setup() {
    this.queue = UploadQueue
  },
  teardown() {
    this.queue.flush()
    return delete this.queue
  }
})

test('Enqueues uploads, flush clears', function() {
  const original = this.queue.attemptNextUpload
  this.queue.attemptNextUpload = mockAttemptNext
  this.queue.enqueue(mockFileOptions())
  equal(this.queue.length(), 1)
  this.queue.enqueue(mockFileOptions())
  equal(this.queue.length(), 2)
  this.queue.flush()
  equal(this.queue.length(), 0)
  this.queue.attemptNextUpload = original
})

test('processes one upload at a time', function(assert) {
  const done = assert.async()
  const original = this.queue.createUploader
  this.queue.createUploader = mockFileUploader
  this.queue.enqueue('foo')
  this.queue.enqueue('bar')
  this.queue.enqueue('baz')
  equal(this.queue.length(), 2) // first item starts, remainder are waiting
  window.setTimeout(() => {
    equal(this.queue.length(), 1) // after two more ticks there is only one remaining
    done();
  }, 2)
  this.queue.createUploader = original
})

test('dequeue removes top of the queue', function() {
  const original = this.queue.attemptNextUpload
  this.queue.attemptNextUpload = mockAttemptNext
  const foo = mockFileOptions('foo')
  this.queue.enqueue(foo)
  equal(this.queue.length(), 1)
  this.queue.enqueue(mockFileOptions('zoo'))
  equal(this.queue.length(), 2)
  equal(this.queue.dequeue().options, foo)
  this.queue.attemptNextUpload = original
})

test('getAllUploaders includes the current uploader', function() {
  const original = this.queue.attemptNextUpload
  this.queue.attemptNextUpload = mockAttemptNext
  this.queue.flush()
  const foo = mockFileOptions('foo')
  this.queue.enqueue(foo)
  equal(this.queue.length(), 1)
  this.queue.enqueue(mockFileOptions('zoo'))
  equal(this.queue.length(), 2)
  equal(this.queue.length(), 2)
  const sentinel = mockFileOptions('sentinel')
  this.queue.currentUploader = sentinel
  const all = this.queue.getAllUploaders()
  equal(all.length, 3)
  equal(all.indexOf(sentinel), 0)
  this.queue.currentUploader = undefined
  this.queue.attemptNextUpload = original
})
