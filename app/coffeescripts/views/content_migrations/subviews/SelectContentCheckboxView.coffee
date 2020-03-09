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
  'Backbone'
  'jst/content_migrations/subviews/SelectContentCheckbox'
  'i18n!select_content_checkbox'
], ($, Backbone, template, I18n) -> 
  class SelectContentCheckbox extends Backbone.View
    template: template

    events: 
      'click [name=selective_import]' : 'updateModel'

    updateModel: (event) -> 
      @model.set 'selective_import', $(event.currentTarget).val() == "true"

    # validations this form element. This validates method is a convention used 
    # for all sub views.
    # ie:
    #   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
    # -----------------------------------------------------------------------
    # @expects void
    # @returns void | object (error)
    # @api private

    validations: -> 
      errors = {}
      @model.set 'selective_import', true if ENV.HIDE_DESTRUCTIVE_COURSE_OPTIONS
      selective_import = @model.get('selective_import')

      if selective_import == null || selective_import == undefined
        errors.selective_import = [
          type: "required"
          message: I18n.t('select_content_error', "You must choose a content option")
        ]

      errors
