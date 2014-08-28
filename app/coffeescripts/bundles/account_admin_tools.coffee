#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#
require [
  'compiled/models/CourseRestore'
  'compiled/views/accounts/admin_tools/AdminToolsView'
  'compiled/views/accounts/admin_tools/RestoreContentPaneView'
  'compiled/views/accounts/admin_tools/CourseSearchFormView'
  'compiled/views/accounts/admin_tools/CourseSearchResultsView'
  'compiled/views/accounts/admin_tools/LoggingContentPaneView'
  'compiled/views/InputFilterView'
  'compiled/views/accounts/UserView'
  'compiled/views/PaginatedCollectionView'
  'compiled/collections/CommMessageCollection'
  'compiled/collections/AccountUserCollection'
  'compiled/views/accounts/admin_tools/CommMessagesContentPaneView'
  'compiled/views/accounts/admin_tools/UserDateRangeSearchFormView'
  'compiled/views/accounts/admin_tools/CommMessageItemView'
  'jst/accounts/admin_tools/commMessagesSearchResults'
  'jst/accounts/usersList'
], (
  CourseRestoreModel, 
  AdminToolsView, 
  RestoreContentPaneView, 
  CourseSearchFormView, 
  CourseSearchResultsView, 
  LoggingContentPaneView,
  InputFilterView, 
  UserView, 
  PaginatedCollectionView, 
  CommMessageCollection, 
  AccountUserCollection, 
  CommMessagesContentPaneView, 
  UserDateRangeSearchFormView, 
  CommMessageItemView, 
  messagesSearchResultsTemplate, 
  usersTemplate
) ->
  # This is used by admin tools to display search results
  restoreModel = new CourseRestoreModel account_id: ENV.ACCOUNT_ID

  messages = new CommMessageCollection null,
    params: {perPage: 10}
  messagesUsers = new AccountUserCollection null,
    account_id: ENV.ACCOUNT_ID
  loggingUsers = new AccountUserCollection null,
    account_id: ENV.ACCOUNT_ID
  messagesContentView = new CommMessagesContentPaneView
    searchForm: new UserDateRangeSearchFormView
      formName: 'messages'
      inputFilterView: new InputFilterView
        collection: messagesUsers
      usersView: new PaginatedCollectionView
        collection: messagesUsers
        itemView: UserView
        buffer: 1000
        template: usersTemplate
      collection: messages
    resultsView: new PaginatedCollectionView
      template: messagesSearchResultsTemplate
      itemView: CommMessageItemView
      collection: messages
    collection: messages

    # Render tabs
  @app = new AdminToolsView
    el: "#admin-tools-app"
    tabs:
      courseRestore: ENV.PERMISSIONS.restore_course
      viewMessages: ENV.PERMISSIONS.view_messages
      logging: !!ENV.PERMISSIONS.logging
    restoreContentPaneView: new RestoreContentPaneView
                              courseSearchFormView: new CourseSearchFormView
                                model: restoreModel
                              courseSearchResultsView: new CourseSearchResultsView
                                model: restoreModel
    messageContentPaneView: messagesContentView
    loggingContentPaneView: new LoggingContentPaneView
                              permissions: ENV.PERMISSIONS.logging
                              users: loggingUsers

  @app.render()
