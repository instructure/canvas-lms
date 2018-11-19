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

import {auditEventStudentAnonymityStates, overallAnonymityStates} from '../AuditTrailHelpers'

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

  function getUserEventGroup(userId) {
    auditTrail = auditTrail || buildAuditTrail({auditEvents, users})
    return auditTrail.userEventGroups.find(group => group.user.id === userId)
  }

  function getAuditEvents() {
    const {dateEventGroups} = getUserEventGroup('1101')
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

  function getAuditEvent(eventId) {
    return getAuditEvents().find(({auditEvent}) => auditEvent.id === eventId)
  }

  describe('.finalGradeDate', () => {
    describe('when the assignment is moderated', () => {
      beforeEach(() => {
        auditEvents = [
          buildAssignmentCreatedEvent(
            {id: '4901', createdAt: '2018-09-01T12:00:00Z'},
            {moderated_grading: true}
          ),
          buildEvent({
            createdAt: '2018-09-17T12:00:00Z',
            eventType: 'provisional_grade_selected',
            id: '4911',
            userId: '1101'
          })
        ]
      })

      it('is the date of the "provisional_grade_selected" event', () => {
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.finalGradeDate).toEqual(new Date('2018-09-17T12:00:00Z'))
      })

      it('is the latest selection date when the selected grade changed', () => {
        auditEvents.push(
          buildEvent({
            createdAt: '2018-09-17T12:01:00Z',
            eventType: 'provisional_grade_selected',
            id: '4912'
          }),
          buildEvent({
            createdAt: '2018-09-17T12:08:00Z',
            eventType: 'provisional_grade_selected',
            id: '4913'
          })
        )
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.finalGradeDate).toEqual(new Date('2018-09-17T12:08:00Z'))
      })
    })

    describe('when the assignment is not moderated', () => {
      beforeEach(() => {
        auditEvents = [
          buildAssignmentCreatedEvent(
            {id: '4901', createdAt: '2018-09-01T12:00:00Z'},
            {moderated_grading: false}
          )
        ]
      })

      function gradeStudent(id, createdAt, gradeBefore, gradeAfter) {
        auditEvents.push(
          buildEvent(
            {createdAt, eventType: 'submission_updated', id},
            {grade: [gradeBefore, gradeAfter]}
          )
        )
      }

      it('is the date of the "submission_updated" event where the grade was changed', () => {
        gradeStudent('4912', '2018-09-17T12:00:00Z')
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.finalGradeDate).toEqual(new Date('2018-09-17T12:00:00Z'))
      })

      it('is the latest grade change date when the grade changed multiple times', () => {
        gradeStudent('4912', '2018-09-17T12:00:00Z')
        gradeStudent('4913', '2018-09-17T12:01:00Z')
        gradeStudent('4914', '2018-09-18T13:04:00Z')
        auditTrail = buildAuditTrail({auditEvents, users})
        expect(auditTrail.finalGradeDate).toEqual(new Date('2018-09-18T13:04:00Z'))
      })
    })
  })

  describe('user event groups', () => {
    let availableUsers

    beforeEach(() => {
      availableUsers = {
        1101: {id: '1101', name: 'Adam Jones'},
        1102: {id: '1102', name: 'Betty Ford'},
        1103: {id: '1103', name: 'Charlie Xi'},
        1104: {id: '1104', name: 'Dana Young'},
        1105: {id: '1105', name: 'Ed Valiant'},
        1106: {id: '1106', name: 'Fay Aldrin'},
        1107: {id: '1107'}
      }

      users = []
    })

    function addEventWithUser(userId, day, role) {
      const event = buildEvent({
        createdAt: `2018-09-0${day}T12:00:00Z`,
        id: `490${auditEvents.length + 1}`,
        userId
      })
      users.push({...availableUsers[userId], role})
      auditEvents.push(event)
    }

    function getUserIds() {
      return buildAuditTrail({auditEvents, users}).userEventGroups.map(group => group.user.id)
    }

    describe('students', () => {
      beforeEach(() => {
        addEventWithUser('1101', 1, 'grader')
        addEventWithUser('1102', 6, 'student')
        addEventWithUser('1103', 4, 'unknown')
        addEventWithUser('1104', 3, 'student')
        addEventWithUser('1105', 2, 'admin')
        addEventWithUser('1106', 5, 'student')
        addEventWithUser('1107', 7, 'final_grader')
      })

      it('are positioned before all other users', () => {
        const userIds = getUserIds().slice(0, 3)
        expect(userIds.sort()).toEqual(['1102', '1104', '1106'])
      })

      it('are ordered by date of their first event', () => {
        expect(getUserIds().slice(0, 3)).toEqual(['1104', '1106', '1102'])
      })
    })

    describe('graders', () => {
      beforeEach(() => {
        addEventWithUser('1101', 1, 'admin')
        addEventWithUser('1102', 6, 'grader')
        addEventWithUser('1103', 4, 'unknown')
        addEventWithUser('1104', 3, 'grader')
        addEventWithUser('1105', 2, 'student')
        addEventWithUser('1106', 5, 'grader')
        addEventWithUser('1107', 7, 'final_grader')
      })

      it('are positioned after students', () => {
        const userIds = getUserIds().slice(1, 4)
        expect(userIds.sort()).toEqual(['1102', '1104', '1106'])
      })

      it('are ordered by date of their first event', () => {
        expect(getUserIds().slice(1, 4)).toEqual(['1104', '1106', '1102'])
      })
    })

    it('positions final grader after graders', () => {
      addEventWithUser('1101', 2, 'unknown')
      addEventWithUser('1102', 3, 'admin')
      addEventWithUser('1104', 4, 'student')
      addEventWithUser('1105', 1, 'final_grader')
      addEventWithUser('1103', 5, 'grader')
      expect(getUserIds()[2]).toEqual('1105')
    })

    describe('admins', () => {
      beforeEach(() => {
        addEventWithUser('1101', 1, 'grader')
        addEventWithUser('1102', 6, 'admin')
        addEventWithUser('1103', 4, 'unknown')
        addEventWithUser('1104', 3, 'admin')
        addEventWithUser('1105', 2, 'student')
        addEventWithUser('1106', 5, 'admin')
        addEventWithUser('1107', 7, 'final_grader')
      })

      it('are positioned after final grader', () => {
        const userIds = getUserIds().slice(3, 6)
        expect(userIds.sort()).toEqual(['1102', '1104', '1106'])
      })

      it('orders admins by date of their first event', () => {
        expect(getUserIds().slice(3, 6)).toEqual(['1104', '1106', '1102'])
      })
    })

    describe('unknown users', () => {
      beforeEach(() => {
        addEventWithUser('1101', 1, 'grader')
        addEventWithUser('1102', 6, null)
        addEventWithUser('1103', 4, 'admin')
        addEventWithUser('1104', 3, null)
        addEventWithUser('1105', 2, 'student')
        addEventWithUser('1106', 5, 'unknown')
        addEventWithUser('1107', 7, 'final_grader')
      })

      it('are positioned after all other users', () => {
        const userIds = getUserIds().slice(4)
        expect(userIds.sort()).toEqual(['1102', '1104', '1106'])
      })

      it('orders unknown users by date of their first event', () => {
        expect(getUserIds().slice(4)).toEqual(['1104', '1106', '1102'])
      })
    })
  })

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
      expect(getUserEventGroup('1109')).toBeUndefined()
    })

    it('sets .user with the related user data when the specified user is known', () => {
      auditTrail = buildAuditTrail({
        auditEvents: [buildEvent()],
        users: [secondUser]
      })
      expect(getUserEventGroup('1101').user).toEqual(secondUser)
    })

    it('sets .user with "unknown user" data when the specified user is not known', () => {
      auditTrail = buildAuditTrail({
        auditEvents: [buildEvent()],
        users: []
      })
      expect(getUserEventGroup('1101').user).toEqual({
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
        const userEventGroup = getUserEventGroup('1101')
        expect(userEventGroup.dateEventGroups).toHaveLength(1)
      })

      it('assigns the event date to the date event group', () => {
        const {dateEventGroups} = getUserEventGroup('1101')
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
        const {dateEventGroups} = getUserEventGroup('1101')
        expect(dateEventGroups).toHaveLength(1)
      })

      it('includes all events in the same group', () => {
        const {dateEventGroups} = getUserEventGroup('1101')
        expect(dateEventGroups[0].auditEvents).toHaveLength(3)
      })

      it('orders events within the date event group by ascending date', () => {
        const {dateEventGroups} = getUserEventGroup('1101')
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
        return getUserEventGroup('1101').dateEventGroups
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          buildCreateEvent({moderated_grading: true})
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-01T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_comment_visibility_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_count_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents(
            'grader_to_final_grader_anonymity_updated',
            '2018-09-02T12:00:00Z'
          )
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-01T12:00:00Z')
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-02T12:00:00Z')
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_created" audit event datum', () => {
          const [createEventDatum] = filterAuditEvents('assignment_created')
          const [auditEventDatum] = filterAuditEvents('assignment_muted', '2018-09-01T12:00:00Z')
          expect(auditEventDatum.studentAnonymity).toEqual(createEventDatum.studentAnonymity)
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

        it('copies .studentAnonymity from the "assignment_updated" audit event datum', () => {
          const [updateEventDatum] = filterAuditEvents('assignment_updated')
          const [auditEventDatum] = filterAuditEvents('assignment_unmuted', '2018-09-02T12:00:00Z')
          expect(auditEventDatum.studentAnonymity).toEqual(updateEventDatum.studentAnonymity)
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

  describe('per-event anonymity tracking', () => {
    const {NA, OFF, ON, TURNED_OFF, TURNED_ON} = auditEventStudentAnonymityStates

    describe('when student anonymity is initially disabled and subsequently enabled', () => {
      beforeEach(() => {
        buildCreateEvent({anonymous_grading: false})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {points_possible: [10, 15]})
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {anonymous_grading: [false, true]})
        buildUpdateEvent('4904', '2018-09-04T12:00:00Z', {points_possible: [15, 10]})
      })

      it('sets .studentAnonymity to OFF on the initial event', () => {
        expect(getAuditEvent('4901').studentAnonymity).toBe(OFF)
      })

      it('sets .studentAnonymity to OFF on subsequent events which have not enabled student anonymity', () => {
        expect(getAuditEvent('4902').studentAnonymity).toBe(OFF)
      })

      it('sets .studentAnonymity to ON on the subsequent update which enables student anonymity', () => {
        expect(getAuditEvent('4903').studentAnonymity).toBe(ON)
      })

      it('sets .studentAnonymity to TURNED_ON on the extracted event which enables student anonymity', () => {
        expect(getAuditEvent('4903.student_anonymity_updated').studentAnonymity).toBe(TURNED_ON)
      })

      it('sets .studentAnonymity to ON on subsequent events which have not re-disabled student anonymity', () => {
        expect(getAuditEvent('4904').studentAnonymity).toBe(ON)
      })
    })

    describe('when student anonymity is initially enabled and subsequently disabled', () => {
      beforeEach(() => {
        buildCreateEvent({anonymous_grading: true})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {points_possible: [10, 15]})
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {anonymous_grading: [true, false]})
        buildUpdateEvent('4904', '2018-09-04T12:00:00Z', {points_possible: [15, 10]})
      })

      it('sets .studentAnonymity to ON on the initial event', () => {
        expect(getAuditEvent('4901').studentAnonymity).toBe(ON)
      })

      it('sets .studentAnonymity to ON on subsequent events which have not disabled student anonymity', () => {
        expect(getAuditEvent('4902').studentAnonymity).toBe(ON)
      })

      it('sets .studentAnonymity to OFF on the subsequent event which disables student anonymity', () => {
        expect(getAuditEvent('4903').studentAnonymity).toBe(OFF)
      })

      it('sets .studentAnonymity to TURNED_OFF on the extracted event which enables student anonymity', () => {
        expect(getAuditEvent('4903.student_anonymity_updated').studentAnonymity).toBe(TURNED_OFF)
      })

      it('sets .studentAnonymity to OFF on subsequent events which have not re-enabled student anonymity', () => {
        expect(getAuditEvent('4904').studentAnonymity).toBe(OFF)
      })
    })

    describe('when student anonymity is never enabled', () => {
      beforeEach(() => {
        buildCreateEvent({})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {points_possible: [10, 15]})
      })

      it('sets .studentAnonymity to N/A on the initial event', () => {
        expect(getAuditEvent('4901').studentAnonymity).toBe(NA)
      })

      it('sets .studentAnonymity to N/A on subsequent events', () => {
        expect(getAuditEvent('4902').studentAnonymity).toBe(NA)
      })
    })
  })

  describe('per-user anonymity tracking', () => {
    beforeEach(() => {
      buildCreateEvent({anonymous_grading: true})
      buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {points_possible: [10, 15]})
    })

    function gradeStudent(id, createdAt, userId, payload) {
      auditEvents.push(
        buildEvent({createdAt, eventType: 'provisional_grade_created', id, userId}, payload)
      )
    }

    it('sets .anonymousOnly to true when student anonymity was never disabled', () => {
      expect(getUserEventGroup('1101').anonymousOnly).toBe(true)
    })

    it('sets .anonymousOnly to false when the given user disabled student anonymity', () => {
      buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {anonymous_grading: [true, false]})
      buildUpdateEvent('4904', '2018-09-04T12:00:00Z', {anonymous_grading: [false, true]})
      expect(getUserEventGroup('1101').anonymousOnly).toBe(false)
    })

    it('sets .anonymousOnly to false when the given user acted while student anonymity was disabled', () => {
      buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {anonymous_grading: [true, false]})
      gradeStudent('4904', '2018-09-03T12:01:00Z', '1103', {grade: 'F', score: 0})
      buildUpdateEvent('4905', '2018-09-04T12:00:00Z', {anonymous_grading: [false, true]})
      expect(getUserEventGroup('1103').anonymousOnly).toBe(false)
    })

    it('sets .anonymousOnly to true when the given user acted only before student anonymity was disabled', () => {
      gradeStudent('4903', '2018-09-03T11:59:00Z', '1103', {grade: 'F', score: 0})
      buildUpdateEvent('4904', '2018-09-03T12:00:00Z', {anonymous_grading: [true, false]})
      buildUpdateEvent('4905', '2018-09-04T12:00:00Z', {anonymous_grading: [false, true]})
      expect(getUserEventGroup('1103').anonymousOnly).toBe(true)
    })

    it('sets .anonymousOnly to true when the given user acted only after student anonymity was re-enabled', () => {
      buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {anonymous_grading: [true, false]})
      buildUpdateEvent('4904', '2018-09-04T12:00:00Z', {anonymous_grading: [false, true]})
      gradeStudent('4905', '2018-09-04T12:01:00Z', '1103', {grade: 'F', score: 0})
      expect(getUserEventGroup('1103').anonymousOnly).toBe(true)
    })
  })

  describe('overall anonymity tracking', () => {
    const {FULL, NA, PARTIAL} = overallAnonymityStates

    function gradeStudent(id, createdAt, userId, payload) {
      auditEvents.push(
        buildEvent({createdAt, eventType: 'provisional_grade_created', id, userId}, payload)
      )
    }

    function getOverallAnonymity() {
      return buildAuditTrail({auditEvents, users}).overallAnonymity
    }

    function getAnonymityDate() {
      return buildAuditTrail({auditEvents, users}).anonymityDate
    }

    describe('when only student anonymity was enabled', () => {
      beforeEach(() => {
        buildCreateEvent({muted: true})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {anonymous_grading: [false, true]})
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {points_possible: [10, 15]})
        gradeStudent('4910', '2018-09-10T11:59:00Z', '1103', {grade: 'F', score: 0})
        buildUpdateEvent('4951', '2018-09-30T12:10:00Z', {muted: [true, false]})
      })

      describe('when anonymity was not interrupted', () => {
        it('is fully anonymous', () => {
          expect(getOverallAnonymity()).toEqual(FULL)
        })

        it('uses the last "anonymity enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-02T12:00:00Z'))
        })
      })

      describe('when anonymity was temporarily disabled', () => {
        beforeEach(() => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {anonymous_grading: [true, false]})
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {anonymous_grading: [false, true]})
        })

        it('is partially anonymous', () => {
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })

        it('uses the later "anonymity re-enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-17T12:01:00Z'))
        })
      })

      describe('when anonymity was disabled at the end of the audit trail', () => {
        it('is fully anonymous when anonymity was not interrupted', () => {
          buildUpdateEvent('4930', '2018-09-30T12:00:00Z', {anonymous_grading: [true, false]})
          expect(getOverallAnonymity()).toEqual(FULL)
        })

        it('is partially anonymous when anonymity was temporarily disabled', () => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {anonymous_grading: [true, false]})
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {anonymous_grading: [false, true]})
          buildUpdateEvent('4930', '2018-09-30T12:00:00Z', {anonymous_grading: [true, false]})
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })
      })
    })

    describe('when only grader-to-grader anonymity was enabled', () => {
      beforeEach(() => {
        buildCreateEvent({muted: true})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {
          graders_anonymous_to_graders: [false, true]
        })
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {points_possible: [10, 15]})
        gradeStudent('4910', '2018-09-10T11:59:00Z', '1103', {grade: 'F', score: 0})
        buildUpdateEvent('4951', '2018-09-30T12:10:00Z', {muted: [true, false]})
      })

      describe('when anonymity was not interrupted', () => {
        it('is fully anonymous', () => {
          expect(getOverallAnonymity()).toEqual(FULL)
        })

        it('uses the last "anonymity enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-02T12:00:00Z'))
        })
      })

      describe('when anonymity was temporarily disabled', () => {
        beforeEach(() => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {
            graders_anonymous_to_graders: [true, false]
          })
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {
            graders_anonymous_to_graders: [false, true]
          })
        })

        it('is partially anonymous', () => {
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })

        it('uses the later "anonymity re-enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-17T12:01:00Z'))
        })
      })

      describe('when anonymity was disabled at the end of the audit trail', () => {
        it('is fully anonymous when anonymity was not interrupted', () => {
          buildUpdateEvent('4930', '2018-09-30T12:00:00Z', {
            graders_anonymous_to_graders: [true, false]
          })
          expect(getOverallAnonymity()).toEqual(FULL)
        })

        it('is partially anonymous when anonymity was temporarily disabled', () => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {
            graders_anonymous_to_graders: [true, false]
          })
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {
            graders_anonymous_to_graders: [false, true]
          })
          buildUpdateEvent('4930', '2018-09-30T12:00:00Z', {
            graders_anonymous_to_graders: [true, false]
          })
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })
      })
    })

    describe('when only grader-to-final-grader anonymity was enabled', () => {
      beforeEach(() => {
        buildCreateEvent({muted: true})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {
          grader_names_visible_to_final_grader: [true, false]
        })
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {points_possible: [10, 15]})
        gradeStudent('4910', '2018-09-10T11:59:00Z', '1103', {grade: 'F', score: 0})
        buildUpdateEvent('4951', '2018-09-30T12:10:00Z', {muted: [true, false]})
      })

      describe('when anonymity was not interrupted', () => {
        it('is fully anonymous', () => {
          expect(getOverallAnonymity()).toEqual(FULL)
        })

        it('uses the last "anonymity enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-02T12:00:00Z'))
        })
      })

      describe('when anonymity was temporarily disabled', () => {
        beforeEach(() => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {
            grader_names_visible_to_final_grader: [false, true]
          })
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {
            grader_names_visible_to_final_grader: [true, false]
          })
        })

        it('is partially anonymous', () => {
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })

        it('uses the later "anonymity re-enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-17T12:01:00Z'))
        })
      })

      describe('when anonymity was disabled at the end of the audit trail', () => {
        it('is fully anonymous when anonymity was not interrupted', () => {
          buildUpdateEvent('4930', '2018-09-30T12:00:00Z', {
            grader_names_visible_to_final_grader: [false, true]
          })
          expect(getOverallAnonymity()).toEqual(FULL)
        })

        it('is partially anonymous when anonymity was temporarily disabled', () => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {
            grader_names_visible_to_final_grader: [false, true]
          })
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {
            grader_names_visible_to_final_grader: [true, false]
          })
          buildUpdateEvent('4930', '2018-09-30T12:00:00Z', {
            grader_names_visible_to_final_grader: [false, true]
          })
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })
      })
    })

    describe('when all forms of anonymity are enabled', () => {
      beforeEach(() => {
        buildCreateEvent({muted: true})
        buildUpdateEvent('4902', '2018-09-02T12:00:00Z', {
          anonymous_grading: [false, true],
          graders_anonymous_to_graders: [false, true]
        })
        buildUpdateEvent('4903', '2018-09-02T12:10:00Z', {
          grader_names_visible_to_final_grader: [true, false]
        })
        buildUpdateEvent('4905', '2018-09-03T12:00:00Z', {points_possible: [10, 15]})
        gradeStudent('4910', '2018-09-10T11:59:00Z', '1103', {grade: 'F', score: 0})
        buildUpdateEvent('4930', '2018-09-30T12:00:00Z', {
          anonymous_grading: [true, false],
          grader_names_visible_to_final_grader: [false, true],
          graders_anonymous_to_graders: [true, false]
        })
        buildUpdateEvent('4951', '2018-09-30T12:10:00Z', {muted: [true, false]})
      })

      describe('when anonymity was not interrupted', () => {
        it('is fully anonymous', () => {
          expect(getOverallAnonymity()).toEqual(FULL)
        })

        it('uses the last "anonymity enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-02T12:10:00Z'))
        })
      })

      describe('when student anonymity was temporarily disabled', () => {
        beforeEach(() => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {anonymous_grading: [true, false]})
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {anonymous_grading: [false, true]})
        })

        it('is partially anonymous', () => {
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })

        it('uses the later "anonymity re-enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-17T12:01:00Z'))
        })
      })

      describe('when grader-to-grader anonymity was temporarily disabled', () => {
        beforeEach(() => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {
            graders_anonymous_to_graders: [true, false]
          })
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {
            graders_anonymous_to_graders: [false, true]
          })
        })

        it('is partially anonymous', () => {
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })

        it('uses the later "anonymity re-enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-17T12:01:00Z'))
        })
      })

      describe('when grader-to-final-grader anonymity was temporarily disabled', () => {
        beforeEach(() => {
          buildUpdateEvent('4917', '2018-09-17T12:00:00Z', {
            grader_names_visible_to_final_grader: [false, true]
          })
          buildUpdateEvent('4918', '2018-09-17T12:01:00Z', {
            grader_names_visible_to_final_grader: [true, false]
          })
        })

        it('is partially anonymous', () => {
          expect(getOverallAnonymity()).toEqual(PARTIAL)
        })

        it('uses the later "anonymity re-enabled" date for the anonymity date', () => {
          expect(getAnonymityDate()).toEqual(new Date('2018-09-17T12:01:00Z'))
        })
      })
    })

    describe('when anonymity was never applied', () => {
      beforeEach(() => {
        buildCreateEvent({muted: true})
        buildUpdateEvent('4903', '2018-09-03T12:00:00Z', {points_possible: [10, 15]})
        gradeStudent('4910', '2018-09-10T11:59:00Z', '1103', {grade: 'F', score: 0})
        buildUpdateEvent('4951', '2018-09-30T12:10:00Z', {muted: [true, false]})
      })

      it('is N/A', () => {
        expect(getOverallAnonymity()).toEqual(NA)
      })

      it('has no anonymity date', () => {
        expect(getAnonymityDate()).toBeNull()
      })
    })
  })
})
