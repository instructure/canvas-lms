/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import $ from 'jquery'
import _ from 'underscore'
import SyllabusBehaviors from 'compiled/behaviors/SyllabusBehaviors'
import SyllabusCollection from 'compiled/collections/SyllabusCollection'
import SyllabusCalendarEventsCollection from 'compiled/collections/SyllabusCalendarEventsCollection'
import SyllabusAppointmentGroupsCollection from 'compiled/collections/SyllabusAppointmentGroupsCollection'
import SyllabusPlannerCollection from '../../coffeescripts/collections/SyllabusPlannerCollection'
import SyllabusView from 'compiled/views/courses/SyllabusView'

// Setup the collections
const collections = [
  new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'event'),
  new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'assignment')
]

// Don't show appointment groups for non-logged in users
if (ENV.current_user_id) {
  collections.push(new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'reservable'))
  collections.push(new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'manageable'))
}

if (ENV.STUDENT_PLANNER_ENABLED) {
  collections.push(new SyllabusPlannerCollection([ENV.context_asset_string]))
}

// Perform a fetch on each collection
//   The fetch continues fetching until no next link is returned
const deferreds = _.map(collections, (collection) => {
  const deferred = $.Deferred()

  const error = () => deferred.reject()

  const success = () => {
    if (collection.canFetch('next')) {
      return collection.fetch({page: 'next', success, error })
    } else {
      return deferred.resolve()
    }
  }

  collection.fetch({
    data: {
      per_page: ENV.SYLLABUS_PER_PAGE || 50
    },
    success,
    error
  })

  return deferred
})

// Create the aggregation collection and view
const acollection = new SyllabusCollection(collections)
const view = new SyllabusView({
  el: '#syllabusContainer',
  collection: acollection,
  can_read: ENV.CAN_READ,
  is_valid_user: !!ENV.current_user_id
})

// When all of the fetches have completed, render the view and bind behaviors
$.when.apply(this, deferreds).then(() => {
  view.render()
  SyllabusBehaviors.bindToSyllabus()
})

// Add the loading indicator now that the collections are fetching
$('#loading_indicator').replaceWith('<img src="/images/ajax-reload-animated.gif">')

// Binding to the mini calendar must take place after sidebar initializes,
// so this must be done on dom ready
$(() => {
  SyllabusBehaviors.bindToEditSyllabus()
  SyllabusBehaviors.bindToMiniCalendar()
})

