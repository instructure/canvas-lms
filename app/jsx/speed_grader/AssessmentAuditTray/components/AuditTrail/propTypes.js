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

import {arrayOf, bool, instanceOf, oneOf, shape, string} from 'prop-types'

import {auditEventStudentAnonymityStates, overallAnonymityStates} from '../../AuditTrailHelpers'

export const auditEvent = shape({
  eventType: string.isRequired
})

export const auditEventInfo = {
  auditEvent: auditEvent.isRequired,
  studentAnonymity: oneOf(Object.values(auditEventStudentAnonymityStates)).isRequired
}

export const dateEventGroup = shape({
  auditEvents: arrayOf(shape(auditEventInfo)).isRequired,
  startDate: instanceOf(Date).isRequired,
  startDateKey: string.isRequired
})

export const user = shape({
  id: string.isRequired,
  name: string.isRequired,
  role: string.isRequired
})

export const userEventGroup = shape({
  anonymousOnly: bool.isRequired,
  dateEventGroups: arrayOf(dateEventGroup).isRequired,
  user: user.isRequired
})

export const anonymityDate = instanceOf(Date)
export const finalGradeDate = instanceOf(Date)
export const overallAnonymity = oneOf(Object.values(overallAnonymityStates))

export const auditTrail = shape({
  anonymityDate,
  finalGradeDate: finalGradeDate.isRequired,
  overallAnonymity: overallAnonymity.isRequired,
  userEventGroups: arrayOf(userEventGroup).isRequired
})
