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

import fetchMock from 'fetch-mock'

import {fetchLatestAnnouncement} from 'jsx/dashboard/utils'

const ANNOUNCEMENT_URL =
  '/api/v1/announcements?context_codes=course_test&active_only=true&per_page=1'

afterEach(() => {
  fetchMock.restore()
})

describe('fetchLatestAnnouncement', () => {
  it('returns the first announcement if multiple are returned', async () => {
    fetchMock.get(
      ANNOUNCEMENT_URL,
      JSON.stringify([
        {
          title: 'I am first'
        },
        {
          title: 'I am not'
        }
      ])
    )
    const announcement = await fetchLatestAnnouncement('test')
    expect(announcement).toEqual({title: 'I am first'})
  })

  it('returns null if an empty array is returned', async () => {
    fetchMock.get(ANNOUNCEMENT_URL, '[]')
    const announcement = await fetchLatestAnnouncement('test')
    expect(announcement).toBeNull()
  })

  it('returns null if something falsy is returned', async () => {
    fetchMock.get(ANNOUNCEMENT_URL, 'null')
    const announcement = await fetchLatestAnnouncement('test')
    expect(announcement).toBeNull()
  })
})
