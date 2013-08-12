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
  'compiled/views/InputFilterView'
  'compiled/views/accounts/UserView'
  'compiled/views/PaginatedCollectionView'
  'compiled/collections/CommMessageCollection'
  'compiled/collections/AccountUserCollection'
  'compiled/collections/AuthLoggingCollection'
  'compiled/views/accounts/admin_tools/CommMessagesContentPaneView'
  'compiled/views/accounts/admin_tools/AuthLoggingContentPaneView'
  'compiled/views/accounts/admin_tools/UserDateRangeSearchFormView'
  'compiled/views/accounts/admin_tools/CommMessageItemView'
  'compiled/views/accounts/admin_tools/AuthLoggingItemView'
  'jst/accounts/admin_tools/commMessagesSearchResults'
  'jst/accounts/admin_tools/authLoggingSearchResults'
  'jst/accounts/usersList'
], (CourseRestoreModel, AdminToolsView, RestoreContentPaneView, CourseSearchFormView, CourseSearchResultsView, InputFilterView, UserView, PaginatedCollectionView, CommMessageCollection, AccountUserCollection, AuthLoggingCollection, CommMessagesContentPaneView, AuthLoggingContentPaneView, UserDateRangeSearchFormView, CommMessageItemView, AuthLoggingItemView, messagesSearchResultsTemplate, authLoggingResultsTemplate, usersTemplate) ->
    # This is used by admin tools to display search results
    restoreModel = new CourseRestoreModel account_id: ENV.ACCOUNT_ID

    messages = new CommMessageCollection null,
      params: {perPage: 10}
    users = new AccountUserCollection null,
      account_id: ENV.ACCOUNT_ID
    messagesContentView = new CommMessagesContentPaneView
      searchForm: new UserDateRangeSearchFormView
        formName: 'messages'
        inputFilterView: new InputFilterView
          collection: users
        usersView: new PaginatedCollectionView
          collection: users
          itemView: UserView
          buffer: 1000
          template: usersTemplate
        collection: messages
      resultsView: new PaginatedCollectionView
        template: messagesSearchResultsTemplate
        itemView: CommMessageItemView
        collection: messages
      collection: messages
    loggingEvents = new AuthLoggingCollection null
    loggingContentView = new AuthLoggingContentPaneView
      searchForm: new UserDateRangeSearchFormView
        formName: 'logging'
        inputFilterView: new InputFilterView
          collection: users
        usersView: new PaginatedCollectionView
          collection: users
          itemView: UserView
          buffer: 1000
          template: usersTemplate
        collection: loggingEvents
      resultsView: new PaginatedCollectionView
        template: authLoggingResultsTemplate
        itemView: AuthLoggingItemView
        collection: loggingEvents
      collection: loggingEvents

      # Render tabs
    @app = new AdminToolsView
      el: "#content"
      tabs:
        courseRestore: ENV.PERMISSIONS.restore_course
        viewMessages: ENV.PERMISSIONS.view_messages
        authLogging: ENV.PERMISSIONS.auth_logging
      restoreContentPaneView: new RestoreContentPaneView
                                courseSearchFormView: new CourseSearchFormView
                                  model: restoreModel
                                courseSearchResultsView: new CourseSearchResultsView
                                  model: restoreModel
      messageContentPaneView: messagesContentView
      authLoggingContentPaneView: loggingContentView

    @app.render()
