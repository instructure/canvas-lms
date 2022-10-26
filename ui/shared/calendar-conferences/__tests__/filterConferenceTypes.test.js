/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import filterConferenceTypes from '../filterConferenceTypes'

describe('filterConferenceTypes', () => {
  const contextTypes = [
    {id: 1, contexts: ['course_1', 'group_2', 'acccount_3', 'course_4', 'group_5']},
    {id: 2, contexts: ['group_2', 'acccount_3', 'course_4']},
    {id: 3, contexts: ['course_1', 'group_5']},
  ]

  it('returns for course contexts', () => {
    expect(filterConferenceTypes(contextTypes, 'course_4').map(t => t.id)).toEqual([1, 2])
  })
  it('returns for group contexts', () => {
    expect(filterConferenceTypes(contextTypes, 'group_5').map(t => t.id)).toEqual([1, 3])
  })
  it('returns [] if no match', () => {
    expect(filterConferenceTypes(contextTypes, 'cousrse_6').map(t => t.id)).toEqual([])
  })
  it('returns [] for other contexts', () => {
    expect(filterConferenceTypes(contextTypes, 'account_3').map(t => t.id)).toEqual([])
  })
})
