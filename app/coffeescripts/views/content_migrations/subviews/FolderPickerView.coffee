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
  'jst/content_migrations/subviews/FolderPicker'
  'i18n!content_migrations'
], (Backbone, template, I18n) ->
  class FolderPickerView extends Backbone.View
    template: template
    @optionProperty 'folderOptions'

    els:
      ".migrationUploadTo" : "$migrationUploadTo"

    events:
      "change .migrationUploadTo" : "setAttributes"

    setAttributes: (event) ->
      @model.set('settings', folder_id: @$migrationUploadTo.val() if @$migrationUploadTo.val())

    toJSON: (json) ->
      json = super
      json.folderOptions = @folderOptions || ENV.FOLDER_OPTIONS
      json

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
      settings = @model.get('settings')

      unless settings?.folder_id
        errors.migrationUploadTo = [
          type: "required"
          message: I18n.t("You must select a folder to upload your migration to")
        ]

      errors

