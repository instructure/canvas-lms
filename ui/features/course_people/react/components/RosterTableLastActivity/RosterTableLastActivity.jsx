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
import {arrayOf, object} from 'prop-types'
import {Tooltip} from '@instructure/ui-tooltip'
import {datetimeString} from '@canvas/datetime/date-functions'

const OBSERVER_ENROLLMENT = 'ObserverEnrollment'

const RosterTableLastActivity = ({enrollments}) => {
  const lastActivityComponents = enrollments.map(enrollment => {
    if (enrollment.type === OBSERVER_ENROLLMENT) return null
    if (enrollment.lastActivityAt === null) return null

    return (
      <div key={`last-activity-${enrollment.id}`}>
        <Tooltip
          renderTip={datetimeString(enrollment.lastActivityAt, {timezone: ENV.CONTEXT_TIMEZONE})}
        >
          {datetimeString(enrollment.lastActivityAt, {timezone: ENV.TIMEZONE})}
        </Tooltip>
      </div>
    )
  })

  return lastActivityComponents
}

RosterTableLastActivity.propTypes = {
  enrollments: arrayOf(object),
}

RosterTableLastActivity.defaultProps = {
  enrollments: [],
}

export default RosterTableLastActivity
