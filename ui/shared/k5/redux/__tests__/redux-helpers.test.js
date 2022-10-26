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

import {mapStateToProps} from '../redux-helpers'

jest.mock('moment-timezone', () => ({
  tz: jest.fn(() => ({
    format: () => '2021-02-06',
  })),
}))

const state = weekOverrides => ({
  opportunities: {
    items: [
      {
        id: '14',
        course_id: 'science',
        planner_override: {
          dismissed: false,
        },
      },
      {
        id: '22',
        course_id: 'math',
      },
      {
        id: '37',
        course_id: 'science',
        planner_override: {
          dismissed: true,
        },
      },
    ],
  },
  timeZone: 'America/Denver',
  weeklyDashboard: {
    weeks: {
      '2021-01-31T00:00:00-00:00': weekOverrides || [
        [
          '2021-02-06',
          [
            {
              type: 'Assignment',
              course_id: 'science',
              status: {submitted: true},
            },
            {
              type: 'Discussion',
              course_id: 'science',
              status: {submitted: false},
            },
            {
              type: 'Assignment',
              course_id: 'math',
              status: {submitted: false},
            },
            {
              type: 'Assignment',
              course_id: 'science',
              status: {submitted: false},
            },
          ],
        ],
      ],
    },
  },
})

describe('K-5 Dashboard redux-helpers', () => {
  describe('mapStateToProps', () => {
    describe('assignmentsDueToday', () => {
      it('returns empty objects when no days are present', () => {
        expect(mapStateToProps(state([])).assignmentsDueToday).toEqual({})
      })

      it('returns an empty object when days are malformed or missing', () => {
        expect(mapStateToProps(state([])).assignmentsDueToday).toEqual({})
        expect(mapStateToProps(state([[]])).assignmentsDueToday).toEqual({})
        expect(mapStateToProps(state([['2021-02-06']])).assignmentsDueToday).toEqual({})
        expect(mapStateToProps(state([['2021-02-06', null]])).assignmentsDueToday).toEqual({})
        expect(mapStateToProps(state([['2021-02-06', []]])).assignmentsDueToday).toEqual({})
        expect(
          mapStateToProps(state([['2021-02-06', [{foo: 'bar'}], [{foo: 'baz'}]]]))
            .assignmentsDueToday
        ).toEqual({})
      })

      it('groups the number of assignment items by course_id', () => {
        const {assignmentsDueToday} = mapStateToProps(state())
        expect(Object.keys(assignmentsDueToday).length).toBe(2)
        expect(assignmentsDueToday.science).toBe(2)
        expect(assignmentsDueToday.math).toBe(1)
      })

      it('filters out assignments in submitted status', () => {
        const {assignmentsDueToday, assignmentsCompletedForToday} = mapStateToProps(state())
        expect(Object.keys(assignmentsDueToday).length).toBe(2)
        expect(assignmentsDueToday.science).toBe(2)
        expect(assignmentsCompletedForToday.science).toBe(1)
      })
    })

    describe('assignmentsMissing', () => {
      it('groups the number of missing assignments by course_id', () => {
        const {assignmentsMissing} = mapStateToProps(state())
        expect(Object.keys(assignmentsMissing).length).toBe(2)
        expect(assignmentsMissing.science).toBe(1)
        expect(assignmentsMissing.math).toBe(1)
      })

      it('filters out assignments that have been dismissed already', () => {
        const {assignmentsMissing} = mapStateToProps(state())
        expect(Object.keys(assignmentsMissing).length).toBe(2)
        expect(assignmentsMissing.science).toBe(1)
      })
    })
  })
})
