/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment-timezone'

import {countByCourseId} from '../react/utils'

export const mapStateToProps = ({days, opportunities, timeZone}) => {
  const props = {assignmentsDueToday: {}, assignmentsMissing: {}, assignmentsCompletedForToday: {}}
  const todaysDate = moment.tz(timeZone).format('YYYY-MM-DD')
  const today = days?.length > 0 && days.find(([date]) => date === todaysDate)
  if (today?.length === 2 && today[1]?.length > 0) {
    props.assignmentsDueToday = countByCourseId(
      today[1].filter(({status}) => status && !status.submitted)
    )
    props.assignmentsCompletedForToday = countByCourseId(
      today[1].filter(({status}) => status && status.submitted)
    )
  }
  if (opportunities?.items?.length > 0) {
    props.assignmentsMissing = countByCourseId(
      opportunities.items.filter(({planner_override}) => !planner_override?.dismissed)
    )
  }
  return props
}
