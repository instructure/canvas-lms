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
import Backbone from '@canvas/backbone'
import template from './ImportBlueprintSettingsView.handlebars'

extend(ImportBlueprintSettingsView, Backbone.View)

function ImportBlueprintSettingsView() {
  this.updateSetting = this.updateSetting.bind(this)
  this.importTypeSelected = this.importTypeSelected.bind(this)
  this.courseSelected = this.courseSelected.bind(this)
  this.afterRender = this.afterRender.bind(this)
  this.allContent = false
  return ImportBlueprintSettingsView.__super__.constructor.apply(this, arguments)
}

ImportBlueprintSettingsView.prototype.template = template

ImportBlueprintSettingsView.optionProperty('blueprintSelected')

ImportBlueprintSettingsView.prototype.els = {
  '#importBlueprintSettingsContainer': '$container',
}

ImportBlueprintSettingsView.prototype.events = {
  'change #importBlueprintSettingsCheckbox': 'updateSetting',
}

ImportBlueprintSettingsView.prototype.afterRender = function () {
  return this.$container.showIf(this.blueprintSelected && this.allContent)
}

ImportBlueprintSettingsView.prototype.courseSelected = function (course) {
  this.blueprintSelected = course.blueprint
  return this.render()
}

ImportBlueprintSettingsView.prototype.importTypeSelected = function (selective) {
  this.allContent = !selective
  return this.render()
}

ImportBlueprintSettingsView.prototype.updateSetting = function (event) {
  const settings = this.model.get('settings') || {}
  settings.import_blueprint_settings = event.target.checked
  return this.model.set('settings', settings)
}

export default ImportBlueprintSettingsView
