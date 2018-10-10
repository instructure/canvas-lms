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
  'i18n!context_modules'
  'jquery'
  'Backbone'
  'jst/modules/ProgressionModuleView'
], (I18n, $, Backbone, template) ->

  class ProgressionModuleView extends Backbone.View

    tagName: 'li'
    className: 'progressionModule'
    template: template

    statuses:
      "started"   : I18n.t("module_started", "In Progress")
      "completed" : I18n.t("module_complete", "Complete")
      "unlocked"  : I18n.t("module_unlocked", "Unlocked")
      "locked"    : I18n.t("module_locked", "Locked")

    iconClasses:
      'ModuleItem'          : "icon-module"
      'File'                : "icon-paperclip"
      'Page'                : "icon-document"
      'Discussion'          : "icon-discussion"
      'Assignment'          : "icon-assignment"
      'Quiz'                : "icon-quiz"
      'ExternalTool'        : "icon-link"
      'Lti::MessageHandler' : "icon-link"

    toJSON: ->
      json = super
      json.student_id = @model.collection.student_id
      json.status_text = @statuses[json.state]
      json[json.state] = true

      for item in json.items
        item.icon_class = @iconClasses[item.type] || @iconClasses['ModuleItem']
      json

    afterRender: ->
      super
      @model.collection.syncHeight()
