/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'
import fakeENV from '@canvas/test-utils/fakeENV'
import Assignment from '../Assignment'

describe('Assignment', () => {
  describe('#peerReviews', () => {
    it('returns the peer_reviews on the record if no args passed', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('peer_reviews', false)
      expect(assignment.peerReviews()).toBe(false)
    })

    it("sets the record's peer_reviews if args passed", () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('peer_reviews', false)
      assignment.peerReviews(true)
      expect(assignment.peerReviews()).toBe(true)
    })
  })

  describe('#automaticPeerReviews', () => {
    it('returns the automatic_peer_reviews on the model if no args passed', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('automatic_peer_reviews', false)
      expect(assignment.automaticPeerReviews()).toBe(false)
    })

    it('sets the automatic_peer_reviews on the record if args passed', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('automatic_peer_reviews', false)
      assignment.automaticPeerReviews(true)
      expect(assignment.automaticPeerReviews()).toBe(true)
    })
  })

  describe('#notifyOfUpdate', () => {
    it("returns record's notifyOfUpdate if no args passed", () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('notify_of_update', false)
      expect(assignment.notifyOfUpdate()).toBe(false)
    })

    it("sets record's notifyOfUpdate if args passed", () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.notifyOfUpdate(false)
      expect(assignment.notifyOfUpdate()).toBe(false)
    })
  })

  describe('#multipleDueDates', () => {
    it('checks for multiple due dates from assignment overrides', () => {
      const assignment = new Assignment({
        all_dates: [{title: 'Winter'}, {title: 'Summer'}],
      })
      expect(assignment.multipleDueDates()).toBe(true)
    })

    it('checks for no multiple due dates from assignment overrides', () => {
      const assignment = new Assignment({all_dates: []})
      expect(assignment.multipleDueDates()).toBe(false)
    })
  })

  describe('#allDates', () => {
    it('gets the due dates from the assignment overrides', () => {
      const dueAt = new Date('2013-08-20T11:13:00')
      const dates = [
        new DateGroup({
          due_at: dueAt,
          title: 'Everyone',
        }),
      ]
      const assignment = new Assignment({all_dates: dates})
      const allDates = assignment.allDates()
      const first = allDates[0]
      expect(String(first.dueAt)).toBe(String(dueAt))
      expect(first.dueFor).toBe('Everyone')
    })

    it('gets empty due dates when there are no dates', () => {
      const assignment = new Assignment()
      expect(assignment.allDates()).toEqual([])
    })
  })

  describe('#inGradingPeriod', () => {
    let gradingPeriod
    let dateInPeriod
    let dateOutsidePeriod

    beforeEach(() => {
      gradingPeriod = {
        id: '1',
        title: 'Fall',
        startDate: new Date('2013-07-01T11:13:00'),
        endDate: new Date('2013-10-01T11:13:00'),
        closeDate: new Date('2013-10-05T11:13:00'),
        isLast: true,
        isClosed: true,
      }
      dateInPeriod = new Date('2013-08-20T11:13:00')
      dateOutsidePeriod = new Date('2013-01-20T11:13:00')
    })

    it('returns true if the assignment has a due_at in the given period', () => {
      const assignment = new Assignment()
      assignment.set('due_at', dateInPeriod)
      expect(assignment.inGradingPeriod(gradingPeriod)).toBe(true)
    })

    it('returns false if the assignment has a due_at outside the given period', () => {
      const assignment = new Assignment()
      assignment.set('due_at', dateOutsidePeriod)
      expect(assignment.inGradingPeriod(gradingPeriod)).toBe(false)
    })

    it('returns true if the assignment has a date group in the given period', () => {
      const dates = [
        new DateGroup({
          due_at: dateInPeriod,
          title: 'Everyone',
        }),
      ]
      const assignment = new Assignment({all_dates: dates})
      expect(assignment.inGradingPeriod(gradingPeriod)).toBe(true)
    })

    it('returns false if the assignment does not have a date group in the given period', () => {
      const dates = [
        new DateGroup({
          due_at: dateOutsidePeriod,
          title: 'Everyone',
        }),
      ]
      const assignment = new Assignment({all_dates: dates})
      expect(assignment.inGradingPeriod(gradingPeriod)).toBe(false)
    })
  })

  describe('#singleSectionDueDate', () => {
    beforeEach(() => {
      fakeENV.setup()
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('gets the due date for section instead of null', () => {
      const dueAt = new Date('2013-11-27T11:01:00Z')
      const assignment = new Assignment({
        all_dates: [
          {
            due_at: null,
            title: 'Everyone',
          },
          {
            due_at: dueAt,
            title: 'Summer',
          },
        ],
      })
      jest.spyOn(assignment, 'multipleDueDates').mockReturnValue(false)
      expect(assignment.singleSectionDueDate()).toBe(dueAt.toISOString())
    })

    it('returns due_at when only one date/section are present', () => {
      const date = Date.now()
      const assignment = new Assignment({name: 'Taco party!'})
      assignment.set('due_at', date)
      expect(assignment.singleSectionDueDate()).toBe(assignment.dueAt())
      ENV.PERMISSIONS = {manage: false}
      expect(assignment.singleSectionDueDate()).toBe(assignment.dueAt())
      ENV.PERMISSIONS = {}
    })
  })

  describe('#omitFromFinalGrade', () => {
    it("gets the record's omit_from_final_grade boolean", () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('omit_from_final_grade', true)
      expect(assignment.omitFromFinalGrade()).toBe(true)
    })

    it("sets the record's omit_from_final_grade boolean if args passed", () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('omit_from_final_grade', false)
      assignment.omitFromFinalGrade(true)
      expect(assignment.omitFromFinalGrade()).toBe(true)
    })
  })
})
