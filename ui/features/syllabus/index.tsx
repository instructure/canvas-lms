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

import React from 'react'
import {render} from '@canvas/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map} from 'es-toolkit/compat'
import SyllabusBehaviors from '@canvas/syllabus/backbone/behaviors/SyllabusBehaviors'
import SyllabusCollection from './backbone/collections/SyllabusCollection'
import SyllabusCalendarEventsCollection from './backbone/collections/SyllabusCalendarEventsCollection'
import SyllabusAppointmentGroupsCollection from './backbone/collections/SyllabusAppointmentGroupsCollection'
import SyllabusPlannerCollection from './backbone/collections/SyllabusPlannerCollection'
import SyllabusView from './backbone/views/SyllabusView'
import type {SyllabusCollectionLike} from './backbone/types'
import {attachImmersiveReaderButton} from './util/utils'
import ready from '@instructure/ready'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('syllabus')

type SyllabusCollectionSet =
  | SyllabusAppointmentGroupsCollection
  | SyllabusCalendarEventsCollection
  | SyllabusPlannerCollection

ready(() => {
  const immersive_reader_mount_point = () => document.getElementById('immersive_reader_mount_point')
  const immersive_reader_mobile_mount_point = () =>
    document.getElementById('immersive_reader_mobile_mount_point')
  const showCourseSummary = !!document.getElementById('syllabusContainer')

  let collections: SyllabusCollectionSet[] = []
  let deferreds: JQuery.Deferred<void>[] = []

  // If we're in a paced course, we're not showing the assignments
  // so skip retrieving them.
  // Also, ensure 'Show Course Summary' is checked otherwise don't bother.
  if (!(ENV.IN_PACED_COURSE && !ENV.current_user_is_student) && showCourseSummary) {
    // Setup the collections
    collections = [
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'event'),
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'assignment'),
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'sub_assignment'),
    ]

    // Don't show appointment groups for non-logged in users
    if (ENV.current_user_id) {
      collections.push(
        new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'reservable'),
      )
      collections.push(
        new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'manageable'),
      )
    }

    collections.push(new SyllabusPlannerCollection([ENV.context_asset_string]))

    // Perform a fetch on each collection
    //   The fetch continues fetching until no next link is returned
    deferreds = map(collections, collection => {
      const deferred = $.Deferred<void>()

      const error = () => deferred.reject()

      const success = () => {
        // @ts-expect-error TS7 migration
        if (collection.canFetch('next')) {
          return collection.fetch({page: 'next', success, error})
        }

        deferred.resolve()
      }

      collection.fetch({
        data: {
          // @ts-expect-error TS2339 (typescriptify) - page-specific ENV property.
          per_page: ENV.SYLLABUS_PER_PAGE || 50,
        },
        success,
        error,
      })

      return deferred
    })
  }

  // Attach the immersive reader button if enabled
  const activeMountPoints = [
    immersive_reader_mount_point(),
    immersive_reader_mobile_mount_point(),
  ].filter((node): node is HTMLElement => node instanceof HTMLElement)

  if (activeMountPoints.length > 0) {
    attachImmersiveReaderButton(activeMountPoints)
  }

  // Finish early if we don't need show summary content
  if (!showCourseSummary) {
    SyllabusBehaviors.bindToEditSyllabus(false)
    return
  }

  let view: SyllabusView | undefined
  if (ENV.IN_PACED_COURSE && !ENV.current_user_is_student) {
    renderCoursePacingNotice()
  } else {
    // Create the aggregation collection and view
    const acollection = new SyllabusCollection(collections as unknown as SyllabusCollectionLike[])
    view = new SyllabusView({
      el: '#syllabusTableBody',
      collection: acollection,
      // @ts-expect-error TS2339 (typescriptify) - page-specific ENV property.
      can_read: ENV.CAN_READ,
      is_valid_user: !!ENV.current_user_id,
    })
  }

  // When all of the fetches have completed, render the view and bind behaviors
  if (view) {
    $.when(...deferreds)
      .then(() => {
        view?.render()
        SyllabusBehaviors.bindToSyllabus()
      })
      .fail(() => {})
  }

  // Add the loading indicator now that the collections are fetching
  const node = document.querySelector('#loading_indicator')
  if (node instanceof HTMLElement) {
    const root = render(
      <View padding="x-small" textAlign="center" as="div" display="block">
        <Spinner delay={300} size="x-small" renderTitle={() => I18n.t('Loading')} />
      </View>,
      node,
    )

    // Cleanup on unmount
    $(window).on('beforeunload', () => {
      root.unmount()
    })
  }

  // Binding to the mini calendar must take place after sidebar initializes,
  // so this must be done on dom ready
  SyllabusBehaviors.bindToEditSyllabus(true)
  SyllabusBehaviors.bindToMiniCalendar()

  const syllabusRevisionsBtn = document.getElementById('syllabus_revisions_btn')
  if (syllabusRevisionsBtn instanceof HTMLButtonElement) {
    const contextInfo = ENV.context_asset_string.split('_')
    const courseId = contextInfo[0] === 'course' ? contextInfo[1] : undefined
    if (courseId) {
      import(/* webpackChunkName: "syllabus_revisions" */ '../syllabus_revisions/index').then(
        module => {
          module.initSyllabusRevisionsTray(courseId, syllabusRevisionsBtn)
        },
      )
    }
  }
})

function renderCoursePacingNotice() {
  const contextInfo = ENV.context_asset_string.split('_')
  const courseId = contextInfo[0] === 'course' ? contextInfo[1] : undefined
  const mountPoint = document.getElementById('syllabusContainer')
  if (mountPoint) {
    // replace the table with the notice
    import(/* webpackChunkName: "[request]" */ '@canvas/due-dates/react/CoursePacingNotice')
      .then(CoursePacingNoticeModule => {
        const renderNotice = CoursePacingNoticeModule.renderCoursePacingNotice
        renderNotice(mountPoint, courseId)
      })
      .catch(ex => {
        console.error('Falied loading CoursePacingNotice', ex)
      })
  }
}
