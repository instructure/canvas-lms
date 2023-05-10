/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/SelectContentCheckbox.handlebars'
import ImportBlueprintSettingsView from './ImportBlueprintSettingsView'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('select_content_checkbox')

extend(SelectContentCheckbox, Backbone.View)

function SelectContentCheckbox() {
  return SelectContentCheckbox.__super__.constructor.apply(this, arguments)
}

SelectContentCheckbox.prototype.template = template

SelectContentCheckbox.prototype.importBlueprintSettings = new ImportBlueprintSettingsView({
  model: SelectContentCheckbox.model,
})

SelectContentCheckbox.child('importBlueprintSettings', '.importBlueprintSettings')

SelectContentCheckbox.prototype.events = {
  'click [name=selective_import]': 'updateModel',
}

SelectContentCheckbox.prototype.initialize = function () {
  SelectContentCheckbox.__super__.initialize.apply(this, arguments)
  return (this.importBlueprintSettings.model = this.model)
}

SelectContentCheckbox.prototype.updateModel = function (event) {
  this.model.set('selective_import', $(event.currentTarget).val() === 'true')
  return this.importBlueprintSettings.importTypeSelected($(event.currentTarget).val() === 'true')
}

SelectContentCheckbox.prototype.courseSelected = function (course) {
  return this.importBlueprintSettings.courseSelected(course)
}

// validations this form element. This validates method is a convention used
// for all sub views.
// ie:
//   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
// -----------------------------------------------------------------------
// @expects void
// @returns void | object (error)
// @api private
SelectContentCheckbox.prototype.validations = function () {
  const errors = {}
  const selective_import = this.model.get('selective_import')
  // eslint-disable-next-line no-void
  if (selective_import === null || selective_import === void 0) {
    errors.selective_import = [
      {
        type: 'required',
        message: I18n.t('select_content_error', 'You must choose a content option'),
      },
    ]
  }
  return errors
}

export default SelectContentCheckbox
