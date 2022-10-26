/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import createDiscussionsIndex from './react/index'
import ready from '@instructure/ready'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'

ready(() => {
  const [contextType, contextId] = ENV.context_asset_string.split('_')

  const root = document.querySelector('#content')
  const app = createDiscussionsIndex(root, {
    permissions: ENV.permissions,
    roles: ENV.current_user_roles,
    masterCourseData: ENV.BLUEPRINT_COURSES_DATA,
    discussionTopicMenuTools: ENV.discussion_topic_menu_tools,
    discussionTopicIndexMenuTools: ENV.discussion_topic_index_menu_tools,
    contextCodes: [ENV.context_asset_string],
    currentUserId: ENV.current_user.id,
    DIRECT_SHARE_ENABLED: ENV.DIRECT_SHARE_ENABLED,
    COURSE_ID: ENV.COURSE_ID,
    contextType,
    contextId,
  })
  app.render()
})
monitorLtiMessages()
