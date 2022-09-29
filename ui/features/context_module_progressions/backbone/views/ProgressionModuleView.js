//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as useI18nScope} from '@canvas/i18n'

import Backbone from '@canvas/backbone'
import template from '../../jst/ProgressionModuleView.handlebars'

const I18n = useI18nScope('context_modules')

let ProgressionModuleView

export default ProgressionModuleView = (function () {
  ProgressionModuleView = class ProgressionModuleView extends Backbone.View {
    static initClass() {
      this.prototype.tagName = 'li'
      this.prototype.className = 'progressionModule'
      this.prototype.template = template

      this.prototype.statuses = {
        started: I18n.t('module_started', 'In Progress'),
        completed: I18n.t('module_complete', 'Complete'),
        unlocked: I18n.t('module_unlocked', 'Unlocked'),
        locked: I18n.t('module_locked', 'Locked'),
      }

      this.prototype.iconClasses = {
        ModuleItem: 'icon-module',
        File: 'icon-paperclip',
        Page: 'icon-document',
        Discussion: 'icon-discussion',
        Assignment: 'icon-assignment',
        Quiz: 'icon-quiz',
        ExternalTool: 'icon-link',
        'Lti::MessageHandler': 'icon-link',
      }
    }

    toJSON() {
      const json = super.toJSON(...arguments)
      json.student_id = this.model.collection.student_id
      json.status_text = this.statuses[json.state]
      json[json.state] = true

      json.show_items = json.state === 'started' && json.items
      if (json.show_items) {
        for (const item of json.items) {
          item.icon_class = this.iconClasses[item.type] || this.iconClasses.ModuleItem
        }
      }
      return json
    }

    afterRender() {
      super.afterRender(...arguments)
      return this.model.collection.syncHeight()
    }
  }
  ProgressionModuleView.initClass()
  return ProgressionModuleView
})()
