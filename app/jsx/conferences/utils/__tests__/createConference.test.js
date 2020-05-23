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

import fetchMock from 'fetch-mock'
import createConference from '../createConference'

describe('createConference', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('posts to conferences endpoint', async () => {
    fetchMock.post('/api/v1/courses/112/conferences', 200)
    const context = 'course_112'
    const conferenceType = {type: 'foo', name: 'Foo'}
    await createConference(context, conferenceType)
    expect(fetchMock.calls().length).toEqual(1)
  })

  it('raises error on error', async () => {
    fetchMock.post('/api/v1/accounts/3/conferences', 500)
    const context = 'account_3'
    const conferenceType = {type: 'foo', name: 'Foo'}
    try {
      await createConference(context, conferenceType)
    } catch (error) {
      expect(error.message).toMatch('500')
    }
    expect(fetchMock.calls().length).toEqual(1)
    expect.assertions(2)
  })
})
