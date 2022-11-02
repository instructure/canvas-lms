/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {COURSE, ACCOUNT, ENABLED_FOR_ALL} from '@canvas/permissions/react/propTypes'

const PERMISSIONS = [
  {
    permission_name: 'add_section',
    label: 'add section',
    contextType: COURSE,
    displayed: true,
  },
  {
    permission_name: 'delete_section',
    label: 'delete section',
    contextType: COURSE,
    displayed: true,
  },
  {
    permission_name: 'add_course',
    label: 'add course',
    contextType: ACCOUNT,
    displayed: false,
  },
  {
    permission_name: 'delete_course',
    label: 'delete course',
    contextType: ACCOUNT,
    displayed: false,
  },
]

const BASIC_ROLE_PERMISSION = {
  enabled: ENABLED_FOR_ALL,
  explicit: true,
  locked: true,
  readonly: true,
  applies_to_decendants: true,
  applies_to_self: true,
}

const ROLES = [
  {
    id: '1',
    value: '1',
    label: 'Course Admin',
    base_role_type: 'Course Admin',
    contextType: COURSE,
    displayed: true,
    permissions: {
      add_section: BASIC_ROLE_PERMISSION,
      delete_section: BASIC_ROLE_PERMISSION,
    },
  },
  {
    id: '2',
    value: '2',
    label: 'Course Sub-Admin',
    base_role_type: 'Course Admin',
    contextType: COURSE,
    displayed: true,
    permissions: {
      add_section: BASIC_ROLE_PERMISSION,
      delete_section: BASIC_ROLE_PERMISSION,
    },
  },
  {
    id: '3',
    value: '3',
    label: 'Account Admin',
    base_role_type: 'Account Admin',
    contextType: ACCOUNT,
    displayed: false,
    permissions: {add_course: BASIC_ROLE_PERMISSION, delete_course: BASIC_ROLE_PERMISSION},
  },
  {
    id: '4',
    value: '4',
    label: 'Account Sub-admin',
    base_role_type: 'Account Admin',
    contextType: ACCOUNT,
    displayed: false,
    permissions: {add_course: BASIC_ROLE_PERMISSION, delete_course: BASIC_ROLE_PERMISSION},
  },
]

const DEFAULT_PROPS = () => ({
  contextId: 1,
  permissions: PERMISSIONS,
  roles: ROLES,
  selectedRoles: [{value: '0', label: 'All Roles'}],
})

export {DEFAULT_PROPS, PERMISSIONS, ROLES, BASIC_ROLE_PERMISSION}
