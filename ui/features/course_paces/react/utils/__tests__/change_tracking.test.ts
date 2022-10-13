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

import {summarizeItemChanges, summarizeSettingChanges} from '../change_tracking'
import {PACE_ITEM_1, PACE_ITEM_2} from '../../__tests__/fixtures'

const EXCLUDE_WEEKENDS = {id: 'exclude_weekends', oldValue: false, newValue: true}
const END_DATE = {id: 'end_date', oldValue: '2021-09-01', newValue: '2021-11-01'}
const REQUIRE_COMPLETION = {id: 'require_completion', oldValue: false, newValue: true}
const BLACKOUT_DATES = [
  {
    id: 'blackout_date',
    oldValue: {id: '1', event_title: 'one'},
    newValue: null,
  },
  {
    id: 'blackout_date',
    oldValue: null,
    newValue: {temp_id: '_foo', event_title: 'new one'},
  },
]

describe('summarizeSettingChanges', () => {
  it('formats known setting changes correctly', () => {
    expect(
      summarizeSettingChanges([EXCLUDE_WEEKENDS, END_DATE, REQUIRE_COMPLETION]).map(c => c.summary)
    ).toEqual([
      'Skip Weekends was turned on.',
      'Require Completion by End Date was turned on and set to November 1, 2021.',
    ])
  })

  it('includes end_date if require_completion was unchanged', () => {
    expect(summarizeSettingChanges([END_DATE]).map(c => c.summary)).toEqual([
      'End Date was changed from September 1, 2021 to November 1, 2021.',
    ])
  })

  it('includes unknown settings (and formats them as strings)', () => {
    expect(
      summarizeSettingChanges([{id: 'unknown_setting', oldValue: 50, newValue: 500}]).map(
        c => c.summary
      )
    ).toEqual(['unknown_setting was changed from 50 to 500.'])
  })

  it('includes blackout date changes', () => {
    const changes = summarizeSettingChanges(BLACKOUT_DATES)
    expect(changes[0]).toMatchObject({
      id: 'blackout_date',
      summary: 'Blackout date one was deleted.',
    })
    expect(changes[1]).toMatchObject({
      id: 'blackout_date',
      summary: 'Blackout date new one was added.',
    })
  })
})

describe('summarizeItemChanges', () => {
  it('formats changes correctly', () => {
    expect(
      summarizeItemChanges([
        {
          id: PACE_ITEM_1.id,
          oldValue: PACE_ITEM_1,
          newValue: {...PACE_ITEM_1, duration: 1},
        },
        {id: PACE_ITEM_2.id, oldValue: PACE_ITEM_2, newValue: {...PACE_ITEM_2, duration: 2000}},
      ]).map(c => c.summary)
    ).toEqual([
      `${PACE_ITEM_1.assignment_title} was changed from 2 days to 1 day.`,
      `${PACE_ITEM_2.assignment_title} was changed from 5 days to 2,000 days.`,
    ])
  })
})
