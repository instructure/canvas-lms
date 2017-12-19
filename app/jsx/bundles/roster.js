/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!roster'
import { Model } from 'Backbone'
import CreateUserList from 'compiled/models/CreateUserList'
import Role from 'compiled/models/Role'
import CreateUsersView from 'compiled/views/courses/roster/CreateUsersView'
import RoleSelectView from 'compiled/views/courses/roster/RoleSelectView'
import rosterUsersTemplate from 'jst/courses/roster/rosterUsers'
import RosterUserCollection from 'compiled/collections/RosterUserCollection'
import RolesCollection from 'compiled/collections/RolesCollection'
import SectionCollection from 'compiled/collections/SectionCollection'
import GroupCategoryCollection from 'compiled/collections/GroupCategoryCollection'
import InputFilterView from 'compiled/views/InputFilterView'
import PaginatedCollectionView from 'compiled/views/PaginatedCollectionView'
import RosterUserView from 'compiled/views/courses/roster/RosterUserView'
import RosterView from 'compiled/views/courses/roster/RosterView'
import RosterTabsView from 'compiled/views/courses/roster/RosterTabsView'
import ResendInvitationsView from 'compiled/views/courses/roster/ResendInvitationsView'
import $ from 'jquery'
import '../context_cards/StudentContextCardTrigger'

const fetchOptions = {
  include: ['avatar_url', 'enrollments', 'email', 'observed_users', 'can_be_removed', 'custom_links'],
  per_page: 50
}
const users = new RosterUserCollection(null, {
  course_id: ENV.context_asset_string.split('_')[1],
  sections: new SectionCollection(ENV.SECTIONS),
  params: fetchOptions
})
const rolesCollection = new RolesCollection(Array.from(ENV.ALL_ROLES).map(attributes => new Role(attributes)))
const course = new Model(ENV.course)
const inputFilterView = new InputFilterView({collection: users})
const usersView = new PaginatedCollectionView({
  collection: users,
  itemView: RosterUserView,
  itemViewOptions: {
    course: ENV.course
  },
  canViewLoginIdColumn: ENV.permissions.manage_admin_users || ENV.permissions.manage_students,
  canViewSisIdColumn: ENV.permissions.read_sis,
  buffer: 1000,
  template: rosterUsersTemplate
})
const roleSelectView = new RoleSelectView({
  collection: users,
  rolesCollection
})
const createUsersView = new CreateUsersView({
  collection: users,
  rolesCollection,
  model: new CreateUserList({
    sections: ENV.SECTIONS,
    roles: ENV.ALL_ROLES,
    readURL: ENV.USER_LISTS_URL,
    updateURL: ENV.ENROLL_USERS_URL
  }),
  courseModel: course
})
const resendInvitationsView = new ResendInvitationsView({
  model: course,
  resendInvitationsUrl: ENV.resend_invitations_url,
  canResend: ENV.permissions.manage_students || ENV.permissions.manage_admin_users
})

const groupCategories = new (GroupCategoryCollection.extend({
  url: `/api/v1/courses/${ENV.course && ENV.course.id}/group_categories?per_page=50`
}))()

const rosterTabsView = new RosterTabsView({collection: groupCategories})

rosterTabsView.fetch()

const app = new RosterView({
  usersView,
  rosterTabsView,
  inputFilterView,
  roleSelectView,
  createUsersView,
  resendInvitationsView,
  collection: users,
  roles: ENV.ALL_ROLES,
  permissions: ENV.permissions,
  course: ENV.course
})

users.once('reset', () =>
  users.on('reset', () => {
    let msg
    const numUsers = users.length
    if (numUsers === 0) {
      msg = I18n.t('filter_no_users_found', 'No matching users found.')
    } else if (numUsers === 1) {
      msg = I18n.t('filter_one_user_found', '1 user found.')
    } else {
      msg = I18n.t('filter_multiple_users_found', '%{userCount} users found.', {userCount: numUsers})
    }
    return $('#aria_alerts').empty().text(msg)
  })
)

app.render()
app.$el.appendTo($('#content'))
users.fetch()
