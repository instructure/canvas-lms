/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {arrayOf, string, shape} from 'prop-types'
import {readableRoleName} from '@canvas/k5/react/utils'
import {Text} from '@instructure/ui-text'
import {OBSERVER_ENROLLMENT} from '../../../util/constants'

const I18n = useI18nScope('course_people')
const DEFAULT_ROLES = ['student', 'ta', 'observer', 'designer', 'teacher']

export const getRoleName = ({sisRole, type}) => {
  if (DEFAULT_ROLES.includes(sisRole)) {
    return readableRoleName(type)
  }
  return sisRole || readableRoleName(type)
}

const RosterTableRoles = ({enrollments}) => {
  const enrollmentRoles = enrollments.map(enrollment => {
    const {type, associatedUser, id} = enrollment

    if (type === OBSERVER_ENROLLMENT) {
      return associatedUser ? (
        <Text as="div" wrap="break-word" key={`role-${associatedUser.id}`}>
          {I18n.t('Observing: %{user_name}', {user_name: associatedUser.name})}
        </Text>
      ) : null
    }
    return (
      <Text as="div" wrap="break-word" key={`role-${id}`}>
        {getRoleName(enrollment)}
      </Text>
    )
  })

  return enrollmentRoles
}

RosterTableRoles.propTypes = {
  enrollments: arrayOf(
    shape({
      sisRole: string.isRequired,
      type: string.isRequired,
      id: string.isRequired,
      associatedUser: shape({
        id: string.isRequired,
        name: string.isRequired,
      }),
    })
  ).isRequired,
}

RosterTableRoles.defaultProps = {
  enrollments: [],
}

export default RosterTableRoles
