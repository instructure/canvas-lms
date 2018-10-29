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
import I18n from 'i18n!speed_grader'

function getDateKey(date) {
  return timezone.format(date, '%F')
}

function trackFeaturesOverall(auditEvents) {
  let anonymousGradingWasUsed = false
  let moderatedGradingWasUsed = false
  let mutingWasUsed = false

  auditEvents.forEach(auditEvent => {
    if (auditEvent.eventType === 'assignment_created') {
      anonymousGradingWasUsed = anonymousGradingWasUsed || auditEvent.payload.anonymous_grading
      moderatedGradingWasUsed = moderatedGradingWasUsed || auditEvent.payload.moderated_grading
      mutingWasUsed = mutingWasUsed || auditEvent.payload.muted
    }

    if (auditEvent.eventType === 'assignment_updated') {
      anonymousGradingWasUsed = anonymousGradingWasUsed || 'anonymous_grading' in auditEvent.payload
      moderatedGradingWasUsed = moderatedGradingWasUsed || 'moderated_grading' in auditEvent.payload
      mutingWasUsed = mutingWasUsed || 'muted' in auditEvent.payload
    }
  })

  return {
    anonymousGradingWasUsed,
    moderatedGradingWasUsed,
    mutingWasUsed
  }
}

function extractEvent(eventDatum, eventType, payload) {
  const {anonymous, auditEvent} = eventDatum

  return {
    anonymous,
    auditEvent: {
      ...auditEvent,
      eventType,
      id: `${auditEvent.id}.${eventType}`,
      payload
    }
  }
}

function extractEvents(eventDatum, featureTracking) {
  const eventData = [eventDatum]
  const {
    auditEvent: {eventType, payload}
  } = eventDatum

  if (eventType === 'assignment_created') {
    const addCreateEvent = (newEventType, payloadKey) => {
      eventData.push(extractEvent(eventDatum, newEventType, {[payloadKey]: payload[payloadKey]}))
    }

    if (featureTracking.anonymousGradingWasUsed) {
      // Anonymous Grading was enabled at some point.
      // Capture its initial state in its own audit event.
      addCreateEvent('student_anonymity_updated', 'anonymous_grading')
    }

    // Moderated Grading was enabled at some point.
    // Capture the initial state of related attributes in their own audit
    // events.
    if (featureTracking.moderatedGradingWasUsed) {
      addCreateEvent('grader_to_grader_anonymity_updated', 'graders_anonymous_to_graders')

      addCreateEvent(
        'grader_to_final_grader_anonymity_updated',
        'grader_names_visible_to_final_grader'
      )

      addCreateEvent(
        'grader_to_grader_comment_visibility_updated',
        'grader_comments_visible_to_graders'
      )

      if (payload.moderated_grading) {
        // When moderated grading is not applied at assignment creation, grader
        // count will not be relevant and will not be included in the audit
        // trail until moderated grading is later enabled.
        addCreateEvent('grader_count_updated', 'grader_count')
      }
    }

    if (featureTracking.mutingWasUsed) {
      const newEventType = payload.muted ? 'assignment_muted' : 'assignment_unmuted'
      addCreateEvent(newEventType, 'muted')
    }
  }

  if (eventType === 'assignment_updated') {
    const maybeAddUpdateEvent = (newEventType, payloadKey) => {
      // [0] is the value before the change
      // [1] is the value after the change
      if (payload[payloadKey][1] !== payload[payloadKey][0]) {
        eventData.push(
          extractEvent(eventDatum, newEventType, {[payloadKey]: payload[payloadKey][1]})
        )
      }
    }

    if ('anonymous_grading' in payload) {
      maybeAddUpdateEvent('student_anonymity_updated', 'anonymous_grading')
    }

    if ('graders_anonymous_to_graders' in payload) {
      maybeAddUpdateEvent('grader_to_grader_anonymity_updated', 'graders_anonymous_to_graders')
    }

    if ('grader_names_visible_to_final_grader' in payload) {
      maybeAddUpdateEvent(
        'grader_to_final_grader_anonymity_updated',
        'grader_names_visible_to_final_grader'
      )
    }

    if ('grader_comments_visible_to_graders' in payload) {
      maybeAddUpdateEvent(
        'grader_to_grader_comment_visibility_updated',
        'grader_comments_visible_to_graders'
      )
    }

    if ('grader_count' in payload) {
      if (!('moderated_grading' in payload) || payload.moderated_grading[1]) {
        // When moderated grading is being disabled, the grader count is
        // irrelevant and will not be included in the audit trail.
        maybeAddUpdateEvent('grader_count_updated', 'grader_count')
      }
    }

    if ('muted' in payload) {
      const newEventType = payload.muted[1] ? 'assignment_muted' : 'assignment_unmuted'
      maybeAddUpdateEvent(newEventType, 'muted')
    }
  }

  return eventData
}

/*
 * Audit trail data is structured as follows:
 * {
 *   anonymousGradingWasUsed: `boolean`,
 *   moderatedGradingWasUsed: `boolean`,
 *   mutingWasUsed: `boolean`,
 *   [userId]: {
 *     anonymousOnly: `boolean`,
 *     dateEventGroups: [`DateEventGroup`]
 *   }
 * }
 *
 * - `anonymousGradingWasUsed` indicate whether or not anonymous grading was
 *   enabled at any time within the audit trail.
 * - `moderatedGradingWasUsed` indicate whether or not moderated grading was
 *   enabled at any time within the audit trail.
 * - `mutingWasUsed` indicate whether or not the assignment was muted at any
 *   time within the audit trail.
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
export default function buildAuditTrail(auditData) {
  const {auditEvents, users} = auditData
  if (!auditEvents) {
    return {}
  }

  const usersById = {}
  users.forEach(user => { usersById[user.id] = user })

  // sort in ascending order (earliest event to most recent)
  const sortedEvents = [...auditEvents].sort((a, b) => a.createdAt - b.createdAt)
  const userEventGroups = {}

  const featureTracking = trackFeaturesOverall(sortedEvents)

  sortedEvents.forEach(auditEvent => {
    const {userId} = auditEvent
    // We hope we won't ever get events keyed to a user that doesn't exist, but
    // better safe than sorry
    const user = usersById[userId] || {id: userId, name: I18n.t('Unknown User'), role: 'unknown'}

    userEventGroups[userId] = userEventGroups[userId] || {dateEventGroups: [], user}
    const {dateEventGroups} = userEventGroups[userId]

    const dateKey = getDateKey(auditEvent.createdAt)

    const lastDateGroup = dateEventGroups[dateEventGroups.length - 1]
    const eventDatum = {
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
    const eventData = extractEvents(eventDatum, featureTracking)

    if (lastDateGroup && lastDateGroup.startDateKey === dateKey) {
      lastDateGroup.auditEvents.push(...eventData)
    } else {
      dateEventGroups.push({
        auditEvents: eventData,
        startDate: auditEvent.createdAt,
        startDateKey: dateKey
      })
    }
  })

  return {
    anonymousGradingWasUsed: featureTracking.anonymousGradingWasUsed,
    moderatedGradingWasUsed: featureTracking.moderatedGradingWasUsed,
    mutingWasUsed: featureTracking.mutingWasUsed,
    userEventGroups
  }
}
