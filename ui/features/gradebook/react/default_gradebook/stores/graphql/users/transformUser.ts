/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Student} from 'api.d'
import {User} from './getUsers'

export const transformUser = (user: User): Student & Record<string, unknown> => ({
  id: user._id,
  name: user.name ?? '',
  sortable_name: user.sortableName ?? undefined,
  avatar_url: user.avatarUrl ?? undefined,
  first_name: user.firstName ?? '',
  last_name: user.lastName ?? '',
  enrollments: [],
  created_at: user.createdAt ?? '',
  email: user.email,
  integration_id: user.integrationId,
  login_id: user.loginId ?? '',
  short_name: user.shortName ?? '',
  sis_user_id: user.sisId,
  group_ids: user.groupMemberships.map(membership => membership.group._id),

  // The following attributes were provided by the legacy API,
  // but they are not defined in the type
  has_non_collaborative_groups: user.groupMemberships.some(
    membership => membership.group.nonCollaborative,
  ),

  // The following attributes are not used at all
  // only defining them to satisfy the type
  sis_import_id: null,

  // TODO what are these!!!
  index: 0,
  section_ids: [],
})
