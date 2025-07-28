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

import {useScope as createI18nScope} from '@canvas/i18n'
import {EnvRole, SortField, SortDirection} from '../types'

const I18n = createI18nScope('course_people')

export const NO_PERMISSIONS = 'NoPermissions'
export const ACCOUNT_MEMBERSHIP = 'AccountMembership'
export const TEACHER_ENROLLMENT = 'TeacherEnrollment'
export const STUDENT_ENROLLMENT = 'StudentEnrollment'
export const TA_ENROLLMENT = 'TaEnrollment'
export const OBSERVER_ENROLLMENT = 'ObserverEnrollment'
export const DESIGNER_ENROLLMENT = 'DesignerEnrollment'

export const ACTIVE_ENROLLMENT = 'active'
export const INACTIVE_ENROLLMENT = 'inactive'
export const PENDING_ENROLLMENT = 'invited'

export const TEACHER_ROLE = 'teacher'
export const TA_ROLE = 'ta'
export const STUDENT_ROLE = 'student'
export const OBSERVER_ROLE = 'observer'
export const DESIGNER_ROLE = 'designer'

export const ACCOUNT_ADMIN = 'AccountAdmin'

export const ASCENDING = 'ascending'
export const DESCENDING = 'descending'
export const ASC = 'asc'
export const DESC = 'desc'

export const DEFAULT_OPTION: EnvRole = {
  addable_by_user: false,
  base_role_name: undefined,
  count: 0,
  deleteable_by_user: false,
  id: 'all_roles',
  label: I18n.t('All Roles'),
  name: I18n.t('All Roles'),
  plural_label: I18n.t('All Roles'),
}

export const SORTABLE_FIELDS = [
  'name',
  'login_id',
  'sis_id',
  'section_name',
  'role',
  'last_activity_at',
  'total_activity_time',
] as SortField[]

export const DEFAULT_SORT_FIELD = 'name' as SortField
export const DEFAULT_SORT_DIRECTION = 'asc' as SortDirection

export const DEFAULT_ENROLLMENTS_SORT_FIELD = 'section_name' as SortField
export const DEFAULT_ENROLLMENTS_SORT_DIRECTION = 'asc' as SortDirection

export const MULTI_VALUE_SORT_FIELDS = ['section_name', 'last_activity_at', 'role'] as SortField[]
