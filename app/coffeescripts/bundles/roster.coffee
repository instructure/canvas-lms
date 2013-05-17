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
  'compiled/models/CreateUserList'
  'compiled/views/courses/roster/CreateUsersView'
  'compiled/views/SelectView'
  'jst/courses/roster/rosterUsers'
  'compiled/collections/RosterUserCollection'
  'compiled/collections/SectionCollection'
  'compiled/views/InputFilterView'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/courses/roster/RosterUserView'
  'compiled/views/courses/roster/RosterView'
  'jquery'
], (CreateUserList, CreateUsersView, SelectView, rosterUsersTemplate, RosterUserCollection, SectionCollection, InputFilterView, PaginatedCollectionView, RosterUserView, RosterView, $) ->

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
  createUsersView = new CreateUsersView
    model: new CreateUserList
      sections: ENV.SECTIONS
      roles: ENV.ALL_ROLES
      readURL: ENV.USER_LISTS_URL
      updateURL: ENV.ENROLL_USERS_URL
  @app = new RosterView
    usersView: usersView
    inputFilterView: inputFilterView
    roleSelectView: roleSelectView
    createUsersView: createUsersView
    collection: users
    roles: ENV.ALL_ROLES
    permissions: ENV.permissions

  @app.render()
  @app.$el.appendTo $('#content')
  users.fetch()

