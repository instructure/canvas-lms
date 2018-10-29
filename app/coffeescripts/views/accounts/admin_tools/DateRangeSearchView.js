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

import Backbone from 'Backbone'
import I18n from 'i18n!user_date_range_search'
import template from 'jst/accounts/admin_tools/dateRangeSearch'
import 'jquery.instructure_date_and_time'

export default class DateRangeSearchView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.els = {'.dateSearchField': '$dateSearchFields'}
  }

  toJSON() {
    return {name: this.options.name}
  }

  afterRender() {
    return this.$dateSearchFields.datetime_field()
  }

  validate(json) {
    if (!json) {
      json = this.$el.toJSON()
    }
    const errors = {}
    if (json.start_time && json.end_time && json.start_time > json.end_time) {
      errors.end_time = [
        {
          type: 'invalid',
          message: I18n.t('cant_come_before_from', "'To Date' can't come before 'From Date'")
        }
      ]
    }
    return errors
  }
}
DateRangeSearchView.initClass()
