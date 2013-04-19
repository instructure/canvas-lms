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

require [
  'jquery'
  'underscore'
  'compiled/behaviors/SyllabusBehaviors'
  'compiled/collections/SyllabusCollection'
  'compiled/collections/SyllabusCalendarEventsCollection'
  'compiled/collections/SyllabusAppointmentGroupsCollection'
  'compiled/views/courses/SyllabusView'
], ($, _, SyllabusBehaviors, SyllabusCollection, SyllabusCalendarEventsCollection, SyllabusAppointmentGroupsCollection, SyllabusView) ->

  # Setup the collections
  collections = [
    new SyllabusCalendarEventsCollection [ENV.context_asset_string], 'event'
    new SyllabusCalendarEventsCollection [ENV.context_asset_string], 'assignment'
  ]

  # Don't show appointment groups for non-logged in users
  if ENV.current_user_id
    collections.push(new SyllabusAppointmentGroupsCollection [ENV.context_asset_string], 'reservable')
    collections.push(new SyllabusAppointmentGroupsCollection [ENV.context_asset_string], 'manageable')

  # Perform a fetch on each collection
  #   The fetch continues fetching until no next link is returned
  deferreds = _.map collections, (collection) ->
    deferred = $.Deferred()

    error = ->
      deferred.reject()

    success = ->
      if collection.canFetch 'next'
        collection.fetch
          page: 'next'
          success: success
          error: error
      else
        deferred.resolve()

    collection.fetch
      data:
        per_page: ENV.SYLLABUS_PER_PAGE ? 50
      success: success
      error: error

    deferred

  # Create the aggregation collection and view
  acollection = new SyllabusCollection collections
  view = new SyllabusView
    el: '#syllabusContainer'
    collection: acollection
    can_read: ENV.CAN_READ
    is_valid_user: if ENV.current_user_id then true else false

  # When all of the fetches have completed, render the view and bind behaviors
  $.when.apply(this, deferreds).then ->
    view.render()
    SyllabusBehaviors.bindToSyllabus()

  # Add the loading indicator now that the collections are fetching
  $('#loading_indicator').replaceWith '<img src="/images/ajax-reload-animated.gif">'

  # Binding to the mini calendar must take place after wikiSidebar initializes,
  # so this must be done on dom ready
  $ ->
    SyllabusBehaviors.bindToEditSyllabus()
    SyllabusBehaviors.bindToMiniCalendar()

    $.scrollSidebar()
