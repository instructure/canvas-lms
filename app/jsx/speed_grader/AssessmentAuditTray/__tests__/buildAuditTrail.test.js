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
import newYork from 'timezone/America/New_York'

import buildAuditTrail from '../buildAuditTrail'
import {
  buildAssignmentCreatedEvent,
  buildAssignmentUpdatedEvent,
  buildEvent
} from './AuditTrailSpecHelpers'

describe('AssessmentAuditTray buildAuditTrail()', () => {
  let auditEvents
  let auditTrail
  let timezoneSnapshot
  let users

  const firstUser = {id: '1109', name: 'An extraordinarily prolific user', role: 'grader'}
  const secondUser = {id: '1101', name: 'A somewhat less prolific user', role: 'grader'}

  beforeEach(() => {
    timezoneSnapshot = timezone.snapshot()
    timezone.changeZone(newYork, 'America/New_York')

    auditEvents = []
    users = [firstUser, secondUser]
    auditTrail = null
  })

  afterEach(() => {
    timezone.restore(timezoneSnapshot)
  })

  function buildCreateEvent(payloadValues) {
    const payload = {
      anonymous_grading: false,
      anonymous_instructor_annotations: false,
      final_grader_id: '1102',
      grader_comments_visible_to_graders: true,
      grader_count: 0,
      grader_names_visible_to_final_grader: true,
      graders_anonymous_to_graders: false,
      moderated_grading: false,
      muted: false,
      ...payloadValues
    }
    auditEvents.push(
      buildAssignmentCreatedEvent({id: '4901', createdAt: '2018-09-01T12:00:00Z'}, payload)
    )
  }

  function buildUpdateEvent(id, createdAt, payload) {
    auditEvents.push(buildAssignmentUpdatedEvent({createdAt, id}, payload))
  }

  function getAuditEvents() {
    auditTrail = auditTrail || buildAuditTrail({auditEvents, users})
    const {dateEventGroups} = auditTrail.userEventGroups['1101']
    return dateEventGroups.reduce(
      (allEvents, dateEventGroup) => allEvents.concat(dateEventGroup.auditEvents),
      []
    )
  }

  function eventWasCreatedAt(eventDatum, createdAt) {
    return eventDatum.auditEvent.createdAt.valueOf() === new Date(createdAt).valueOf()
  }

  function filterAuditEvents(eventType, createdAt = null) {
    return getAuditEvents().filter(eventDatum => {
      if (eventDatum.auditEvent.eventType !== eventType) {
        return false
      }

      if (!createdAt) {
        return true
      }

      return eventWasCreatedAt(eventDatum, createdAt)
    })
  }

  describe('events by user id', () => {
    function buildUnknownEvent(id, createdAt, data = {}) {
      return buildEvent({id, createdAt, ...data})
    }

    function getDateGroupEventIds(dateEventGroup) {
      return dateEventGroup.auditEvents.map(({auditEvent}) => auditEvent.id)
    }

    it('is undefined when the user has no events', () => {
      auditTrail = buildAuditTrail({
        auditEvents: [buildUnknownEvent('4901', '2018-09-01T12:00:00Z')],
        users: [firstUser]
      })
      expect(auditTrail.userEventGroups['1109']).toBeUndefined()
    })

    it('sets .user with the related user data when the specified user is known', () => {
      auditTrail = buildAuditTrail({
        auditEvents: [buildEvent()],
        users: [secondUser]
      })
      expect(auditTrail.userEventGroups['1101'].user).toEqual(secondUser)
    })

    it('sets .user with "unknown user" data when the specified user is not known', () => {
      auditTrail = buildAuditTrail({
        auditEvents: [buildEvent()],
        users: []
      })
      expect(auditTrail.userEventGroups['1101'].user).toEqual({
        id: '1101',
        name: 'Unknown User',
        role: 'unknown'
      })
    })

    describe('when the user has only one event', () => {
      beforeEach(() => {
        auditTrail = buildAuditTrail({
          auditEvents: [buildUnknownEvent('4901', '2018-09-01T12:00:00Z')],
          users: [firstUser]
        })
      })

      it('includes one group of events when the user has only one event', () => {
        const userEventGroup = auditTrail.userEventGroups['1101']
        expect(userEventGroup.dateEventGroups).toHaveLength(1)
      })

      it('assigns the event date to the date event group', () => {
        const {dateEventGroups} = auditTrail.userEventGroups['1101']
        expect(dateEventGroups[0].startDate).toEqual(new Date('2018-09-01T12:00:00Z'))
      })
    })

    describe('when all events occurred on the same date', () => {
      beforeEach(() => {
        auditEvents = [
          buildUnknownEvent('4903', '2018-09-01T14:00:00Z'),
          buildUnknownEvent('4901', '2018-09-01T12:00:00Z'),
          buildUnknownEvent('4902', '2018-09-01T13:00:00Z')
        ]
        users = [firstUser, secondUser]

        auditTrail = buildAuditTrail({auditEvents, users})
      })

      it('includes one group of events', () => {
        const {dateEventGroups} = auditTrail.userEventGroups['1101']
        expect(dateEventGroups).toHaveLength(1)
      })

      it('includes all events in the same group', () => {
        const {dateEventGroups} = auditTrail.userEventGroups['1101']
        expect(dateEventGroups[0].auditEvents).toHaveLength(3)
      })

      it('orders events within the date event group by ascending date', () => {
        const {dateEventGroups} = auditTrail.userEventGroups['1101']
        const eventIds = getDateGroupEventIds(dateEventGroups[0])
        expect(eventIds).toEqual(['4901', '4902', '4903'])
      })
    })

    describe('when events occurred on different dates', () => {
      beforeEach(() => {
        auditEvents = [
          buildUnknownEvent('4904', '2018-09-02T13:00:00Z'),
          buildUnknownEvent('4901', '2018-09-01T12:00:00Z'),
          buildUnknownEvent('4903', '2018-09-02T12:00:00Z'),
          buildUnknownEvent('4902', '2018-09-01T13:00:00Z')
        ]
        users = [firstUser, secondUser]
      })

      function getDateEventGroups() {
        auditTrail = buildAuditTrail({auditEvents, users})
        return auditTrail.userEventGroups['1101'].dateEventGroups
      }

      it('includes a date event group for each distinct date', () => {
        expect(getDateEventGroups()).toHaveLength(2)
      })

      it('orders date event groups by ascending date', () => {
        const startDates = getDateEventGroups().map(dateEventGroup => dateEventGroup.startDate)
        expect(startDates).toEqual([
          new Date('2018-09-01T12:00:00Z'),
          new Date('2018-09-02T12:00:00Z')
        ])
      })

      it('separates events which occurred on different dates into different groups', () => {
        const eventIds = getDateEventGroups().map(dateEventGroup =>
          getDateGroupEventIds(dateEventGroup).sort()
        )
        expect(eventIds).toEqual([['4901', '4902'], ['4903', '4904']])
      })

      it('orders events within date event groups by ascending date', () => {
        const eventIds = getDateEventGroups().map(dateEventGroup =>
          getDateGroupEventIds(dateEventGroup)
        )
        expect(eventIds).toEqual([['4901', '4902'], ['4903', '4904']])
      })

      it('partitions event groups at midnight in the timezone of the current user', () => {
        auditEvents = [
          buildUnknownEvent('4904', '2018-09-03T03:59:59Z'),
          buildUnknownEvent('4901', '2018-09-01T04:00:00Z'),
          buildUnknownEvent('4903', '2018-09-02T04:00:00Z'),
          buildUnknownEvent('4902', '2018-09-02T03:59:59Z')
        ]
        const eventIds = getDateEventGroups().map(dateEventGroup =>
          getDateGroupEventIds(dateEventGroup)
        )
        expect(eventIds).toEqual([['4901', '4902'], ['4903', '4904']])
      })
    })
  })

  describe('event splitting', () => {
    describe('"assignment_created" event', () => {
      it('includes the "assignment_created" event', () => {
        buildCreateEvent({})
        expect(filterAuditEvents('assignment_created')).toHaveLength(1)
      })

      it('is positioned before derived events', () => {
        buildCreateEvent({})
        const [firstAuditEventDatum] = getAuditEvents()
        expect(firstAuditEventDatum.auditEvent.eventType).toEqual('assignment_created')
      })
    })

    /* Event Splitting: Anonymous Grading */

    describe('when anonymous grading is initially enabled', () => {
      beforeEach(() => {
        buildCreateEvent({anonymous_grading: true})
      })

      it('sets .anonymousGradingWasUsed to true', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.anonymousGradingWasUsed).toBe(true)
      })

      it('includes the "assignment_created" event', () => {
        expect(filterAuditEvents('assignment_created')).toHaveLength(1)
      })

      describe('"student_anonymity_updated" event', () => {
        it('is added using the assignment creation date', () => {
          const auditEventData = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {anonymous_grading: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({anonymous_grading: true})
        })

        it('derives a unique id from the "assignment_created" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4901.student_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })
    })

    describe('when anonymous grading is initially disabled and subsequently enabled', () => {
      beforeEach(() => {
        buildCreateEvent({anonymous_grading: false})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {anonymous_grading: [false, true]})
      })

      it('sets .anonymousGradingWasUsed to true', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.anonymousGradingWasUsed).toBe(true)
      })

      describe('initial "student_anonymity_updated" event', () => {
        it('is added using the assignment creation date', () => {
          const auditEventData = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {anonymous_grading: false}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({anonymous_grading: false})
        })

        it('derives a unique id from the "assignment_created" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4901.student_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('subsequent "student_anonymity_updated" event', () => {
        it('is added using the assignment update date', () => {
          const auditEventData = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {anonymous_grading: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({anonymous_grading: true})
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4902.student_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      it('does not create an additional "student_anonymity_updated" event when unchanged', () => {
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {anonymous_grading: [true, true]})
        const auditEventData = filterAuditEvents(
          'student_anonymity_updated',
          '2018-09-03T12:00:00Z'
        )
        expect(auditEventData).toHaveLength(0)
      })
    })

    describe('when anonymous grading is initially enabled and subsequently disabled', () => {
      beforeEach(() => {
        buildCreateEvent({anonymous_grading: true})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {anonymous_grading: [true, false]})
      })

      describe('subsequent "student_anonymity_updated" event', () => {
        it('is added using the assignment update date', () => {
          const auditEventData = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {anonymous_grading: false}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({anonymous_grading: false})
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4902.student_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'student_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })
    })

    describe('when anonymous grading is never enabled', () => {
      beforeEach(() => {
        buildCreateEvent({points_possible: 10})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {points_possible: [10, 15]})
      })

      it('includes the "assignment_created" event', () => {
        expect(filterAuditEvents('assignment_created')).toHaveLength(1)
      })

      it('does not add a "student_anonymity_updated" event', () => {
        const auditEventData = filterAuditEvents('student_anonymity_updated')
        expect(auditEventData).toHaveLength(0)
      })

      it('sets .anonymousGradingWasUsed to false', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.anonymousGradingWasUsed).toBe(false)
      })
    })

    /* Event Splitting: Moderated Grading */

    describe('when moderated grading is initially enabled', () => {
      it('sets .moderatedGradingWasUsed to true', () => {
        buildCreateEvent({moderated_grading: true})
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.moderatedGradingWasUsed).toBe(true)
      })

      describe('"grader_to_grader_anonymity_updated" event', () => {
        it('is added using the assignment creation date', () => {
          buildCreateEvent({moderated_grading: true, graders_anonymous_to_graders: true})
          const auditEventData = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {graders_anonymous_to_graders: false} when graders are not anonymous to each other', () => {
          buildCreateEvent({moderated_grading: true, graders_anonymous_to_graders: false})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({graders_anonymous_to_graders: false})
        })

        it('sets the payload to {graders_anonymous_to_graders: true} when graders are anonymous to each other', () => {
          buildCreateEvent({moderated_grading: true, graders_anonymous_to_graders: true})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({graders_anonymous_to_graders: true})
        })

        it('derives a unique id from the "assignment_created" event', () => {
          buildCreateEvent({moderated_grading: true})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4901.grader_to_grader_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('"grader_to_final_grader_anonymity_updated" event', () => {
        it('is added using the assignment creation date', () => {
          buildCreateEvent({moderated_grading: true, grader_names_visible_to_final_grader: true})
          const auditEventData = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {grader_names_visible_to_final_grader: false} when graders are not anonymous to the final grader', () => {
          buildCreateEvent({moderated_grading: true, grader_names_visible_to_final_grader: false})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_names_visible_to_final_grader: false
          })
        })

        it('sets the payload to {grader_names_visible_to_final_grader: false} when graders are anonymous to the final grader', () => {
          buildCreateEvent({moderated_grading: true, grader_names_visible_to_final_grader: false})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_names_visible_to_final_grader: false
          })
        })

        it('derives a unique id from the "assignment_created" event', () => {
          buildCreateEvent({moderated_grading: true})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual(
            '4901.grader_to_final_grader_anonymity_updated'
          )
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('"grader_to_grader_comment_visibility_updated" event', () => {
        it('is added using the assignment creation date', () => {
          buildCreateEvent({moderated_grading: true, grader_comments_visible_to_graders: true})
          const auditEventData = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {grader_comments_visible_to_graders: false} when graders are not anonymous to the final grader', () => {
          buildCreateEvent({moderated_grading: true, grader_comments_visible_to_graders: false})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_comments_visible_to_graders: false
          })
        })

        it('sets the payload to {grader_comments_visible_to_graders: false} when graders are anonymous to the final grader', () => {
          buildCreateEvent({moderated_grading: true, grader_comments_visible_to_graders: false})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_comments_visible_to_graders: false
          })
        })

        it('derives a unique id from the "assignment_created" event', () => {
          buildCreateEvent({moderated_grading: true})
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual(
            '4901.grader_to_grader_comment_visibility_updated'
          )
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('"grader_count_updated" event', () => {
        it('is added using the assignment creation date', () => {
          buildCreateEvent({moderated_grading: true})
          const auditEventData = filterAuditEvents('grader_count_updated', '2018-09-01T12:00:00Z')
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload with the initial grader count', () => {
          buildCreateEvent({moderated_grading: true, grader_count: 2})
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({grader_count: 2})
        })

        it('derives a unique id from the "assignment_created" event', () => {
          buildCreateEvent({moderated_grading: true})
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4901.grader_count_updated')
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })
    })

    describe('when moderated grading is initially disabled and subsequently enabled', () => {
      beforeEach(() => {
        buildCreateEvent({moderated_grading: false})
      })

      function enabledModeratedGradingWith(payload) {
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {
          moderated_grading: [false, true],
          ...payload
        })
      }

      it('sets .moderatedGradingWasUsed to true', () => {
        enabledModeratedGradingWith({})
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.moderatedGradingWasUsed).toBe(true)
      })

      describe('initial "grader_to_grader_anonymity_updated" event', () => {
        beforeEach(() => {
          enabledModeratedGradingWith({})
        })

        it('is added using the assignment creation date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {graders_anonymous_to_graders: false}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({graders_anonymous_to_graders: false})
        })

        it('derives a unique id from the "assignment_created" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4901.grader_to_grader_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('subsequent "grader_to_grader_anonymity_updated" event', () => {
        beforeEach(() => {
          enabledModeratedGradingWith({graders_anonymous_to_graders: [false, true]})
        })

        it('is added using the assignment updated date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {graders_anonymous_to_graders: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({graders_anonymous_to_graders: true})
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4902.grader_to_grader_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      describe('initial "grader_to_final_grader_anonymity_updated" event', () => {
        beforeEach(() => {
          enabledModeratedGradingWith({})
        })

        it('is added using the assignment creation date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {grader_names_visible_to_final_grader: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_names_visible_to_final_grader: true
          })
        })

        it('derives a unique id from the "assignment_created" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual(
            '4901.grader_to_final_grader_anonymity_updated'
          )
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('subsequent "grader_to_final_grader_anonymity_updated" event', () => {
        beforeEach(() => {
          enabledModeratedGradingWith({grader_names_visible_to_final_grader: [false, true]})
        })

        it('is added using the assignment updated date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {grader_names_visible_to_final_grader: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_names_visible_to_final_grader: true
          })
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual(
            '4902.grader_to_final_grader_anonymity_updated'
          )
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      describe('initial "grader_to_grader_comment_visibility_updated" event', () => {
        beforeEach(() => {
          enabledModeratedGradingWith({})
        })

        it('is added using the assignment creation date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {grader_comments_visible_to_graders: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_comments_visible_to_graders: true
          })
        })

        it('derives a unique id from the "assignment_created" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual(
            '4901.grader_to_grader_comment_visibility_updated'
          )
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('subsequent "grader_to_grader_comment_visibility_updated" event', () => {
        beforeEach(() => {
          enabledModeratedGradingWith({grader_comments_visible_to_graders: [false, true]})
        })

        it('is added using the assignment updated date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {grader_comments_visible_to_graders: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_comments_visible_to_graders: true
          })
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual(
            '4902.grader_to_grader_comment_visibility_updated'
          )
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      it('does not add an initial "grader_count_updated" event', () => {
        // When moderated grading is not applied at assignment creation, grader
        // count will not be relevant and will not be included in the audit
        // trail until moderated grading is later enabled.
        enabledModeratedGradingWith({grader_count: [0, 2]})
        const auditEventData = filterAuditEvents('grader_count_updated', '2018-09-01T12:00:00Z')
        expect(auditEventData).toHaveLength(0)
      })

      describe('subsequent "grader_count_updated" event', () => {
        beforeEach(() => {
          enabledModeratedGradingWith({grader_count: [0, 2]})
        })

        it('is added using the assignment updated date', () => {
          const auditEventData = filterAuditEvents('grader_count_updated', '2018-09-02T12:00:00Z')
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload with the updated grader count', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({grader_count: 2})
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4902.grader_count_updated')
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      it('does not create an additional "grader_to_grader_anonymity_updated" event when unchanged', () => {
        enabledModeratedGradingWith({graders_anonymous_to_graders: [false, false]})
        const auditEventData = filterAuditEvents(
          'grader_to_grader_anonymity_updated',
          '2018-09-02T12:00:00Z'
        )
        expect(auditEventData).toHaveLength(0)
      })

      it('does not create an additional "grader_to_final_grader_anonymity_updated" event when unchanged', () => {
        enabledModeratedGradingWith({grader_names_visible_to_final_grader: [false, false]})
        const auditEventData = filterAuditEvents(
          'grader_to_final_grader_anonymity_updated',
          '2018-09-02T12:00:00Z'
        )
        expect(auditEventData).toHaveLength(0)
      })

      it('does not create an additional "grader_to_grader_comment_visibility_updated" event when unchanged', () => {
        enabledModeratedGradingWith({grader_comments_visible_to_graders: [false, false]})
        const auditEventData = filterAuditEvents(
          'grader_to_grader_comment_visibility_updated',
          '2018-09-02T12:00:00Z'
        )
        expect(auditEventData).toHaveLength(0)
      })

      it('does not create an additional "grader_count_updated" event when unchanged', () => {
        enabledModeratedGradingWith({grader_count: [0, 2]})
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {grader_count: [2, 2]})
        const auditEventData = filterAuditEvents('grader_count_updated', '2018-09-03T12:00:00Z')
        expect(auditEventData).toHaveLength(0)
      })
    })

    describe('when moderated grading is initially enabled and subsequently disabled', () => {
      beforeEach(() => {
        buildCreateEvent({moderated_grading: true})
      })

      function disabledModeratedGradingWith(payload) {
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {
          moderated_grading: [true, false],
          ...payload
        })
      }

      describe('subsequent "grader_to_grader_anonymity_updated" event', () => {
        beforeEach(() => {
          disabledModeratedGradingWith({graders_anonymous_to_graders: [true, false]})
        })

        it('is added using the assignment update date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {graders_anonymous_to_graders: false}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({graders_anonymous_to_graders: false})
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual('4902.grader_to_grader_anonymity_updated')
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      describe('subsequent "grader_to_final_grader_anonymity_updated" event', () => {
        beforeEach(() => {
          disabledModeratedGradingWith({grader_names_visible_to_final_grader: [false, true]})
        })

        it('is added using the assignment update date', () => {
          const auditEventData = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {grader_names_visible_to_final_grader: true}', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.payload).toEqual({
            grader_names_visible_to_final_grader: true
          })
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.auditEvent.id).toEqual(
            '4902.grader_to_final_grader_anonymity_updated'
          )
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      it('does not add an initial "grader_count_updated" event', () => {
        // When moderated grading is not applied at assignment creation, grader
        // count will not be relevant and will not be included in the audit
        // trail until moderated grading is later enabled.
        disabledModeratedGradingWith({grader_count: [2, 0]})
        const auditEventData = filterAuditEvents('grader_count_updated', '2018-09-02T12:00:00Z')
        expect(auditEventData).toHaveLength(0)
      })
    })

    describe('when moderated grading is never enabled', () => {
      beforeEach(() => {
        buildCreateEvent({points_possible: 10})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {points_possible: [10, 15]})
      })

      it('includes the "assignment_created" event', () => {
        expect(filterAuditEvents('assignment_created')).toHaveLength(1)
      })

      it('sets .moderatedGradingWasUsed to false', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.moderatedGradingWasUsed).toBe(false)
      })

      it('does not add a "grader_to_grader_anonymity_updated" event', () => {
        const auditEventData = filterAuditEvents('grader_to_grader_anonymity_updated')
        expect(auditEventData).toHaveLength(0)
      })

      it('does not add a "grader_to_final_grader_anonymity_updated" event', () => {
        const auditEventData = filterAuditEvents('grader_to_final_grader_anonymity_updated')
        expect(auditEventData).toHaveLength(0)
      })

      it('does not add a "grader_to_grader_comment_visibility_updated" event', () => {
        const auditEventData = filterAuditEvents('grader_to_grader_comment_visibility_updated')
        expect(auditEventData).toHaveLength(0)
      })

      it('does not add a "grader_count_updated" event', () => {
        const auditEventData = filterAuditEvents('grader_count_updated')
        expect(auditEventData).toHaveLength(0)
      })
    })

    /* Event Splitting: Muting */

    describe('when the assignment is initially unmuted and subsequently muted', () => {
      beforeEach(() => {
        buildCreateEvent({muted: false})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {muted: [false, true]})
      })

      it('sets .mutingWasUsed to true', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.mutingWasUsed).toBe(true)
      })

      describe('"assignment_unmuted" event', () => {
        it('is added using the assignment creation date', () => {
          const auditEventData = filterAuditEvents('assignment_unmuted', '2018-09-01T12:00:00Z')
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {muted: false}', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-01T12:00:00Z')
          expect(auditEventDatum.auditEvent.payload).toEqual({muted: false})
        })

        it('derives a unique id from the "assignment_created" event', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-01T12:00:00Z')
          expect(auditEventDatum.auditEvent.id).toEqual('4901.assignment_unmuted')
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-01T12:00:00Z')
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('"assignment_muted" event', () => {
        it('is added using the assignment updated date', () => {
          const auditEventData = filterAuditEvents('assignment_muted', '2018-09-02T12:00:00Z')
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {muted: true}', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-02T12:00:00Z')
          expect(auditEventDatum.auditEvent.payload).toEqual({muted: true})
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-02T12:00:00Z')
          expect(auditEventDatum.auditEvent.id).toEqual('4902.assignment_muted')
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-02T12:00:00Z')
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })

      it('does not create an additional "assignment_muted" event when unchanged', () => {
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {muted: [true, true]})
        const auditEventData = filterAuditEvents('assignment_muted', '2018-09-03T12:00:00Z')
        expect(auditEventData).toHaveLength(0)
      })

      it('does not create an additional "assignment_unmuted" event when unchanged', () => {
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {muted: [true, false]})
        buildUpdateEvent('4904', '2018-09-04T12:00:00Z', {muted: [false, false]})
        const auditEventData = filterAuditEvents('assignment_unmuted', '2018-09-04T12:00:00Z')
        expect(auditEventData).toHaveLength(0)
      })
    })

    describe('when the assignment is initially muted and subsequently unmuted', () => {
      beforeEach(() => {
        buildCreateEvent({muted: true})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {muted: [true, false]})
      })

      it('sets .mutingWasUsed to true', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.mutingWasUsed).toBe(true)
      })

      describe('"assignment_muted" event', () => {
        it('is added using the assignment creation date', () => {
          const auditEventData = filterAuditEvents('assignment_muted', '2018-09-01T12:00:00Z')
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {muted: true}', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-01T12:00:00Z')
          expect(auditEventDatum.auditEvent.payload).toEqual({muted: true})
        })

        it('derives a unique id from the "assignment_created" event', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-01T12:00:00Z')
          expect(auditEventDatum.auditEvent.id).toEqual('4901.assignment_muted')
        })

        it('copies the remaining attributes from the "assignment_created" audit event', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-01T12:00:00Z')
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(createEventDatum.auditEvent[key])
          })
        })
      })

      describe('"assignment_unmuted" event', () => {
        it('is added using the assignment updated date', () => {
          const auditEventData = filterAuditEvents('assignment_unmuted', '2018-09-02T12:00:00Z')
          expect(auditEventData).toHaveLength(1)
        })

        it('sets the payload to {muted: false}', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-02T12:00:00Z')
          expect(auditEventDatum.auditEvent.payload).toEqual({muted: false})
        })

        it('derives a unique id from the "assignment_updated" event', () => {
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-02T12:00:00Z')
          expect(auditEventDatum.auditEvent.id).toEqual('4902.assignment_unmuted')
        })

        it('copies the remaining attributes from the "assignment_updated" audit event', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-02T12:00:00Z')
          ;['assignmentId', 'createdAt', 'submissionId', 'userId'].forEach(key => {
            expect(auditEventDatum.auditEvent[key]).toEqual(updateEventDatum.auditEvent[key])
          })
        })
      })
    })

    describe('when the assignment is never muted', () => {
      beforeEach(() => {
        buildCreateEvent({points_possible: 10})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {points_possible: [10, 15]})
      })

      it('includes the "assignment_created" event', () => {
        expect(filterAuditEvents('assignment_created')).toHaveLength(1)
      })

      it('sets .mutingWasUsed to false', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.mutingWasUsed).toBe(false)
      })

      it('does not add an "assignment_muted" event', () => {
        const auditEventData = filterAuditEvents('assignment_muted')
        expect(auditEventData).toHaveLength(0)
      })

      it('does not add an "assignment_unmuted" event', () => {
        const auditEventData = filterAuditEvents('assignment_muted')
        expect(auditEventData).toHaveLength(0)
      })
    })
  })
})
