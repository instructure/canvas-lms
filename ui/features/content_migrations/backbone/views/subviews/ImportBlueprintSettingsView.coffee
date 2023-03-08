#
# Copyright (C) 2022 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/ImportBlueprintSettingsView.handlebars'

export default class ImportBlueprintSettingsView extends Backbone.View
  template: template

  @optionProperty 'blueprintSelected'
  allContent = false

  els:
    '#importBlueprintSettingsContainer': '$container'

  events:
    'change #importBlueprintSettingsCheckbox': 'updateSetting'

  afterRender: =>
    @$container.showIf(@blueprintSelected && @allContent)

  courseSelected: (course) =>
    @blueprintSelected = course.blueprint
    @render()

  importTypeSelected: (selective) =>
    @allContent = !selective
    @render()

  updateSetting: (event) =>
    settings = @model.get('settings') || {}
    settings.import_blueprint_settings = event.target.checked
    @model.set('settings', settings)

