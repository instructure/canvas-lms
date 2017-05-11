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
], ($) ->

  ###
  # builds and interacts with hidden input file for kaltura uploads
  ###
  class FileInputManager

    constructur: ->
      @allowedMedia = ['audio', 'video']

    resetFileInput: (callback, id, parentId) =>
      id ||= 'file_upload'
      parentId ||= '#media_upload_settings'
      if @$fileInput
        @$fileInput.off 'change', callback
        @$fileInput.remove()
      fileInputHtml = "<input id='#{id}' type='file' style='display: none;'>"
      $(parentId).append(fileInputHtml)
      @$fileInput = $("##{id}")
      @$fileInput.on 'change', callback

    setUpInputTrigger: (el, mediaType) ->
      $(el).on 'click', (e) =>
        @allowedMedia = mediaType
        @$fileInput.click()

    getSelectedFile: ->
      @$fileInput.get()[0].files[0]

