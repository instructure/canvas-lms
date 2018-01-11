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
  'jquery'
  'jquery.ajaxJSON'
], ($) ->

  # Base uploader with common api between File and Zip uploads
  # (where zip is expanded)
  class BaseUploader

    constructor: (fileOptions, folder) ->
      @file = fileOptions.file
      @options = fileOptions
      @folder = folder
      @progress = 0

    onProgress: (percentComplete, file) ->
      #noop will be set up a level

    createFormData: () ->
      data = @uploadData.upload_params
      formData = new FormData()
      Object.keys(data).forEach (key) ->
        formData.append(key, data[key])
      formData.append('file', @file)
      formData

    createPreFlightParams: ->
      params =
        name: @options.name || @file.name
        size: @file.size
        content_type: @file.type
        on_duplicate: @options.dup || 'rename'
        parent_folder_id: @folder.id
        no_redirect: true

    getPreflightUrl: ->
      "/api/v1/folders/#{@folder.id}/files"

    onPreflightComplete: (data) =>
      @uploadData = data
      @_actualUpload()

    # kickoff / preflight upload process
    upload: ->
      @deferred = $.Deferred()
      @deferred.fail (failReason) =>
        @error = failReason
        $.screenReaderFlashError(@error.message) if @error?.message

      $.ajaxJSON(@getPreflightUrl(), 'POST', @createPreFlightParams(), @onPreflightComplete, @deferred.reject)
      @deferred.promise()

    #actual upload based on kickoff / preflight
    _actualUpload: () ->
      @_xhr = new XMLHttpRequest
      @_xhr.upload.addEventListener('progress', @trackProgress, false)
      @_xhr.onload = @onUploadPosted
      @_xhr.onerror = @deferred.reject
      @_xhr.onabort = @deferred.reject
      @_xhr.open 'POST', @uploadData.upload_url, true
      @_xhr.send @createFormData()

    # when using s3 uploads you now need to manually hit the success_url
    # when using local uploads you have already been auto-redirected (even
    # though we requested no_redirect) to the succes_url at this point
    onUploadPosted: (event) =>
      # should be implemented in extensions

    trackProgress: (e) =>
      @progress = (e.loaded/ e.total)
      @onProgress(@progress, @file)

    getProgress: ->
      @progress

    roundProgress: ->
      value = @getProgress() || 0
      Math.min(Math.round(value * 100), 100)

    getFileName: ->
      @options.name || @file.name

    abort: ->
      @_xhr.abort()
      @deferred.reject('user_aborted_upload')
