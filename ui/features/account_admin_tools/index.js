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

import CourseRestoreModel from './backbone/models/CourseRestore'
import UserRestoreModel from './backbone/models/UserRestore'
import AdminToolsView from './backbone/views/AdminToolsView'
import RestoreContentPaneView from './backbone/views/RestoreContentPaneView'
import CourseSearchResultsView from './backbone/views/CourseSearchResultsView'
import UserSearchResultsView from './backbone/views/UserSearchResultsView'
import LoggingContentPaneView from './backbone/views/LoggingContentPaneView'
import AccountUserCollection from './backbone/collections/AccountUserCollection'
import ready from '@instructure/ready'
import {initializeTopNavPortal} from '@canvas/top-navigation/react/TopNavPortal'

const courseRestoreModel = new CourseRestoreModel({account_id: ENV.ACCOUNT_ID})
const userRestoreModel = new UserRestoreModel({account_id: ENV.ACCOUNT_ID})

const loggingUsers = new AccountUserCollection(null, {account_id: ENV.ACCOUNT_ID})

ready(() => {
  initializeTopNavPortal()

  // Render tabs
  const app = new AdminToolsView({
    el: '#admin-tools-app',
    tabs: {
      contentRestore: ENV.PERMISSIONS.restore_course || ENV.PERMISSIONS.restore_user,
      viewMessages: ENV.PERMISSIONS.view_messages,
      logging: !!ENV.PERMISSIONS.logging,
      bouncedEmails: ENV.bounced_emails_admin_tool,
    },
    restoreContentPaneView: new RestoreContentPaneView({
      permissions: ENV.PERMISSIONS,
      courseSearchResultsView: new CourseSearchResultsView({model: courseRestoreModel}),
      userSearchResultsView: new UserSearchResultsView({model: userRestoreModel}),
    }),
    loggingContentPaneView: new LoggingContentPaneView({
      permissions: ENV.PERMISSIONS.logging,
      users: loggingUsers,
    }),
  })

  app.render()
})
