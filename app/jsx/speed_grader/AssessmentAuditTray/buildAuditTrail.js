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

import timezone from 'timezone_core'

function getDateKey(date) {
  return timezone.format(date, '%F')
}

/*
 * Audit trail data is structured as follows:
 * {
 *   [userId]: {
 *     anonymousOnly: `boolean`,
 *     dateEventGroups: [`DateEventGroup`]
 *   }
 * }
 *
 * A `DateEventGroup` is an object containing audit event data from a specific
 * date. It is structured as follows:
 *
 * {
 *   auditEvents: [`AuditEventDatum`],
 *   startDate: `Date`
 * }
 *
 * - `startDate` is the earliest `createdAt` date from the audit events in this
 *   group.
 * - `auditEvents` is an array of `AuditEventDatum`, sorted by `createdAt` on
 *   the contained event, in ascending order.
 *
 * An `AuditEventDatum` is an object containing an audit event and other
 * information related to the audit trail specific to this event. It is
 * structured as follows:
 *
 * {
 *   anonymous: `boolean`,
 *   auditEvent: `AuditEvent`
 * }
 */
export default function buildAuditTrail(auditEvents) {
  // sort in ascending order (earliest event to most recent)
  const sortedEvents = [...auditEvents].sort((a, b) => a.createdAt - b.createdAt)
  const userEventGroups = {}

  sortedEvents.forEach(auditEvent => {
    userEventGroups[auditEvent.userId] = userEventGroups[auditEvent.userId] || {dateEventGroups: []}
    const {dateEventGroups} = userEventGroups[auditEvent.userId]

    const dateKey = getDateKey(auditEvent.createdAt)

    const lastDateGroup = dateEventGroups[dateEventGroups.length - 1]
    const eventData = {
      /*
       * TODO: GRADE-1668
       * This `anonymous` value is only a placeholder so that the related part
       * of the UI can be displayed, for QA/PR purposes.  This will be replaced
       * with logic for specifying whether or not anonymity was enabled when
       * this event occurred.
       */
      anonymous: Math.random() >= 0.5,
      auditEvent
    }

    if (lastDateGroup && lastDateGroup.startDateKey === dateKey) {
      lastDateGroup.auditEvents.push(eventData)
    } else {
      dateEventGroups.push({
        auditEvents: [eventData],
        startDate: auditEvent.createdAt,
        startDateKey: dateKey
      })
    }
  })

  return {userEventGroups}
}
