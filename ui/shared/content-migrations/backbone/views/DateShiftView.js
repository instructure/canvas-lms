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
import DaySubModel from '@canvas/day-substitution/backbone/models/DaySubstitution'
import template from '../../jst/DateShift.handlebars'

extend(DateShiftView, Backbone.View)

function DateShiftView() {
  this.updateNewDates = this.updateNewDates.bind(this)
  this.createDaySubView = this.createDaySubView.bind(this)
  this.toggleShiftContent = this.toggleShiftContent.bind(this)
  this.toggleContent = this.toggleContent.bind(this)
  return DateShiftView.__super__.constructor.apply(this, arguments)
}

DateShiftView.prototype.template = template

DateShiftView.child('daySubstitution', '#daySubstitution')

DateShiftView.optionProperty('oldStartDate')

DateShiftView.optionProperty('oldEndDate')

DateShiftView.optionProperty('addHiddenInput')

DateShiftView.prototype.els = {
  '.dateAdjustContent': '$dateAdjustContent',
  '#dateAdjustCheckbox': '$dateAdjustCheckbox',
  '.dateShiftContent': '$dateShiftContent',
  '#dateShiftOption': '$dateShiftOption',
  '#oldStartDate': '$oldStartDate',
  '#oldEndDate': '$oldEndDate',
  '#newStartDate': '$newStartDate',
  '#newEndDate': '$newEndDate',
  '#daySubstitution': '$daySubstitution',
}

DateShiftView.prototype.events = {
  'click #dateAdjustCheckbox': 'toggleContent',
  'click #dateRemoveOption': 'toggleShiftContent',
  'click #dateShiftOption': 'toggleShiftContent',
  'click #addDaySubstitution': 'createDaySubView',
}

DateShiftView.prototype.afterRender = function () {
  this.$el.find('input[type=text]').datetime_field({
    addHiddenInput: this.addHiddenInput,
  })
  if (this.oldStartDate) {
    this.$newStartDate.val(this.oldStartDate).trigger('change')
  }
  if (this.oldEndDate) {
    this.$newEndDate.val(this.oldEndDate).trigger('change')
  }
  this.collection.on(
    'remove',
    (function (_this) {
      return function () {
        return _this.$el.find('#addDaySubstitution').focus()
      }
    })(this)
  )
  return this.toggleContent()
}

// Toggle adjust-dates content. Shows Shift/Remove radio buttons
// if "Adjust dates" is checked.
DateShiftView.prototype.toggleContent = function () {
  const adjustDates = this.$dateAdjustCheckbox.is(':checked')
  if (adjustDates) {
    this.toggleShiftContent()
  }
  return this.$dateAdjustContent.toggle(adjustDates)
}

// Toggle shift content. Shows content when the "Shift dates" radio button
// is selected, and hides content otherwise
//
// @expects jQuery event
// @returns void
// @api private
DateShiftView.prototype.toggleShiftContent = function () {
  const dateShift = this.$dateShiftOption.is(':checked')
  this.model.daySubCollection = dateShift ? this.collection : null
  return this.$dateShiftContent.toggle(dateShift)
}

// Displays a new DaySubstitutionView by adding it to the collection.
// @api private
DateShiftView.prototype.createDaySubView = function (event) {
  event.preventDefault()
  this.collection.add(new DaySubModel())
  let ref
  // Focus on the last date substitution added
  // eslint-disable-next-line no-void
  const $lastDaySubView = (ref = this.collection.last()) != null ? ref.view.$el : void 0
  return $lastDaySubView.find('select').first().focus()
}

DateShiftView.prototype.updateNewDates = function (course) {
  this.$oldStartDate.val(course.start_at).trigger('change')
  return this.$oldEndDate.val(course.end_at).trigger('change')
}

export default DateShiftView
