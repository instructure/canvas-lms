#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'compiled/react_files/modules/UploadQueue'
  'jquery'
], (UploadQueue, $) ->

  mockFileOptions = (name='foo', type='bar') ->
      file:
        size: 1
        name: name
        type: type


  mockFileUploader = (file) ->
    {
      upload: ->
        promise = $.Deferred()
        window.setTimeout ->
          promise.resolve()
        , 2
        promise
      file: file
    }

  mockAttemptNext = ->
    #noop

  QUnit.module 'UploadQueue',
    setup: ->
      @queue = UploadQueue

    teardown: ->
      @queue.flush()
      delete @queue


  test 'Enqueues uploads, flush clears', ->
    original = @queue.attemptNextUpload
    @queue.attemptNextUpload = mockAttemptNext

    @queue.enqueue mockFileOptions()
    equal(@queue.length(), 1)
    @queue.enqueue mockFileOptions()
    equal(@queue.length(), 2)
    @queue.flush()
    equal(@queue.length(), 0)

    @queue.attemptNextUpload = original


  test 'processes one upload at a time', ->
    expect(2)
    original = @queue.createUploader
    @queue.createUploader = mockFileUploader

    @queue.enqueue 'foo'
    @queue.enqueue 'bar'
    @queue.enqueue 'baz'
    equal(@queue.length(), 2) # first item starts, remainder are waitingj
    stop()
    window.setTimeout =>
      start()
      equal(@queue.length(), 1) #after two more ticks there is only one remaining
    , 2

    @queue.createUploader = original

  test 'dequeue removes top of the queue', ->
    original = @queue.attemptNextUpload
    @queue.attemptNextUpload = mockAttemptNext

    foo = mockFileOptions('foo')
    @queue.enqueue foo
    equal(@queue.length(), 1)
    @queue.enqueue mockFileOptions('zoo')
    equal(@queue.length(), 2)
    equal(@queue.dequeue().options, foo)

    @queue.attemptNextUpload = original

  test 'getAllUploaders includes the current uploader', ->
    original = @queue.attemptNextUpload
    @queue.attemptNextUpload = mockAttemptNext
    @queue.flush()

    foo = mockFileOptions('foo')
    @queue.enqueue foo
    equal(@queue.length(), 1)
    @queue.enqueue mockFileOptions('zoo')
    equal(@queue.length(), 2)

    equal @queue.length(), 2
    sentinel = mockFileOptions('sentinel')
    @queue.currentUploader = sentinel

    all = @queue.getAllUploaders()
    equal all.length, 3
    equal all.indexOf(sentinel), 0

    @queue.currentUploader = undefined
    @queue.attemptNextUpload = original
