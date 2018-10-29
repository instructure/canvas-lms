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

import Backbone from 'Backbone'
import PaginatedCollectionView from '../../PaginatedCollectionView'
import InputFilterView from '../../InputFilterView'
import UserView from '../UserView'
import UserDateRangeSearchFormView from './UserDateRangeSearchFormView'
import AuthLoggingCollection from '../../../collections/AuthLoggingCollection'
import AuthLoggingItemView from './AuthLoggingItemView'
import authLoggingResultsTemplate from 'jst/accounts/admin_tools/authLoggingSearchResults'
import usersTemplate from 'jst/accounts/usersList'
import template from 'jst/accounts/admin_tools/authLoggingContentPane'

export default class AuthLoggingContentPaneView extends Backbone.View {
  static initClass() {
    this.child('searchForm', '#authLoggingSearchForm')
    this.child('resultsView', '#authLoggingSearchResults')

    this.prototype.template = template
  }

  constructor(options) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.fetch = this.fetch.bind(this)
    this.onFail = this.onFail.bind(this)
    this.options = options
    this.collection = new AuthLoggingCollection(null)
    super(...arguments)

    this.searchForm = new UserDateRangeSearchFormView({
      formName: 'logging',
      inputFilterView: new InputFilterView({
        collection: this.options.users
      }),
      usersView: new PaginatedCollectionView({
        collection: this.options.users,
        itemView: UserView,
        buffer: 1000,
        template: usersTemplate
      }),
      collection: this.collection
    })
    this.resultsView = new PaginatedCollectionView({
      template: authLoggingResultsTemplate,
      itemView: AuthLoggingItemView,
      collection: this.collection
    })
  }

  attach() {
    return this.collection.on('setParams', this.fetch)
  }

  fetch() {
    return this.collection.fetch().fail(this.onFail)
  }

  onFail() {
    // Received a 404, empty the collection and don't let the paginated
    // view try to fetch more.
    this.collection.reset()
    return this.resultsView.detachScroll()
  }
}
AuthLoggingContentPaneView.initClass()
