#
# Copyright (C) 2012 Instructure, Inc.
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
  'jst/courses/rosterSearch'
  'jst/courses/rosterUsers'
  'compiled/collections/RosterUserCollection'
  'compiled/collections/SectionCollection'
  'compiled/views/InputFilterView'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/courses/RosterUserView'
  'compiled/views/SearchView'
  'jquery'
], (rosterSearchTemplate, rosterUsersTemplate, UserCollection, SectionCollection, InputFilterView, PaginatedCollectionView, RosterUserView, SearchView, $) ->

  fetchOptions =
    include: ['avatar_url', 'enrollments', 'email']
    per_page: 50
  users = new UserCollection null,
    course_id: ENV.context_asset_string.split('_')[1]
    sections: new SectionCollection ENV.SECTIONS
    params: fetchOptions
  inputView = new InputFilterView
  usersView = new PaginatedCollectionView
    collection: users
    itemView: RosterUserView
    buffer: 1000
    template: rosterUsersTemplate
  searchView = new SearchView
    collectionView: usersView
    inputFilterView: inputView
    template: rosterSearchTemplate

  users.on 'beforeFetch', =>
    inputView.$el.addClass 'loading'
  users.on 'fetch', =>
    inputView.$el.removeClass 'loading'

  searchView.render()
  searchView.$el.appendTo $('#content')
  users.fetch()

