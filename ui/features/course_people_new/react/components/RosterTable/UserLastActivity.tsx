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
import {View} from '@instructure/ui-view'
import {timeEventToString} from '../../../util/utils'
import {OBSERVER_ENROLLMENT} from '../../../util/constants'
import {Enrollment} from '../../../types'

const UserLastActivity: FC<{enrollments: Enrollment[]}> = ({enrollments}) => (
  enrollments.map(enrollment => {
    if (enrollment.type === OBSERVER_ENROLLMENT) return null
    if (!enrollment.lastActivityAt) return null

    return (
      <View as="div" key={`last-activity-${enrollment._id}`} data-testid={`last-activity-${enrollment._id}`}>
        {timeEventToString(enrollment.lastActivityAt)}
      </View>
    )
  })
)

export default UserLastActivity
