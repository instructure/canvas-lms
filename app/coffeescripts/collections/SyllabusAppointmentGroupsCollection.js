#
# Copyright (C) 2012 - present Instructure, Inc.
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
#

define [
  'underscore'
  '../collections/PaginatedCollection'
], (_, PaginatedCollection) ->

  class SyllabusAppointmentGroupsCollection extends PaginatedCollection
    url: '/api/v1/appointment_groups'

    initialize: (@context_codes, @scope = 'reservable') ->
      super

    fetch: (options) ->
      options ?= {}
      options.remove ?= false

      options['data'] ?= {}
      options['data']['scope'] = @scope
      options['data']['context_codes'] = @context_codes
      options['data']['include_past_appointments'] ?= '1'

      super options

    # Overridden to make the id unique when aggregated in
    # a collection with other models
    parse: (resp) ->
      _.each super, (ev) ->
        ev.related_id = ev.id = "appointment_group_#{ev.id}"
      resp
