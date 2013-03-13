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
  'compiled/views/SelectView'
  'jst/courses/roster/rosterUsers'
  'compiled/collections/RosterUserCollection'
  'compiled/collections/SectionCollection'
  'compiled/views/InputFilterView'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/courses/RosterUserView'
  'compiled/views/courses/RosterView'
  'jquery'
], (SelectView, rosterUsersTemplate, RosterUserCollection, SectionCollection, InputFilterView, PaginatedCollectionView, RosterUserView, RosterView, $) ->

  fetchOptions =
    include: ['avatar_url', 'enrollments', 'email']
    per_page: 50
  users = new RosterUserCollection null,
    course_id: ENV.context_asset_string.split('_')[1]
    sections: new SectionCollection ENV.SECTIONS
    params: fetchOptions
  inputFilterView = new InputFilterView
    collection: users
  usersView = new PaginatedCollectionView
    collection: users
    itemView: RosterUserView
    buffer: 1000
    template: rosterUsersTemplate
  roleSelectView = new SelectView
    collection: users
  @app = new RosterView
    usersView: usersView
    inputFilterView: inputFilterView
    roleSelectView: roleSelectView
    collection: users
    roles: ENV.ALL_ROLES

  @app.render()
  @app.$el.appendTo $('#content')
  users.fetch()

