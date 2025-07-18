/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import Course from '@canvas/courses/backbone/models/Course'
import AssignmentGroupListView from './backbone/views/AssignmentGroupListView'
import CreateGroupView from './backbone/views/CreateGroupView'
import IndexView from './backbone/views/IndexView'
import AssignmentSettingsView from './backbone/views/AssignmentSettingsView'
import AssignmentSyncSettingsView from './backbone/views/AssignmentSyncSettingsView'
import AssignmentGroupWeightsView from './backbone/views/AssignmentGroupWeightsView'
import ToggleShowByView from './backbone/views/ToggleShowByView'
import splitAssetString from '@canvas/util/splitAssetString'
import {getPrefetchedXHR} from '@canvas/util/xhr'
import ready from '@instructure/ready'
import {addDeepLinkingListener} from '@canvas/deep-linking/DeepLinking'
import {
  handleAssignmentIndexDeepLinking,
  alertIfDeepLinkingCreatedModule,
} from './helpers/deepLinkingHelper'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignment_index')

ready(() => {
  const course = new Course({
    id: encodeURIComponent(splitAssetString(ENV.context_asset_string)[1]),
    apply_assignment_group_weights: ENV.apply_assignment_group_weights,
  })
  course.url = ENV.URLS.course_url

  const userIsAdmin = ENV.current_user_is_admin

  const assignmentGroups = new AssignmentGroupCollection([], {
    course,
    courseSubmissionsURL: ENV.URLS.course_student_submissions_url,
  })

  let assignmentSettingsView = false
  let assignmentSyncSettingsView = false
  let createGroupView = false
  let showByView = false

  const assignmentGroupsView = new AssignmentGroupListView({
    collection: assignmentGroups,
    sortURL: ENV.URLS.sort_url,
    assignment_sort_base_url: ENV.URLS.assignment_sort_base_url,
    course,
    userIsAdmin,
  })

  if (ENV.PERMISSIONS.manage_assignments_edit) {
    assignmentSettingsView = new AssignmentSettingsView({
      model: course,
      assignmentGroups,
      weightsView: AssignmentGroupWeightsView,
      userIsAdmin,
    })

    assignmentSyncSettingsView = new AssignmentSyncSettingsView({
      collection: assignmentGroups,
      model: course,
      sisName: ENV.SIS_NAME,
    })
  }

  if (ENV.PERMISSIONS.manage_assignments_add) {
    createGroupView = new CreateGroupView({
      assignmentGroups,
      course,
      userIsAdmin,
    })
  }

  if (!ENV.PERMISSIONS.manage_assignments_edit && !ENV.PERMISSIONS.manage_assignments_add) {
    showByView = new ToggleShowByView({
      course,
      assignmentGroups,
    })
  }

  const indexEl =
    window.location.href.indexOf('assignments') === -1 ? '#course_home_content' : '#content'

  const app = new IndexView({
    el: indexEl,
    assignmentGroupsView,
    assignmentSettingsView,
    assignmentSyncSettingsView,
    createGroupView,
    showByView,
    collection: assignmentGroups,
  })

  app.render()

  // kick it all off
  course.trigger('change')

  const node = document.querySelector('.loadingIndicator')
  if (node instanceof HTMLElement) {
    const root = createRoot(node)
    root.render(
      <View padding="x-small" textAlign="center" as="div" display="block">
        <Spinner delay={300} size="x-small" renderTitle={() => I18n.t('Loading')} />
      </View>,
    )
  }

  getPrefetchedXHR('assignment_groups_url')
    .then(res =>
      res.json().then(data => {
        // we have to do things a little different than a normal paginatedCollection
        // because we used prefetch_xhr to prefetch the first page of assignment_groups
        // but we still want the rest of the pages (if any) to be fetched like any
        // other paginatedCollection would.
        assignmentGroups.reset(data)
        const mockJqXHR = {getResponseHeader: h => res.headers.get(h)}
        assignmentGroups._setStateAfterFetch(mockJqXHR, {})
        if (!assignmentGroups.loadedAll) {
          return assignmentGroups.fetch({page: 'next'})
        }
      }),
    )
    .then(() => {
      if (ENV.HAS_GRADING_PERIODS) {
        app.filterResults()
      }
      if (ENV.PERMISSIONS.manage) {
        assignmentGroups.loadModuleNames()
      } else {
        assignmentGroups.getGrades()
      }
    })

  alertIfDeepLinkingCreatedModule()
  addDeepLinkingListener(handleAssignmentIndexDeepLinking)
})
