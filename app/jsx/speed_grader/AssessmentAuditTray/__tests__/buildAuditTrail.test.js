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
import {buildEvent} from './AuditTrailSpecHelpers'

describe('AssessmentAuditTray buildAuditTrail()', () => {
  let auditTrail
  let timezoneSnapshot

  function buildUnknownEvent(id, createdAt, data = {}) {
    return buildEvent({id, createdAt, ...data})
  }

  function getDateGroupEventIds(dateEventGroup) {
    return dateEventGroup.auditEvents.map(({auditEvent}) => auditEvent.id)
  }

  beforeEach(() => {
    timezoneSnapshot = timezone.snapshot()
    timezone.changeZone(newYork, 'America/New_York')
  })

  afterEach(() => {
    timezone.restore(timezoneSnapshot)
  })

  describe('events by user id', () => {
    it('is undefined when the user has no events', () => {
      auditTrail = buildAuditTrail([buildUnknownEvent('4901', '2018-09-01T12:00:00Z')])
      expect(auditTrail.userEventGroups['1109']).toBeUndefined()
    })

    describe('when the user has only one event', () => {
      beforeEach(() => {
        auditTrail = buildAuditTrail([buildUnknownEvent('4901', '2018-09-01T12:00:00Z')])
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
        auditTrail = buildAuditTrail([
          buildUnknownEvent('4903', '2018-09-01T14:00:00Z'),
          buildUnknownEvent('4901', '2018-09-01T12:00:00Z'),
          buildUnknownEvent('4902', '2018-09-01T13:00:00Z')
        ])
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
      let auditEvents

      beforeEach(() => {
        auditEvents = [
          buildUnknownEvent('4904', '2018-09-02T13:00:00Z'),
          buildUnknownEvent('4901', '2018-09-01T12:00:00Z'),
          buildUnknownEvent('4903', '2018-09-02T12:00:00Z'),
          buildUnknownEvent('4902', '2018-09-01T13:00:00Z')
        ]
      })

      function getDateEventGroups() {
        auditTrail = buildAuditTrail(auditEvents)
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
})
