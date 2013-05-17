#
# Copyright (C) 2013 Instructure, Inc.
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
  'compiled/collections/PaginatedCollection'
], (_, PaginatedCollection) ->

  class SyllabusCalendarEventsCollection extends PaginatedCollection
    url: '/api/v1/calendar_events'

    initialize: (@context_codes, @type = 'event') ->
      super

    fetch: (options) ->
      options ?= {}
      options['add'] ?= true

      options['data'] ?= {}
      options['data']['type'] = @type
      options['data']['context_codes'] = @context_codes
      options['data']['all_events'] ?= '1'

      super options

    # Overridden to make the id unique when aggregated in
    # a collection with other models
    parse: (resp) =>
      eventType = @type
      switch eventType
        when "assignment"
          normalize = (ev) ->
            ev.related_id = ev.id

            overridden = false
            _.each ev.assignment_overrides ? [], (override) ->
              if !overridden
                ev.id = "#{ev.id}_override_#{override.id}"
                overridden = true

        when "event"
          normalize = (ev) ->
            ev.related_id = ev.id = "#{eventType}_#{ev.id}"

      _.each super, (ev) ->
        normalize ev

      resp
