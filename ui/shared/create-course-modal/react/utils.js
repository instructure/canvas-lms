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

import doFetchApi from '@canvas/do-fetch-api-effect'

/* Creates a new course with name in provided account, and enrolls the user as a teacher */
export const createNewCourse = (
  accountId,
  courseName,
  syncHomeroomEnrollments = null,
  homeroomCourseId = null
) =>
  doFetchApi({
    path: `/api/v1/accounts/${accountId}/courses`,
    method: 'POST',
    params: {
      'course[name]': courseName,
      'course[sync_enrollments_from_homeroom]': syncHomeroomEnrollments,
      'course[homeroom_course_id]': homeroomCourseId,
      enroll_me: true,
    },
  }).then(data => data.json)

/* Return array of objects containing id and name of accounts associated with each
   enrollment. */
export const getAccountsFromEnrollments = enrollments =>
  enrollments
    .filter(e => e.account)
    .reduce((acc, e) => {
      if (!acc.find(({id}) => id === e.account.id)) {
        acc.push({
          id: e.account.id,
          name: e.account.name,
        })
      }
      return acc
    }, [])
    .sort((a, b) => a.name.localeCompare(b.name, ENV.LOCALE, {sensitivity: 'base'}))
