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

import {shape, string, bool, oneOf, object} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('permissions_v2_propTypes')

const propTypes = {}

export const COURSE = 'Course'
export const ACCOUNT = 'Account'
export const ALL_ROLES_VALUE = '0'
export const ALL_ROLES_LABEL = I18n.t('All Roles')

// Let's keep "none" as 0 and "all" as nonzero, so that in a pinch they
// will Boolean-cast to false and true respsectively. This is to get a
// bit of backward-compatibilty with the older Boolean type of the
// `enabled` prop.
export const ENABLED_FOR_NONE = 0
export const ENABLED_FOR_PARTIAL = 1
export const ENABLED_FOR_ALL = 2

const ENABLED_STATES = [ENABLED_FOR_NONE, ENABLED_FOR_PARTIAL, ENABLED_FOR_ALL]

propTypes.permissionDetails = shape({
  title: string.isRequired,
  description: string.isRequired,
})

propTypes.permission = shape({
  permission_name: string.isRequired,
  label: string.isRequired,
  contextType: oneOf([COURSE, ACCOUNT]),
  displayed: bool.isRequired,
})

propTypes.rolePermission = shape({
  enabled: oneOf(ENABLED_STATES).isRequired,
  explicit: bool.isRequired,
  locked: bool.isRequired,
  readonly: bool.isRequired,
  applies_to_descendants: bool,
  applies_to_self: bool,
})

propTypes.role = shape({
  id: string.isRequired,
  label: string.isRequired,
  base_role_type: string.isRequired,
  contextType: oneOf([COURSE, ACCOUNT]),
  displayed: bool.isRequired,
  permissions: object.isRequired, // eslint-disable-line, shape is indeterminate
})

propTypes.filteredRole = shape({
  label: string.isRequired,
  value: string.isRequired,
})

export default propTypes
