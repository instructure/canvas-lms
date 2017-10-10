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
  'i18n!react_files'
  'jquery'
  'compiled/models/File'
  './BaseUploader'
  'jquery.ajaxJSON'
], (I18n, $, BBFile, BaseUploader) ->

  class FileUploader extends BaseUploader

    onUploadPosted: (event) =>
      if event.target.status >= 400
        @deferred.reject(event.target.status)
        return

      url = if event.target.status == 201
        $.parseJSON(event.target.response).location
      else
        @uploadData.upload_params.success_url

      if url
        $.getJSON(url).then (results) =>
          f = @addFileToCollection(results)
          @deferred.resolve(f)
      else
        results = $.parseJSON(event.target.response)
        f = @addFileToCollection(results)
        @deferred.resolve(f)

    addFileToCollection: (attrs) =>
      uploadedFile = new BBFile(attrs, 'no/url/needed/') #we've already done the upload, no preflight needed
      @folder.files.add(uploadedFile)

      #remove old version if it was just overwritten
      if @options.dup == 'overwrite'
        name = @options.name || @file.name
        previous = @folder.files.findWhere({display_name: name})
        @folder.files.remove(previous) if previous

      uploadedFile
