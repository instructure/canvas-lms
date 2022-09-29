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

import getConferenceType from '../getConferenceType'

describe('getConferenceType', () => {
  const conferenceTypes = [
    {id: 1, type: 'foo'},
    {id: 2, type: 'bar'},
    {id: 3, type: 'LtiConference', lti_settings: {tool_id: '1'}},
    {id: 4, type: 'LtiConference', lti_settings: {tool_id: '2'}},
  ]

  it('returns the conference type from a list that matches the given conference', () => {
    const conference = {conference_type: 'bar'}
    expect(getConferenceType(conferenceTypes, conference).id).toEqual(2)
  })

  it('returns undefined if none found', () => {
    const conference = {conference_type: 'baz'}
    expect(getConferenceType(conferenceTypes, conference)).toBeUndefined()
  })

  it('returns an LtiConferenceType if it matches tool ids', () => {
    const conference = {conference_type: 'LtiConference', lti_settings: {tool_id: '2'}}
    expect(getConferenceType(conferenceTypes, conference).id).toEqual(4)
  })

  it('returns undefined if no tool ids match', () => {
    const conference = {conference_type: 'LtiConference', lti_settings: {tool_id: '3'}}
    expect(getConferenceType(conferenceTypes, conference)).toBeUndefined()
  })
})
