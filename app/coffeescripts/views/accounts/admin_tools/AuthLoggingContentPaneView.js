#
# Copyright (C) 2013 - present Instructure, Inc.
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

define [
  'Backbone'
  'jquery' 
  '../../PaginatedCollectionView'  
  '../../InputFilterView'
  '../UserView'
  './UserDateRangeSearchFormView'
  '../../../collections/AuthLoggingCollection'
  './AuthLoggingItemView'
  'jst/accounts/admin_tools/authLoggingSearchResults'
  'jst/accounts/usersList'
  'jst/accounts/admin_tools/authLoggingContentPane'
], (
  Backbone,
  $,
  PaginatedCollectionView,
  InputFilterView,
  UserView,
  UserDateRangeSearchFormView,
  AuthLoggingCollection,
  AuthLoggingItemView,
  authLoggingResultsTemplate,
  usersTemplate,
  template
) ->
  class AuthLoggingContentPaneView extends Backbone.View
    @child 'searchForm', '#authLoggingSearchForm'
    @child 'resultsView', '#authLoggingSearchResults'

    template: template

    constructor: (@options) ->
      @collection = new AuthLoggingCollection null
      super

      @searchForm = new UserDateRangeSearchFormView
        formName: 'logging'
        inputFilterView: new InputFilterView
          collection: @options.users
        usersView: new PaginatedCollectionView
          collection: @options.users
          itemView: UserView
          buffer: 1000
          template: usersTemplate
        collection: @collection
      @resultsView = new PaginatedCollectionView
        template: authLoggingResultsTemplate
        itemView: AuthLoggingItemView
        collection: @collection

    attach: ->
      @collection.on 'setParams', @fetch

    fetch: =>
      @collection.fetch().fail @onFail

    onFail: =>
      # Received a 404, empty the collection and don't let the paginated
      # view try to fetch more.
      @collection.reset()
      @resultsView.detachScroll()
