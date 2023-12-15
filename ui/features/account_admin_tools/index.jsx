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
import CourseSearchFormView from './backbone/views/CourseSearchFormView'
import CourseSearchResultsView from './backbone/views/CourseSearchResultsView'
import UserSearchFormView from './backbone/views/UserSearchFormView'
import UserSearchResultsView from './backbone/views/UserSearchResultsView'
import LoggingContentPaneView from './backbone/views/LoggingContentPaneView'
import InputFilterView from '@canvas/backbone-input-filter-view'
import UserView from './backbone/views/UserView'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import CommMessageCollection from './backbone/collections/CommMessageCollection'
import AccountUserCollection from './backbone/collections/AccountUserCollection'
import CommMessagesContentPaneView from './backbone/views/CommMessagesContentPaneView'
import UserDateRangeSearchFormView from './backbone/views/UserDateRangeSearchFormView'
import CommMessageItemView from './backbone/views/CommMessageItemView'
import messagesSearchResultsTemplate from './jst/commMessagesSearchResults.handlebars'
import usersTemplate from './jst/usersList.handlebars'
import React from 'react'
import ReactDOM from 'react-dom'
import BouncedEmailsView from './react/BouncedEmailsView'
import ready from '@instructure/ready'

// This is used by admin tools to display search results
const courseRestoreModel = new CourseRestoreModel({account_id: ENV.ACCOUNT_ID})
const userRestoreModel = new UserRestoreModel({account_id: ENV.ACCOUNT_ID})

const messages = new CommMessageCollection(null, {params: {perPage: 10}})
const messagesUsers = new AccountUserCollection(null, {account_id: ENV.ACCOUNT_ID})
const loggingUsers = new AccountUserCollection(null, {account_id: ENV.ACCOUNT_ID})

ready(() => {
  const messagesContentView = new CommMessagesContentPaneView({
    searchForm: new UserDateRangeSearchFormView({
      formName: 'messages',
      inputFilterView: new InputFilterView({
        collection: messagesUsers,
      }),
      usersView: new PaginatedCollectionView({
        collection: messagesUsers,
        itemView: UserView,
        buffer: 1000,
        template: usersTemplate,
      }),
      collection: messages,
    }),
    resultsView: new PaginatedCollectionView({
      template: messagesSearchResultsTemplate,
      itemView: CommMessageItemView,
      collection: messages,
    }),
    collection: messages,
  })

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
      courseSearchFormView: new CourseSearchFormView({model: courseRestoreModel}),
      courseSearchResultsView: new CourseSearchResultsView({model: courseRestoreModel}),
      userSearchFormView: new UserSearchFormView({model: userRestoreModel}),
      userSearchResultsView: new UserSearchResultsView({model: userRestoreModel}),
    }),
    messageContentPaneView: messagesContentView,
    loggingContentPaneView: new LoggingContentPaneView({
      permissions: ENV.PERMISSIONS.logging,
      users: loggingUsers,
    }),
  })

  app.render()

  const bouncedEmailsMountPoint = document.getElementById('bouncedEmailsPane')
  if (bouncedEmailsMountPoint) {
    ReactDOM.render(<BouncedEmailsView accountId={ENV.ACCOUNT_ID} />, bouncedEmailsMountPoint)
  }
})
