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
  'i18n!roster'
  'Backbone'
  'compiled/models/CreateUserList'
  'compiled/models/Role'
  'compiled/views/courses/roster/CreateUsersView'
  'compiled/views/courses/roster/RoleSelectView'
  'jst/courses/roster/rosterUsers'
  'compiled/collections/RosterUserCollection'
  'compiled/collections/RolesCollection'
  'compiled/collections/SectionCollection'
  'compiled/collections/GroupCategoryCollection'
  'compiled/views/InputFilterView'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/courses/roster/RosterUserView'
  'compiled/views/courses/roster/RosterView'
  'compiled/views/courses/roster/RosterTabsView'
  'compiled/views/courses/roster/ResendInvitationsView'
  'jquery'
], (I18n, {Model}, CreateUserList, Role, CreateUsersView, RoleSelectView, rosterUsersTemplate, RosterUserCollection, RolesCollection, SectionCollection, GroupCategoryCollection, InputFilterView, PaginatedCollectionView, RosterUserView, RosterView, RosterTabsView, ResendInvitationsView, $) ->

  fetchOptions =
    include: ['avatar_url', 'enrollments', 'email', 'observed_users', 'can_be_removed']
    per_page: 50
  users = new RosterUserCollection null,
    course_id: ENV.context_asset_string.split('_')[1]
    sections: new SectionCollection ENV.SECTIONS
    params: fetchOptions
  rolesCollection = new RolesCollection(new Role attributes for attributes in ENV.ALL_ROLES)
  course = new Model(ENV.course)
  inputFilterView = new InputFilterView
    collection: users
  usersView = new PaginatedCollectionView
    collection: users
    itemView: RosterUserView
    itemViewOptions:
      course: ENV.course
    canViewLoginIdColumn: ENV.permissions.manage_admin_users or ENV.permissions.manage_students
    buffer: 1000
    template: rosterUsersTemplate
  roleSelectView = new RoleSelectView
    collection: users
    rolesCollection: rolesCollection
  createUsersView = new CreateUsersView
    collection: users
    rolesCollection: rolesCollection
    model: new CreateUserList
      sections: ENV.SECTIONS
      roles: ENV.ALL_ROLES
      readURL: ENV.USER_LISTS_URL
      updateURL: ENV.ENROLL_USERS_URL
    courseModel: course
  resendInvitationsView = new ResendInvitationsView
    model: course
    resendInvitationsUrl: ENV.resend_invitations_url
    canResend: ENV.permissions.manage_students or ENV.permissions.manage_admin_users
  groupCategories = new (GroupCategoryCollection.extend({url: "/api/v1/courses/#{ENV.course?.id}/group_categories?per_page=50"}))

  rosterTabsView = new RosterTabsView
    collection: groupCategories

  rosterTabsView.fetch()

  @app = new RosterView
    usersView: usersView
    rosterTabsView: rosterTabsView
    inputFilterView: inputFilterView
    roleSelectView: roleSelectView
    createUsersView: createUsersView
    resendInvitationsView: resendInvitationsView
    collection: users
    roles: ENV.ALL_ROLES
    permissions: ENV.permissions
    course: ENV.course

  users.once 'reset', ->
    users.on 'reset', ->
      numUsers = users.length
      if numUsers is 0
        msg = I18n.t "filter_no_users_found", "No matching users found."
      else if numUsers is 1
        msg = I18n.t "filter_one_user_found", "1 user found."
      else
        msg = I18n.t "filter_multiple_users_found", "%{userCount} users found.", userCount: numUsers
      $('#aria_alerts').empty().text msg


  @app.render()
  @app.$el.appendTo $('#content')
  users.fetch()

