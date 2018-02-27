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
  'underscore'
  './FileUploader'
  './ZipUploader'
], (_, FileUploader, ZipUploader) ->

  class UploadQueue
    _uploading: false
    _queue: []

    length: ->
      @_queue.length

    flush: ->
      @_queue = []

    getAllUploaders: ->
      all = @_queue.slice()
      all = all.concat(@currentUploader) if @currentUploader
      all.reverse()

    getCurrentUploader: ->
      @currentUploader

    onChange: ->
      #noop, set by components who care about it

    createUploader: (fileOptions, folder, contextId, contextType) ->
      uploader = if fileOptions.expandZip
        new ZipUploader(fileOptions, folder, contextId, contextType)
      else
        new FileUploader(fileOptions, folder)
      uploader.cancel = =>
        uploader._xhr?.abort()
        @_queue = _.without(@_queue, uploader)
        @currentUploader = null if @currentUploader is uploader
        @onChange()

      uploader

    enqueue: (fileOptions, folder, contextId, contextType) ->
      uploader = @createUploader(fileOptions, folder, contextId, contextType)
      @_queue.push uploader
      @attemptNextUpload()

    dequeue: ->
      firstNonErroredUpload = _.find @_queue, (upload) -> !upload.error
      @_queue = _.without(@_queue, firstNonErroredUpload)
      firstNonErroredUpload

    pageChangeWarning: ->
      "You currently have uploads in progress. If you leave this page, the uploads will stop."

    attemptNextUpload: ->
      @onChange()
      return if @_uploading || @_queue.length == 0
      @currentUploader = uploader = @dequeue()
      if uploader
        @onChange()
        @_uploading = true
        $(window).on 'beforeunload', @pageChangeWarning

        promise = uploader.upload()
        promise.fail (failReason) =>
          # put it back in the queue unless the user aborted it
          unless failReason is 'user_aborted_upload'
            @_queue.unshift(uploader)

        promise.always =>
          @_uploading = false
          @currentUploader = null
          $(window).off 'beforeunload', @pageChangeWarning
          @onChange()
          @attemptNextUpload()

  new UploadQueue()
