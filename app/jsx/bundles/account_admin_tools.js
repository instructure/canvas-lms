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

import CourseRestoreModel from 'compiled/models/CourseRestore'
import AdminToolsView from 'compiled/views/accounts/admin_tools/AdminToolsView'
import RestoreContentPaneView from 'compiled/views/accounts/admin_tools/RestoreContentPaneView'
import CourseSearchFormView from 'compiled/views/accounts/admin_tools/CourseSearchFormView'
import CourseSearchResultsView from 'compiled/views/accounts/admin_tools/CourseSearchResultsView'
import LoggingContentPaneView from 'compiled/views/accounts/admin_tools/LoggingContentPaneView'
import InputFilterView from 'compiled/views/InputFilterView'
import UserView from 'compiled/views/accounts/UserView'
import PaginatedCollectionView from 'compiled/views/PaginatedCollectionView'
import CommMessageCollection from 'compiled/collections/CommMessageCollection'
import AccountUserCollection from 'compiled/collections/AccountUserCollection'
import CommMessagesContentPaneView from 'compiled/views/accounts/admin_tools/CommMessagesContentPaneView'
import UserDateRangeSearchFormView from 'compiled/views/accounts/admin_tools/UserDateRangeSearchFormView'
import CommMessageItemView from 'compiled/views/accounts/admin_tools/CommMessageItemView'
import messagesSearchResultsTemplate from 'jst/accounts/admin_tools/commMessagesSearchResults'
import usersTemplate from 'jst/accounts/usersList'
import React from 'react'
import ReactDOM from 'react-dom'
import BouncedEmailsView from '../bounced_emails/BouncedEmailsView'
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
