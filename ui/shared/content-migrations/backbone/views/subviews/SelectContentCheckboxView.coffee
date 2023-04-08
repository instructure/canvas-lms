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

import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/SelectContentCheckbox.handlebars'
import ImportBlueprintSettingsView from '../../../../../features/content_migrations/backbone/views/subviews/ImportBlueprintSettingsView'
import {useScope as useI18nScope} from '@canvas/i18n'

I18n = useI18nScope('select_content_checkbox')

export default class SelectContentCheckbox extends Backbone.View
  template: template
  importBlueprintSettings: new ImportBlueprintSettingsView
                           model: @model

  @child 'importBlueprintSettings', '.importBlueprintSettings'

  events:
    'click [name=selective_import]' : 'updateModel'

  initialize: () ->
    super
    @importBlueprintSettings.model = @model

  updateModel: (event) ->
    @model.set 'selective_import', $(event.currentTarget).val() == "true"
    @importBlueprintSettings.importTypeSelected($(event.currentTarget).val() == "true")

  courseSelected: (course) ->
    @importBlueprintSettings.courseSelected(course)

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
    selective_import = @model.get('selective_import')

    if selective_import == null || selective_import == undefined
      errors.selective_import = [
        type: "required"
        message: I18n.t('select_content_error', "You must choose a content option")
      ]

    errors
