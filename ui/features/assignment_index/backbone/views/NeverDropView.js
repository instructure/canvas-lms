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
import {defer} from 'lodash'
import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import neverDropTemplate from '../../jst/NeverDrop.handlebars'

const I18n = useI18nScope('assignmentsNeverDrop')

extend(NeverDrop, Backbone.View)

function NeverDrop() {
  this.toJSON = this.toJSON.bind(this)
  return NeverDrop.__super__.constructor.apply(this, arguments)
}

NeverDrop.prototype.className = 'never_drop_rule'

NeverDrop.prototype.template = neverDropTemplate

NeverDrop.optionProperty('canChangeDropRules')

NeverDrop.prototype.events = {
  'change select': 'setChosen',
  'click .remove_never_drop': 'removeNeverDrop',
}

NeverDrop.prototype.setChosen = function (e) {
  if (this.canChangeDropRules) {
    const $target = this.$(e.currentTarget)
    return this.model.set({
      chosen_id: $target.val(),
      focus: true,
    })
  }
}

NeverDrop.prototype.removeNeverDrop = function (e) {
  e.preventDefault()
  if (this.canChangeDropRules) {
    return this.model.collection.remove(this.model)
  }
}

NeverDrop.prototype.afterRender = function () {
  if (this.model.has('focus')) {
    return defer(
      (function (_this) {
        return function () {
          _this.$('select').focus()
          return _this.model.unset('focus')
        }
      })(this)
    )
  }
}

NeverDrop.prototype.toJSON = function () {
  const json = NeverDrop.__super__.toJSON.apply(this, arguments)
  json.canChangeDropRules = this.canChangeDropRules
  json.buttonTitle = I18n.t('remove_unsaved_never_drop_rule', 'Remove unsaved never drop rule')
  if (this.model.has('chosen_id')) {
    json.assignments = this.model.collection.toAssignments(this.model.get('chosen_id'))
  }
  if (json.chosen) {
    json.buttonTitle =
      I18n.t('remove_never_drop_rule', 'Remove never drop rule') + (' ' + json.chosen)
  }
  return json
}

export default NeverDrop
