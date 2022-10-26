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
import {createNewCourse, getAccountsFromEnrollments} from '../utils'

const NEW_COURSE_URL =
  '/api/v1/accounts/15/courses?course[name]=Science&course[sync_enrollments_from_homeroom]=true&course[homeroom_course_id]=14&enroll_me=true'

afterEach(() => {
  fetchMock.restore()
})

describe('createNewCourse', () => {
  it('posts to the new course endpoint and returns the new id', async () => {
    fetchMock.post(encodeURI(NEW_COURSE_URL), {id: '56'})
    const result = await createNewCourse(15, 'Science', true, 14)
    expect(result.id).toBe('56')
  })
})

describe('getAccountsFromEnrollments', () => {
  it('returns array of objects containing id and name', () => {
    const enrollments = [
      {
        name: 'Algebra',
        account: {
          id: 6,
          name: 'Elementary',
          workflow_state: 'active',
        },
      },
    ]
    const accounts = getAccountsFromEnrollments(enrollments)
    expect(accounts.length).toBe(1)
    expect(accounts[0].id).toBe(6)
    expect(accounts[0].name).toBe('Elementary')
    expect(accounts[0].workflow_state).toBeUndefined()
  })

  it('removes duplicate accounts from list', () => {
    const enrollments = [
      {
        account: {
          id: 12,
          name: 'FFES',
        },
      },
      {
        account: {
          id: 12,
          name: 'FFES',
        },
      },
    ]
    const accounts = getAccountsFromEnrollments(enrollments)
    expect(accounts.length).toBe(1)
  })

  it('ignores enrollments without an account property', () => {
    const enrollments = [
      {
        id: 10,
        account: {
          id: 1,
          name: 'School',
        },
      },
      {
        id: 11,
        access_restricted_by_date: true,
      },
    ]
    const accounts = getAccountsFromEnrollments(enrollments)
    expect(accounts.length).toBe(1)
    expect(accounts[0].id).toBe(1)
  })
})
