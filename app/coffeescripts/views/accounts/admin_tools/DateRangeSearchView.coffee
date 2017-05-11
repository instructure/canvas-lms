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
  'Backbone'
  'jquery'
  'i18n!user_date_range_search'
  'jst/accounts/admin_tools/dateRangeSearch'
  'jquery.instructure_date_and_time'
], (Backbone, $, I18n, template) ->
  class DateRangeSearchView extends Backbone.View
    template: template

    els:
      '.dateSearchField': '$dateSearchFields'

    toJSON: ->
      name: @options.name

    constructor: (@options) ->
      super

    afterRender: ->
      @$dateSearchFields.datetime_field()

    validate: (json) ->
      json ||= @$el.toJSON()
      errors = {}
      if json.start_time && json.end_time && (json.start_time > json.end_time)
        errors['end_time'] = [{
          type: 'invalid'
          message: I18n.t('cant_come_before_from', "'To Date' can't come before 'From Date'")
        }]
      errors