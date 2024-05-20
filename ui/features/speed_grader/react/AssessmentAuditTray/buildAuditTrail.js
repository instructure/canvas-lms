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

import * as timezone from '@canvas/datetime'
import {useScope as useI18nScope} from '@canvas/i18n'
import {auditEventStudentAnonymityStates, overallAnonymityStates} from './AuditTrailHelpers'

const I18n = useI18nScope('speed_grader')

const {OFF, ON, TURNED_OFF, TURNED_ON} = auditEventStudentAnonymityStates
const {FULL, PARTIAL} = overallAnonymityStates
const roleOrder = ['student', 'grader', 'final_grader', 'admin']

function getRolePosition(user) {
  const index = roleOrder.indexOf(user.role)
  return index >= 0 ? index : roleOrder.length
}

function buildUnknownUser(userId) {
  return {
    id: userId,
    key: `user-${userId}`,
    name: I18n.t('Unknown User'),
    role: 'unknown',
    type: 'user',
  }
}

function buildUnknownExternalTool(externalToolId) {
  return {
    id: externalToolId,
    key: `externalTool-${externalToolId}`,
    name: I18n.t('Unknown External Tool'),
    role: 'grader',
    type: 'externalTool',
  }
}

function buildUnknownQuiz(quizId) {
  return {
    id: quizId,
    key: `quiz-${quizId}`,
    name: I18n.t('Unknown Quiz'),
    role: 'grader',
    type: 'quiz',
  }
}

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
    mutingWasUsed,
  }
}

function extractEvent(eventDatum, eventType, payload) {
  const {auditEvent, studentAnonymity} = eventDatum

  let specificAnonymity = studentAnonymity
  if (eventType === 'student_anonymity_updated') {
    specificAnonymity = studentAnonymity === ON ? TURNED_ON : TURNED_OFF
  }

  return {
    auditEvent: {
      ...auditEvent,
      eventType,
      id: `${auditEvent.id}.${eventType}`,
      payload,
    },
    studentAnonymity: specificAnonymity,
  }
}

function extractEvents(eventDatum, featureTracking) {
  const eventData = [eventDatum]
  const {
    auditEvent: {eventType, payload},
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

function getCurrentAnonymity({eventType, payload}, currentlyAnonymous) {
  if (eventType === 'assignment_created') {
    return payload.anonymous_grading
  }

  if (eventType === 'assignment_updated' && 'anonymous_grading' in payload) {
    // [1] is the value after the change
    return payload.anonymous_grading[1]
  }

  return currentlyAnonymous
}

function changesFinalGrade({eventType}) {
  /*
   * Selecting a provisional grade for a moderated assignment is considered the
   * "final grade date" of the audit for the related student. For a
   * non-moderated assignment, the date of the last grade change on the
   * submission is used. At this time, every "submission_updated" event is a
   * grade change event.
   */
  return eventType === 'provisional_grade_selected' || eventType === 'submission_updated'
}

function laterDate(dateA, dateB) {
  return dateA == null || dateB - dateA > 0 ? dateB : dateA
}

function buildAnonymityTracker() {
  // Track how many times each feature was enabled
  const anonymityTurnedOnCounts = {
    graderToFinalGrader: 0,
    graderToGrader: 0,
    student: 0,
  }

  let anonymityDate = null

  function update(eventData) {
    eventData.forEach(({auditEvent: {createdAt, eventType, payload}}) => {
      if (eventType === 'grader_to_final_grader_anonymity_updated') {
        if (!payload.grader_names_visible_to_final_grader) {
          anonymityTurnedOnCounts.graderToFinalGrader++
          anonymityDate = laterDate(anonymityDate, createdAt)
        }
      } else if (eventType === 'grader_to_grader_anonymity_updated') {
        if (payload.graders_anonymous_to_graders) {
          anonymityTurnedOnCounts.graderToGrader++
          anonymityDate = laterDate(anonymityDate, createdAt)
        }
      } else if (eventType === 'student_anonymity_updated') {
        if (payload.anonymous_grading) {
          anonymityTurnedOnCounts.student++
          anonymityDate = laterDate(anonymityDate, createdAt)
        }
      }
    })
  }

  function getAnonymityDate() {
    return anonymityDate
  }

  function getOverallAnonymity() {
    const maxEnableCount = Math.max(...Object.values(anonymityTurnedOnCounts))
    if (maxEnableCount > 1) {
      // When a feature was enabled more than once,
      // this means it was temporarily disabled.
      return PARTIAL
    }

    if (maxEnableCount === 1) {
      // When a feature was enabled only once,
      // this means it was used without interruption.
      return FULL
    }

    // When no feature was used, anonymity does not apply.
    return overallAnonymityStates.NA
  }

  return {
    getAnonymityDate,
    getOverallAnonymity,
    update,
  }
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
 * - Within the user event map, `anonymousOnly` indicates whether or not the
 *   user performed actions only when student anonymity was enabled.
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
  const {auditEvents, users, externalTools, quizzes} = auditData
  if (!auditEvents) {
    return {}
  }

  const usersById = {}
  users.forEach(user => {
    user.key = `user-${user.id}`
    user.type = 'user'
    usersById[user.id] = user
  })

  const externalToolsById = {}
  externalTools.forEach(tool => {
    tool.key = `externalTool-${tool.id}`
    tool.type = 'externalTool'
    externalToolsById[tool.id] = tool
  })

  const quizzesById = {}
  quizzes.forEach(quiz => {
    quiz.key = `quiz-${quiz.id}`
    quiz.type = 'quiz'
    quizzesById[quiz.id] = quiz
  })

  // sort in ascending order (earliest event to most recent)
  const sortedEvents = [...auditEvents].sort((a, b) => a.createdAt - b.createdAt)
  const creatorEventGroupsByCreatorId = {}

  const featureTracking = trackFeaturesOverall(sortedEvents)
  const anonymityTracker = buildAnonymityTracker()

  let currentlyAnonymous = false
  let finalGradeDate = null

  sortedEvents.forEach(auditEvent => {
    const {createdAt, userId, externalToolId, quizId} = auditEvent

    let creator = null
    if (externalToolId != null) {
      creator = externalToolsById[externalToolId] || buildUnknownExternalTool[externalToolId]
    } else if (quizId != null) {
      creator = quizzesById[quizId] || buildUnknownQuiz[quizId]
    } else {
      // If the key type is unknown, we'll treat it like a user.
      // In the event we do not have user info loaded for this user id, for
      // whatever reason, the user still needs to be represented in the UI.
      // Use an "Unknown User" as a fallback.
      creator = usersById[userId] || buildUnknownUser(userId)
    }
    const creatorKey = creator.key

    currentlyAnonymous = getCurrentAnonymity(auditEvent, currentlyAnonymous)

    creatorEventGroupsByCreatorId[creatorKey] = creatorEventGroupsByCreatorId[creatorKey] || {
      anonymousOnly: currentlyAnonymous,
      dateEventGroups: [],
      creator,
    }
    creatorEventGroupsByCreatorId[creatorKey].anonymousOnly =
      creatorEventGroupsByCreatorId[creatorKey].anonymousOnly && currentlyAnonymous

    const {dateEventGroups} = creatorEventGroupsByCreatorId[creatorKey]
    const lastDateGroup = dateEventGroups[dateEventGroups.length - 1]

    const eventDatum = {auditEvent}
    if (featureTracking.anonymousGradingWasUsed) {
      eventDatum.studentAnonymity = currentlyAnonymous ? ON : OFF
    } else {
      eventDatum.studentAnonymity = auditEventStudentAnonymityStates.NA
    }

    if (changesFinalGrade(auditEvent)) {
      finalGradeDate = createdAt
    }

    const eventData = extractEvents(eventDatum, featureTracking)
    anonymityTracker.update(eventData)

    const dateKey = getDateKey(createdAt)
    if (lastDateGroup && lastDateGroup.startDateKey === dateKey) {
      lastDateGroup.auditEvents.push(...eventData)
    } else {
      dateEventGroups.push({
        auditEvents: eventData,
        startDate: createdAt,
        startDateKey: dateKey,
      })
    }
  })

  const creatorEventGroups = Object.values(creatorEventGroupsByCreatorId).sort((groupA, groupB) => {
    const rolePositionA = getRolePosition(groupA.creator)
    const rolePositionB = getRolePosition(groupB.creator)

    if (rolePositionA === rolePositionB) {
      const [{auditEvent: auditEventA}] = groupA.dateEventGroups[0].auditEvents
      const [{auditEvent: auditEventB}] = groupB.dateEventGroups[0].auditEvents
      return auditEventA.createdAt - auditEventB.createdAt
    }

    return rolePositionA - rolePositionB
  })

  return {
    ...featureTracking,
    anonymityDate: anonymityTracker.getAnonymityDate(),
    finalGradeDate,
    overallAnonymity: anonymityTracker.getOverallAnonymity(),
    creatorEventGroups,
  }
}
