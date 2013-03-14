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
  'compiled/views/PaginatedCollectionView'
  'compiled/collections/CommMessageCollection'
  'compiled/views/accounts/admin_tools/CommMessagesContentPaneView'
  'compiled/views/accounts/admin_tools/CommMessagesSearchFormView'
  'compiled/views/accounts/admin_tools/CommMessageItemView'
  'jst/accounts/admin_tools/commMessagesSearchResults'
], (CourseRestoreModel, AdminToolsView, RestoreContentPaneView, CourseSearchFormView, CourseSearchResultsView, PaginatedCollectionView, CommMessageCollection, CommMessagesContentPaneView, CommMessagesSearchFormView, CommMessageItemView, messagesSearchResultsTemplate) ->
    # This is used by admin tools to display search results
    restoreModel = new CourseRestoreModel account_id: ENV.ACCOUNT_ID

    messages = new CommMessageCollection null,
      params: {perPage: 10}
    formView = new CommMessagesSearchFormView
      collection: messages
    resultsView = new PaginatedCollectionView
      template: messagesSearchResultsTemplate
      itemView: CommMessageItemView
      collection: messages
    messagesContentView = new CommMessagesContentPaneView
      searchForm: formView
      resultsView: resultsView
      collection: messages

      # Render tabs
    @app = new AdminToolsView
      el: "#content"
      tabs:
        courseRestore: ENV.PERMISSIONS.restore_course
        viewMessages: ENV.PERMISSIONS.view_messages
      restoreContentPaneView: new RestoreContentPaneView
                                courseSearchFormView: new CourseSearchFormView
                                  model: restoreModel
                                courseSearchResultsView: new CourseSearchResultsView
                                  model: restoreModel
      messageContentPaneView: messagesContentView

    @app.render()
