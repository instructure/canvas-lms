/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import moment from 'moment'
import withinMomentDates from '../momentDateHelper'

describe('Moment Date helpers ', () => {
  it('withinMomentDates correctly identifies date that is before as false', () => {
    const dueDate = moment("2015-11-1")
    const startDate = moment("2015-12-1")
    const endDate = moment("2015-12-14")
    const check = withinMomentDates(dueDate, startDate, endDate)
    expect(check).toBe(false)
  })

  it('withinMomentDates correctly identifies date that is on the start date as true', () => {
    const dueDate = moment("2015-12-1")
    const startDate = moment("2015-12-1")
    const endDate = moment("2015-12-14")
    const check = withinMomentDates(dueDate, startDate, endDate)
    expect(check).toBe(true)
  })

  it('withinMomentDates correctly identifies date that is within range as true', () => {
    const dueDate = moment("2015-12-12")
    const startDate = moment("2015-12-1")
    const endDate = moment("2015-12-14")
    const check = withinMomentDates(dueDate, startDate, endDate)
    expect(check).toBe(true)
  })

  it('withinMomentDates correctly identifies date that is on the end date as true', () => {
    const dueDate = moment("2015-12-14")
    const startDate = moment("2015-12-1")
    const endDate = moment("2015-12-14")
    const check = withinMomentDates(dueDate, startDate, endDate)
    expect(check).toBe(true)
  })

  it('withinMomentDates correctly identifies date that is after the end date as false', () => {
    const dueDate = moment("2016-12-14")
    const startDate = moment("2015-12-1")
    const endDate = moment("2015-12-14")
    const check = withinMomentDates(dueDate, startDate, endDate)
    expect(check).toBe(false)
  })
})
