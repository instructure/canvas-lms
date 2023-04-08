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

import ready from '@instructure/ready'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Model} from '@canvas/backbone'
import Role from './backbone/models/Role'
import RoleSelectView from './backbone/views/RoleSelectView'
import rosterUsersTemplate from './jst/rosterUsers.handlebars'
import RosterUserCollection from './backbone/collections/RosterUserCollection'
import RolesCollection from './backbone/collections/RolesCollection'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import GroupCategoryCollection from '@canvas/groups/backbone/collections/GroupCategoryCollection'
import InputFilterView from '@canvas/backbone-input-filter-view'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import RosterUserView from './backbone/views/RosterUserView'
import RosterView from './backbone/views/RosterView'
import RosterTabsView from './backbone/views/RosterTabsView'
import ResendInvitationsView from './backbone/views/ResendInvitationsView'
import $ from 'jquery'
import '@canvas/context-cards/react/StudentContextCardTrigger'

const I18n = useI18nScope('roster_publicjs')

const fetchOptions = {
  include: [
    'avatar_url',
    'enrollments',
    'email',
    'observed_users',
    'can_be_removed',
    'custom_links',
  ],
  per_page: 50,
}
const users = new RosterUserCollection(null, {
  course_id: ENV.context_asset_string.split('_')[1],
  sections: new SectionCollection(ENV.SECTIONS),
  params: fetchOptions,
})
const rolesCollection = new RolesCollection(
  Array.from(ENV.ALL_ROLES).map(attributes => new Role(attributes))
)
const course = new Model(ENV.course)
const inputFilterView = new InputFilterView({collection: users, minLength: 2})
const usersView = new PaginatedCollectionView({
  collection: users,
  itemView: RosterUserView,
  itemViewOptions: {
    course: ENV.course,
  },
  canViewLoginIdColumn: ENV.permissions.view_user_logins,
  canViewSisIdColumn: ENV.permissions.read_sis,
  buffer: 1000,
  hideSectionsOnCourseUsersPage: ENV.course.hideSectionsOnCourseUsersPage,
  template: rosterUsersTemplate,
})
const roleSelectView = new RoleSelectView({
  collection: users,
  rolesCollection,
})
const resendInvitationsView = new ResendInvitationsView({
  model: course,
  resendInvitationsUrl: ENV.resend_invitations_url,
  canResend:
    ENV.permissions.manage_students ||
    ENV.permissions.manage_admin_users ||
    ENV.permissions.can_allow_course_admin_actions,
})

class GroupCategoryCollectionForThisCourse extends GroupCategoryCollection {}
GroupCategoryCollectionForThisCourse.prototype.url = `/api/v1/courses/${
  ENV.course && ENV.course.id
}/group_categories?per_page=50`

const groupCategories = new GroupCategoryCollectionForThisCourse()

const rosterTabsView = new RosterTabsView({collection: groupCategories})

rosterTabsView.fetch()

const app = new RosterView({
  usersView,
  rosterTabsView,
  inputFilterView,
  roleSelectView,
  resendInvitationsView,
  collection: users,
  roles: ENV.ALL_ROLES,
  permissions: ENV.permissions,
  course: ENV.course,
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
      msg = I18n.t('filter_multiple_users_found', '%{userCount} users found.', {
        userCount: numUsers,
      })
    }
    return $('#aria_alerts').empty().text(msg)
  })
)

app.render()
ready(() => app.$el.appendTo($('#content')))
users.fetch()
