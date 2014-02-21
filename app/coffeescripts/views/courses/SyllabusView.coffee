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
  'jquery'
  'underscore'
  'Backbone'
  'jst/courses/Syllabus'
], ($, _, Backbone, template) ->

  class SyllabusView extends Backbone.View
    template: template

    initialize: ({@can_read, @is_valid_user}) ->
      super

    # Normalizes the JSON for all of the aggregated event types
    # into something simpler for the template to consume
    #
    # Example output:
    # {
    #    // Array of the date objects
    #    "dates": [ ... ]
    # }
    #
    # Example date object:
    # {
    #   // Date object for the date at midnight (null for undated events)
    #   "date": new Date(),
    #
    #   // Indicates whether the date is in the past
    #   "passed": true,
    #
    #   // Array of event objects that start on this day
    #   "events": [ ... ]
    # }
    #
    # Example event object:
    # {
    #    // Identifier to associate related events
    #    "related_id": "assignment_1",
    #
    #    // Assignment or other type of event
    #    "type": "assignment|event",
    #
    #    // Title of the event
    #    "title": "Event title",
    #
    #    // URL for the user to access details on the assignment/event
    #    "html_url": "http://...",
    #
    #    // Date the event begins (this is the due_at date for assignments)
    #    "start_at": "2012-01-01T23:59:00-07:00",
    #
    #    // Date the event ends (this is the due_at date for assignments)
    #    "end_at": "2012-01-01T23:59:00-07:00",
    #
    #    // Date the event is due (null for non-assignment events)
    #    "due_at": "2012-01-01T23:59:00-07:00",
    #
    #    // Indicates that the start and end times are on the same day
    #    "same_day": true,
    #
    #    // Indicates that the start and end times are the same time
    #    "same_time": true,
    #
    #    // Indicates that this event is the last on the same day
    #    "last": false,
    #
    #    // Override information associated with this event (null for non-overwritten)
    #    "override": {
    #        // Title for the override
    #        "title": "Overridden for James"
    #    }
    #
    #    // The original JSON from the model
    #    "json": { ... }
    # }
    toJSON: ->
      now = new Date
      today = new Date now.getFullYear(), now.getMonth(), now.getDate()
      html_url_for_assignment = @can_read
      html_url_for_event = @can_read && @is_valid_user # since the calendar page doesn't support anonymous access yet

      relatedEvents = {}
      lastDate = null
      lastEvent = null
      dateCollator = (memo, json) ->
        related_id = json['related_id']
        related_id ?= json['id']
        if json['assignment']
          type = 'assignment'
          html_url = json['html_url'] if html_url_for_assignment
        else
          type = 'event'
          html_url = json['html_url'] if html_url_for_event
        title = json['title']
        start_at = $.fudgeDateForProfileTimezone(Date.parse(json['start_at'])) if json['start_at']
        end_at = $.fudgeDateForProfileTimezone(Date.parse(json['end_at'])) if json['end_at']
        due_at = $.fudgeDateForProfileTimezone(Date.parse(json['assignment']['due_at'])) if json['assignment']?['due_at']

        override = null
        _.each json.assignment_overrides ? [], (ov) ->
          override ?= {}
          override.title = ov.title

        start_date = null
        if start_at
          start_date = new Date start_at.getFullYear(), start_at.getMonth(), start_at.getDate()

        end_date = null
        if end_at
          end_date = new Date end_at.getFullYear(), end_at.getMonth(), end_at.getDate()

        if not lastDate or lastDate['date']?.getTime() != start_date?.getTime()
          lastDate =
            'date': start_date
            'passed': start_date and start_date < today
            'events': []

          memo.push lastDate
          lastEvent = null
        else
          lastEvent['last'] = false if lastEvent

        lastEvent =
          'related_id': related_id
          'type': type
          'title': title
          'html_url': html_url
          'start_at': start_at
          'end_at': end_at
          'due_at': due_at
          'same_day': start_date?.getTime() == end_date?.getTime()
          'same_time': start_at?.getTime() == end_at?.getTime()
          'last': true
          'override': override
          'json': json

        lastDate['events'].push lastEvent

        relatedEvents[related_id] = [] if related_id not of relatedEvents
        relatedEvents[related_id].push lastEvent

        memo

      # Get the dates and events
      dates = _.reduce super, dateCollator, []

      # Remove extraneous override information for single events
      overrides_present = false
      for id, events of relatedEvents
        if events.length == 1
          events[0]['override'] = null
        else
          for event in events
            overrides_present |= event['override'] != null

      # Return the dates and events in a handlebars friendly way
      dates: dates
      overrides_present: overrides_present
