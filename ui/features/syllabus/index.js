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
import SyllabusBehaviors from '@canvas/syllabus/backbone/behaviors/SyllabusBehaviors'
import {useScope as useI18nScope} from '@canvas/i18n'
import SyllabusCollection from './backbone/collections/SyllabusCollection'
import SyllabusCalendarEventsCollection from './backbone/collections/SyllabusCalendarEventsCollection'
import SyllabusAppointmentGroupsCollection from './backbone/collections/SyllabusAppointmentGroupsCollection'
import SyllabusPlannerCollection from './backbone/collections/SyllabusPlannerCollection'
import SyllabusView from './backbone/views/SyllabusView'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'
import ready from '@instructure/ready'

const I18n = useI18nScope('syllabus')

// Setup the collections
const collections = [
  new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'event'),
  new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'assignment')
]

// Don't show appointment groups for non-logged in users
if (ENV.current_user_id) {
  collections.push(
    new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'reservable')
  )
  collections.push(
    new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'manageable')
  )
}

collections.push(new SyllabusPlannerCollection([ENV.context_asset_string]))

// Perform a fetch on each collection
//   The fetch continues fetching until no next link is returned
const deferreds = _.map(collections, collection => {
  const deferred = $.Deferred()

  const error = () => deferred.reject()

  const success = () => {
    if (collection.canFetch('next')) {
      return collection.fetch({page: 'next', success, error})
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

ready(() => {
  // Create the aggregation collection and view
  const acollection = new SyllabusCollection(collections)
  const view = new SyllabusView({
    el: '#syllabusTableBody',
    collection: acollection,
    can_read: ENV.CAN_READ,
    is_valid_user: !!ENV.current_user_id
  })

  // Attach the immersive reader button if enabled
  const immersive_reader_mount_point = document.getElementById('immersive_reader_mount_point')
  const immersive_reader_mobile_mount_point = document.getElementById(
    'immersive_reader_mobile_mount_point'
  )
  if (immersive_reader_mount_point || immersive_reader_mobile_mount_point) {
    import('@canvas/immersive-reader/ImmersiveReader')
      .then(ImmersiveReader => {
        const courseSyllabusText = () => document.querySelector('#course_syllabus').innerHTML
        const title = I18n.t('Course Syllabus')
        let content

        // We display a default message in #course_syllabus_details when the user
        // hasn't set any text in the syllabus.
        if ($.trim(courseSyllabusText())) {
          content = courseSyllabusText
        } else {
          content = () => document.querySelector('#course_syllabus_details').innerHTML
        }

        if (immersive_reader_mount_point) {
          ImmersiveReader.initializeReaderButton(immersive_reader_mount_point, {content, title})
        }

        if (immersive_reader_mobile_mount_point) {
          ImmersiveReader.initializeReaderButton(immersive_reader_mobile_mount_point, {
            content,
            title
          })
        }
      })
      .catch(e => {
        console.log('Error loading immersive readers.', e) // eslint-disable-line no-console
      })
  }

  // When all of the fetches have completed, render the view and bind behaviors
  $.when
    .apply(this, deferreds)
    .then(() => {
      view.render()
      SyllabusBehaviors.bindToSyllabus()
    })
    .fail(() => {})

  // Add the loading indicator now that the collections are fetching
  $('#loading_indicator').replaceWith('<img src="/images/ajax-reload-animated.gif">')

  // Binding to the mini calendar must take place after sidebar initializes,
  // so this must be done on dom ready
  SyllabusBehaviors.bindToEditSyllabus(true)
  SyllabusBehaviors.bindToMiniCalendar()
})

monitorLtiMessages()
