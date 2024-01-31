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
import {map} from 'lodash'
import Backbone from '@canvas/backbone'
import I18n from '@canvas/i18n'
import template from '../../jst/DaySubstitution.handlebars'

extend(DaySubstitutionView, Backbone.View)

function DaySubstitutionView() {
  return DaySubstitutionView.__super__.constructor.apply(this, arguments)
}

DaySubstitutionView.prototype.template = template

DaySubstitutionView.prototype.els = {
  '.currentDay': '$currentDay',
  '.subDay': '$subDay',
}

DaySubstitutionView.prototype.events = {
  'click a': 'removeView',
  'change .currentDay': 'changeCurrentDay',
  'change .subDay': 'updateModelData',
}

// When a new view is created, make sure the model is updated
// with it's initial attributes/values
DaySubstitutionView.prototype.afterRender = function () {
  return this.updateModelData()
}

// Ensure that after you update the current day you change focus
// to the next select box. In this case the next select box is
// @$subDay
DaySubstitutionView.prototype.changeCurrentDay = function () {
  return this.updateModelData()
  // @$subDay.focus()
}

// Clear the model and add new value and key
// for the day representation.
//
// @api private
DaySubstitutionView.prototype.updateModelData = function () {
  const sub_data = {}
  sub_data[this.$currentDay.val()] = this.$subDay.val()
  this.updateName()
  this.model.clear()
  return this.model.set(sub_data)
}

DaySubstitutionView.prototype.updateName = function () {
  return this.$subDay.attr(
    'name',
    'date_shift_options[day_substitutions][' + this.$currentDay.val() + ']'
  )
}

// Remove the model from both the view and
// the collection it belongs to.
//
// @api private
DaySubstitutionView.prototype.removeView = function (event) {
  event.preventDefault()
  return this.model.collection.remove(this.model)
}

// Add weekdays to the handlebars template
//
// @api backbone override
DaySubstitutionView.prototype.toJSON = function () {
  const json = DaySubstitutionView.__super__.toJSON.apply(this, arguments)
  json.weekdays = this.weekdays()
  return json
}

// Return an array of objects with weekdays
// ie:
//   [{index: 0, name: 'Sunday'}, {index: 1, name: 'Monday'}]
// @api private
DaySubstitutionView.prototype.weekdays = function () {
  const dayArray = I18n.lookup('date.day_names')
  return map(
    dayArray,
    (function (_this) {
      return function (day) {
        return {
          index: (dayArray || []).indexOf(day),
          name: day,
        }
      }
    })(this)
  )
}

export default DaySubstitutionView
