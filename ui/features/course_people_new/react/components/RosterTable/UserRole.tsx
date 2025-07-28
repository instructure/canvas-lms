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

import React, {type FC} from 'react'
import {Text} from '@instructure/ui-text'
import {getRoleName} from '../../../util/utils'
import {OBSERVER_ROLE} from '../../../util/constants'
import type {Enrollment} from '../../../types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

const UserRole: FC<{enrollments: Enrollment[]}> = ({enrollments}) => (
  enrollments.map(enrollment => {
    const {_id: id, sisRole, associatedUser, temporaryEnrollmentSourceUserId} = enrollment

    let roleName = getRoleName(sisRole)

    if (temporaryEnrollmentSourceUserId) {
      roleName = I18n.t('Temporary: %{roleName}', {roleName})
    }

    if (sisRole === OBSERVER_ROLE){
      if (associatedUser) {
        roleName = I18n.t('Observing: %{userName}', {userName: associatedUser.name})
      } else {
        return null
      }
    }

    return (
      <Text as="div" key={`enrollment-${id}`}>
        {roleName}
      </Text>
    )
  })
)

export default UserRole
