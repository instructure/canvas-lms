/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import UploadQueue from '../UploadQueue'
import sinon from 'sinon'

const mockFileOptions = (name = 'foo', type = 'bar', expandZip = false) => ({
  file: {
    size: 1,
    name,
    type,
  },
  expandZip,
})

const mockFileUploader = (file, error) => ({
  upload() {
    this.inFlight = true
    return new Promise(resolve => {
      window.setTimeout(() => {
        this.inFlight = false
        resolve()
      }, 2)
    })
  },
  reset() {
    this.error = null
  },
  inFlight: false,
  error,
  file,
})

const mockAttemptNext = function () {}

describe('UploadQueue', () => {
  beforeEach(() => {
    UploadQueue.flush()
    UploadQueue._uploading = false
    UploadQueue._queue = []
    UploadQueue.currentUploader = null
  })

  afterEach(() => {
    UploadQueue.flush()
    UploadQueue._uploading = false
    UploadQueue._queue = []
    UploadQueue.currentUploader = null
  })

  test('enqueues uploads, flush clears', () => {
    const original = UploadQueue.attemptNextUpload
    UploadQueue.attemptNextUpload = mockAttemptNext
    UploadQueue.enqueue(mockFileOptions())
    expect(UploadQueue.length()).toBe(1)
    UploadQueue.enqueue(mockFileOptions())
    expect(UploadQueue.length()).toBe(2)
    UploadQueue.flush()
    expect(UploadQueue.length()).toBe(0)
    UploadQueue.attemptNextUpload = original
  })

  test('processes one upload at a time', done => {
    const original = UploadQueue.createUploader
    UploadQueue.createUploader = mockFileUploader
    UploadQueue.enqueue('foo')
    UploadQueue.enqueue('bar')
    UploadQueue.enqueue('baz')
    expect(UploadQueue.length()).toBe(2) // first item starts, remainder are waiting
    window.setTimeout(() => {
      expect(UploadQueue.length()).toBe(1) // after two more ticks there is only one remaining
      done()
    }, 2)
    UploadQueue.createUploader = original
  })

  test('dequeue removes top of the queue', () => {
    const original = UploadQueue.attemptNextUpload
    UploadQueue.attemptNextUpload = mockAttemptNext
    const foo = mockFileOptions('foo')
    UploadQueue.enqueue(foo)
    expect(UploadQueue.length()).toBe(1)
    UploadQueue.enqueue(mockFileOptions('zoo'))
    expect(UploadQueue.length()).toBe(2)
    expect(UploadQueue.dequeue().options).toBe(foo)
    UploadQueue.attemptNextUpload = original
  })

  test('getAllUploaders includes the current uploader', () => {
    const original = UploadQueue.attemptNextUpload
    UploadQueue.attemptNextUpload = mockAttemptNext
    UploadQueue.flush()
    const foo = mockFileOptions('foo')
    UploadQueue.enqueue(foo)
    expect(UploadQueue.length()).toBe(1)
    UploadQueue.enqueue(mockFileOptions('zoo'))
    expect(UploadQueue.length()).toBe(2)
    const sentinel = mockFileOptions('sentinel')
    UploadQueue.currentUploader = sentinel
    const all = UploadQueue.getAllUploaders()
    expect(all.length).toBe(3)
    expect(all.indexOf(sentinel)).toBe(0)
    UploadQueue.currentUploader = undefined
    UploadQueue.attemptNextUpload = original
  })

  test('calls onChange', () => {
    const onChangeSpy = sinon.spy(UploadQueue, 'onChange')
    const callbackSpy = sinon.spy()
    UploadQueue.addChangeListener(callbackSpy)
    const foo = mockFileOptions('foo', 'bar', true)
    const uploader = UploadQueue.createUploader(foo)

    uploader.onProgress()
    expect(onChangeSpy.calledOnce).toBe(true)
    expect(callbackSpy.calledWith(UploadQueue)).toBe(true)
    expect(callbackSpy.calledOnce).toBe(true)
  })

  test('can retry a specific uploader', async () => {
    const foo = mockFileUploader('foo', 'whoops')
    const zoo = mockFileUploader('zoo', 'failed')
    UploadQueue._queue.push(foo)
    UploadQueue._queue.push(zoo)
    await UploadQueue.attemptThisUpload(foo)
    expect(UploadQueue.length()).toBe(1)
  })
})
