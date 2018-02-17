#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'underscore'
  '../models/FilesystemObject'
  'jsx/shared/upload_file'
  'jquery.ajaxJSON'
], ($, _, FilesystemObject, uploader) ->

  # Simple model for creating an attachment in canvas
  #
  # Required stuff (or uploads won't work):
  #
  # 1. you need to pass a preflightUrl in the options
  # 2. at some point, you need to do: `model.set('file', <input>)`
  #    where <input> is the DOM node (not $-wrapped) of the file input
  class File extends FilesystemObject

    url: ->
      if @isNew()
        # if it is new, fall back to Backbone's default behavior of using
        # the url of the collection this model belongs to.
        # aka: POST /api/v1/folders/:folder_id/files (to create)
        super
      else
        # for GET, PUT, and DELETE, our API expects "/api/v1/files/:file_id"
        # not "/api/v1/folders/:folder_id/files/:file_id" which is what
        # backbone would do by default.
        "/api/v1/files/#{@id}"

    initialize: (attributes, options = {}) ->
      @preflightUrl = options.preflightUrl
      super

    save: (attrs = {}, options = {}) ->
      return super unless @get('file')
      @set attrs

      dfrd = $.Deferred()
      onUpload = (data) =>
        @set(data)
        dfrd.resolve(data)
        options.success?(data)
      onError = (error) =>
        dfrd.reject(error)
        options.error?(error)

      file = @get('file')
      filename = (file.value || file.name).split(/[\/\\]/).pop()
      file = file.files[0]
      preflightData =
        name: filename
        on_duplicate: 'rename'
      uploader.uploadFile(@preflightUrl, preflightData, file)
        .then(onUpload)
        .catch(onError)

      dfrd

    isFile: true

    toJSON: ->
      return super unless @get('file')
      _.pick(@attributes, 'file', _.keys(@uploadParams ? {})...)

    present: ->
      _.clone(@attributes)

    externalToolEnabled: (tool) =>
      if tool.accept_media_types && tool.accept_media_types.length > 0
        content_type = @get('content-type')
        _.find(tool.accept_media_types.split(","), (t) ->
          regex = new RegExp("^#{t.replace('*', '.*')}$")
          content_type.match(regex)
        )
      else
        true
