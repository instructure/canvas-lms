//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from '@canvas/backbone'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import InputFilterView from '@canvas/backbone-input-filter-view'
import UserView from './UserView'
import UserDateRangeSearchFormView from './UserDateRangeSearchFormView'
import AuthLoggingCollection from '../collections/AuthLoggingCollection'
import AuthLoggingItemView from './AuthLoggingItemView'
import authLoggingResultsTemplate from '../../jst/authLoggingSearchResults.handlebars'
import usersTemplate from '../../jst/usersList.handlebars'
import template from '../../jst/authLoggingContentPane.handlebars'
import _inherits from '@babel/runtime/helpers/esm/inheritsLoose'

_inherits(AuthLoggingContentPaneView, Backbone.View)

export default function AuthLoggingContentPaneView(options) {
  this.fetch = this.fetch.bind(this)
  this.onFail = this.onFail.bind(this)
  this.options = options
  this.collection = new AuthLoggingCollection(null)
  Backbone.View.apply(this, arguments)

  this.searchForm = new UserDateRangeSearchFormView({
    formName: 'logging',
    inputFilterView: new InputFilterView({
      collection: this.options.users,
    }),
    usersView: new PaginatedCollectionView({
      collection: this.options.users,
      itemView: UserView,
      buffer: 1000,
      template: usersTemplate,
    }),
    collection: this.collection,
  })
  this.resultsView = new PaginatedCollectionView({
    template: authLoggingResultsTemplate,
    itemView: AuthLoggingItemView,
    collection: this.collection,
  })
}

AuthLoggingContentPaneView.child('searchForm', '#authLoggingSearchForm')
AuthLoggingContentPaneView.child('resultsView', '#authLoggingSearchResults')

Object.assign(AuthLoggingContentPaneView.prototype, {
  template,
  attach() {
    return this.collection.on('setParams', this.fetch)
  },

  fetch() {
    return this.collection.fetch().fail(this.onFail)
  },

  onFail() {
    // Received a 404, empty the collection and don't let the paginated
    // view try to fetch more.
    this.collection.reset()
    return this.resultsView.detachScroll()
  },
})
