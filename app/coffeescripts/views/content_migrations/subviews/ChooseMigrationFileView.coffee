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
  'Backbone'
  'jst/content_migrations/subviews/ChooseMigrationFile'
  'i18n!content_migrations'
], (Backbone, template, I18n) ->
  class ChooseMigrationFile extends Backbone.View
    template: template

    els: 
      '#migrationFileUpload' : '$migrationFileUpload'

    events: 
      'change #migrationFileUpload' : 'setAttributes'

    @optionProperty 'fileSizeLimit'

    setAttributes: (event) -> 
      filename = event.target.value.replace(/^.*\\/, '')
      fileElement = @$migrationFileUpload[0]

      @model.set('pre_attachment', {
        file_size: @fileSize(fileElement),
        name: filename,
        fileElement: fileElement,
        no_redirect: true
      })
    
    # TODO 
    #   Handle cases for file size from IE browsers
    # @api private

    fileSize: (fileElement) -> fileElement.files?[0].size

    # Validates this form element. This validates method is a convention used 
    # for all sub views.
    # ie:
    #   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
    # -----------------------------------------------------------------------
    # @expects void
    # @returns void | object (error)
    # @api private

    validations: -> 
      errors = {}
      preAttachment = @model.get('pre_attachment')
      fileErrors = []
      fileElement = preAttachment?.fileElement

      unless preAttachment?.name && fileElement
        fileErrors.push
                    type: "required"
                    message: I18n.t("file_required", "You must select a file to import content from")

      if @fileSize(fileElement) > @fileSizeLimit
        fileErrors.push
                    type: "upload_limit_exceeded"
                    message: I18n.t("file_too_large", "Your migration cannot exceed %{file_size}", file_size: @humanReadableSize(@fileSizeLimit))

      errors.file = fileErrors if fileErrors.length
      errors

    # Converts a size to a human readible string. "size" should be in
    # bytes to stay consistent with the javascript files api. 
    # --------------------------------------------------------------
    # @expects size (bytes | string(in bytes))
    # @returns readableString (string)
    # @api private

    humanReadableSize: (size) -> 
      size = parseFloat size #Ensure we are working with a number
      units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
      i = 0
      while(size >= 1024) 
          size /= 1024
          ++i

      size.toFixed(1) + ' ' + units[i]
