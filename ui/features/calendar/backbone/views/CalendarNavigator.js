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
import _ from 'underscore'
import Backbone from '@canvas/backbone'
import template from '../../jst/calendarNavigator.handlebars'
import '@canvas/datetime'

extend(CalendarNavigator, Backbone.View)

function CalendarNavigator() {
  this._onPickerClose = this._onPickerClose.bind(this)
  this._onPickerSelect = this._onPickerSelect.bind(this)
  this._flashDateSuggestion = this._flashDateSuggestion.bind(this)
  this._onDateFieldKey = this._onDateFieldKey.bind(this)
  this.setTitle = this.setTitle.bind(this)
  this.hide = this.hide.bind(this)
  this.show = this.show.bind(this)
  return CalendarNavigator.__super__.constructor.apply(this, arguments)
}

CalendarNavigator.prototype.template = template

CalendarNavigator.prototype.els = {
  '.navigation_title': '$title',
  '.navigation_title_text': '$titleText',
  '.navigation_buttons': '$buttons',
  '.date_field': '$dateField',
  '.date_field_wrapper': '$dateWrapper',
}

CalendarNavigator.prototype.events = {
  'click .navigate_prev': '_triggerPrev',
  'click .navigate_today': '_triggerToday',
  'click .navigate_next': '_triggerNext',
  'click .navigation_title': '_onTitleClick',
  'keyclick .navigation_title': '_onTitleClick',
}

// options:
//   hide - set to true if this navigator should start hidden
CalendarNavigator.prototype.initialize = function () {
  CalendarNavigator.__super__.initialize.apply(this, arguments)
  this.render()
  // use debounce to make the aria-live updates nicer
  this._flashDateSuggestion = _.debounce(this._flashDateSuggestion, 1500)
  this.$buttons.buttonset()
  // make sure our jquery key handler is called first
  this.$dateField.keydown(this._onDateFieldKey)
  this.$dateField.date_field({
    datepicker: {
      onClose: this._onPickerClose,
      onSelect: this._onPickerSelect,
      showOn: 'both',
    },
  })
  this.hidePicker()
  if (this.options.hide) {
    return this.hide()
  }
}

CalendarNavigator.prototype.show = function (visible) {
  if (visible == null) {
    visible = true
  }
  return this.$el.toggle(visible)
}

CalendarNavigator.prototype.hide = function () {
  return this.show(false)
}

CalendarNavigator.prototype.setTitle = function (new_text) {
  this.$titleText.attr('aria-label', new_text + ' click to change')
  return this.$titleText.text(new_text)
}

CalendarNavigator.prototype.showPicker = function (visible) {
  if (visible == null) {
    visible = true
  }
  this._pickerShowing = visible
  this.$title.toggle(!visible)
  this.$dateWrapper.toggle(visible)
  if (visible) {
    this._resetPicker()
    return this.$dateField.focus()
  } else {
    this.$dateField.realDatepicker('hide')
    return this.$title.focus()
  }
}

CalendarNavigator.prototype.hidePicker = function () {
  return this.showPicker(false)
}

CalendarNavigator.prototype.showPrevNext = function () {
  return this.$buttons.show()
}

CalendarNavigator.prototype.hidePrevNext = function () {
  return this.$buttons.hide()
}

CalendarNavigator.prototype._resetPicker = function () {
  this._enterKeyData = null
  this._previousDateFieldValue = ''
  this.$dateField.removeAttr('aria-invalid')
  return this.$dateField.val('')
}

CalendarNavigator.prototype._titleActivated = function () {
  return this.showPicker()
}

CalendarNavigator.prototype._currentSelectedDate = function () {
  this.$dateField.trigger('change')
  return this.$dateField.data()
}

CalendarNavigator.prototype._dateFieldSelect = function () {
  const data = this._enterKeyData || this._currentSelectedDate()
  if (!(data.invalid || data.blank)) {
    this._triggerDate(data['unfudged-date'])
  }
  return this.hidePicker()
}

CalendarNavigator.prototype._triggerPrev = function (_event) {
  return this.trigger('navigatePrev')
}

CalendarNavigator.prototype._triggerToday = function (_event) {
  return this.trigger('navigateToday')
}

CalendarNavigator.prototype._triggerNext = function (_event) {
  return this.trigger('navigateNext')
}

CalendarNavigator.prototype._triggerDate = function (selectedDate) {
  return this.trigger('navigateDate', selectedDate)
}

CalendarNavigator.prototype._onTitleClick = function (event) {
  event.preventDefault()
  return this._titleActivated()
}

CalendarNavigator.prototype._onDateFieldKey = function (event) {
  if (event.keyCode === 13) {
    // enter
    // store current field data for later so we can tell the difference
    // between this and a mouse click
    return (this._enterKeyData = this._currentSelectedDate())
  } else {
    return this._flashDateSuggestion()
  }
}

CalendarNavigator.prototype._flashDateSuggestion = function () {
  if (!this._pickerShowing) {
    return
  }
  if (this._previousDateFieldValue === this.$dateField.val()) {
    return
  }
  return (this._previousDateFieldValue = this.$dateField.val())
}

CalendarNavigator.prototype._onPickerSelect = function () {
  return this._dateFieldSelect()
}

CalendarNavigator.prototype._onPickerClose = function () {
  return this.hidePicker()
}

export default CalendarNavigator
