#
# Copyright (C) 2016 - present Instructure, Inc.
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

# This file is to add the methods that depend on '../util/fcUtil'
# as registered handelbars helpers. These are not in app/coffeescripts/handlebars_helpers.coffee
# because otherwise everypage would load fullcalendar.js (which fcUtil depends on).
# So anything that depends on these helpers in their handlbars needs to make sure
# to require this file first, so they are available as helpers.

define [
  'timezone'
  '../util/fcUtil'
  'handlebars/runtime'
], (tz, fcUtil, {default: Handlebars}) ->

  Handlebars.registerHelper name, fn for name, fn of {

    # convert a moment to a string, using the given i18n format in the date.formats namespace
    fcMomentToDateString : (date = '', i18n_format) ->
      return '' unless date
      tz.format(fcUtil.unwrap(date), "date.formats.#{i18n_format}")

    # convert a moment to a time string, using the given i18n format in the time.formats namespace
    fcMomentToString : (date = '', i18n_format) ->
      return '' unless date
      tz.format(fcUtil.unwrap(date), "time.formats.#{i18n_format}")
  }

  return Handlebars
