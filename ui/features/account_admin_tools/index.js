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
import AdminToolsView from './backbone/views/AdminToolsView'
import RestoreContentPaneView from './backbone/views/RestoreContentPaneView'
import CourseSearchFormView from './backbone/views/CourseSearchFormView'
import CourseSearchResultsView from './backbone/views/CourseSearchResultsView'
import LoggingContentPaneView from './backbone/views/LoggingContentPaneView'
import InputFilterView from 'backbone-input-filter-view'
import UserView from './backbone/views/UserView.coffee'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView.coffee'
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
const restoreModel = new CourseRestoreModel({account_id: ENV.ACCOUNT_ID})

const messages = new CommMessageCollection(null, {params: {perPage: 10}})
const messagesUsers = new AccountUserCollection(null, {account_id: ENV.ACCOUNT_ID})
const loggingUsers = new AccountUserCollection(null, {account_id: ENV.ACCOUNT_ID})

ready(() => {
  const messagesContentView = new CommMessagesContentPaneView({
    searchForm: new UserDateRangeSearchFormView({
      formName: 'messages',
      inputFilterView: new InputFilterView({
        collection: messagesUsers
      }),
      usersView: new PaginatedCollectionView({
        collection: messagesUsers,
        itemView: UserView,
        buffer: 1000,
        template: usersTemplate
      }),
      collection: messages
    }),
    resultsView: new PaginatedCollectionView({
      template: messagesSearchResultsTemplate,
      itemView: CommMessageItemView,
      collection: messages
    }),
    collection: messages
  })

  // Render tabs
  const app = new AdminToolsView({
    el: '#admin-tools-app',
    tabs: {
      courseRestore: ENV.PERMISSIONS.restore_course,
      viewMessages: ENV.PERMISSIONS.view_messages,
      logging: !!ENV.PERMISSIONS.logging,
      bouncedEmails: ENV.bounced_emails_admin_tool
    },
    restoreContentPaneView: new RestoreContentPaneView({
      courseSearchFormView: new CourseSearchFormView({model: restoreModel}),
      courseSearchResultsView: new CourseSearchResultsView({model: restoreModel})
    }),
    messageContentPaneView: messagesContentView,
    loggingContentPaneView: new LoggingContentPaneView({
      permissions: ENV.PERMISSIONS.logging,
      users: loggingUsers
    })
  })

  app.render()

  const bouncedEmailsMountPoint = document.getElementById('bouncedEmailsPane')
  if (bouncedEmailsMountPoint) {
    ReactDOM.render(<BouncedEmailsView accountId={ENV.ACCOUNT_ID} />, bouncedEmailsMountPoint)
  }
})
