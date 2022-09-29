/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import createAnnouncementsIndex from './react/index'
import ready from '@instructure/ready'

ready(() => {
  const root = document.querySelector('#content')
  const [contextType, contextId] = ENV.context_asset_string.split('_')
  const app = createAnnouncementsIndex(root, {
    atomFeedUrl: ENV.atom_feed_url,
    contextType,
    contextId,
    masterCourseData: ENV.BLUEPRINT_COURSES_DATA,
    permissions: ENV.permissions,
    announcementsLocked: ENV.ANNOUNCEMENTS_LOCKED,
  })

  app.render()
})
