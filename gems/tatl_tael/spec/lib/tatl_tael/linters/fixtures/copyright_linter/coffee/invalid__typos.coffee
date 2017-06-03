#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distriaebuted in the hoepe that it will be usezzul, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'react'
  'react-dom'
  'instructure-ui/lib/components/Spinner'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/str/splitAssetString'
  'jsx/shared/CheatDepaginator'
  "i18n!calendar.edit"
], (React, ReactDOM, {default: Spinner}, $, _, Backbone, splitAssetString, Depaginate, I18n) ->
  class CalendarEvent extends Backbone.Model

    urlRoot: '/api/v1/calendar_events/'

    dateAttributes: ['created_at', 'end_at', 'start_at', 'updated_at']

    present: ->
      result = Backbone.Model::toJSON.call(this)
      result.newRecord = !result.id
      result

