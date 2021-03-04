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

import {mapStateToProps} from 'jsx/dashboard/redux-helpers'

jest.mock('moment-timezone', () => ({
  tz: jest.fn(() => ({
    format: () => '2021-02-06'
  }))
}))

const timeZone = 'America/Denver'

describe('K-5 Dashboard redux-helpers', () => {
  describe('mapStateToProps', () => {
    describe('assignmentsDueToday', () => {
      it('returns an empty object when no days are present', () => {
        expect(mapStateToProps({days: [], timeZone}).assignmentsDueToday).toEqual({})
      })

      it('returns an empty object when days are malformed or missing', () => {
        expect(mapStateToProps({days: [], timeZone}).assignmentsDueToday).toEqual({})
        expect(mapStateToProps({days: [[]], timeZone}).assignmentsDueToday).toEqual({})
        expect(mapStateToProps({days: [['2021-02-06']], timeZone}).assignmentsDueToday).toEqual({})
        expect(
          mapStateToProps({days: [['2021-02-06', null]], timeZone}).assignmentsDueToday
        ).toEqual({})
        expect(mapStateToProps({days: [['2021-02-06', []]], timeZone}).assignmentsDueToday).toEqual(
          {}
        )
        expect(
          mapStateToProps({days: [['2021-02-06', [{foo: 'bar'}], [{foo: 'baz'}]]], timeZone})
            .assignmentsDueToday
        ).toEqual({})
      })

      it('groups the number of assignment items by course_id', () => {
        const assignments = [
          {
            type: 'Assignment',
            course_id: 'science',
            status: {submitted: false}
          },
          {
            type: 'Discussion',
            course_id: 'science',
            status: {submitted: false}
          },
          {
            type: 'Assignment',
            course_id: 'math',
            status: {submitted: false}
          },
          {
            type: 'Assignment',
            course_id: 'science',
            status: {submitted: false}
          }
        ]
        const {assignmentsDueToday} = mapStateToProps({
          days: [['2021-02-06', assignments]],
          timeZone
        })
        expect(Object.keys(assignmentsDueToday).length).toBe(2)
        expect(assignmentsDueToday.science).toBe(2)
        expect(assignmentsDueToday.math).toBe(1)
      })

      it('filters out assignments in submitted status', () => {
        const assignments = [
          {
            type: 'Assignment',
            course_id: 'science',
            status: {submitted: false}
          },
          {
            type: 'Discussion',
            course_id: 'science',
            status: {submitted: false}
          },
          {
            type: 'Assignment',
            course_id: 'science',
            status: {submitted: true}
          }
        ]
        const {assignmentsDueToday} = mapStateToProps({
          days: [['2021-02-06', assignments]],
          timeZone
        })
        expect(Object.keys(assignmentsDueToday).length).toBe(1)
        expect(assignmentsDueToday.science).toBe(1)
      })
    })
  })
})
