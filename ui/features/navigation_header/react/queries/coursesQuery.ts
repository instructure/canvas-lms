/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import doFetchApi from '@canvas/do-fetch-api-effect'

import type {QueryFunctionContext} from '@tanstack/react-query'
import type {Course} from '../../../../api.d'

export function getFirstPageUrl() {
  const defaultFirstPageUrl =
    '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname'

  const isObserver = window.ENV.current_user_roles?.includes('observer')

  // if user is an observer, only retrieve the courses for the observee
  if (isObserver) {
    const observedUserId = savedObservedId(ENV.current_user_id)
    if (observedUserId) {
      return `${defaultFirstPageUrl}&observed_user_id=${observedUserId}`
    }
  }
  return defaultFirstPageUrl
}

export const hideHomeroomCourseIfK5Student = (course: Pick<Course, 'homeroom_course'>): boolean => {
  const isK5Student =
    window.ENV.K5_USER &&
    window.ENV.current_user_roles?.every(role => role === 'student' || role === 'user')
  return !isK5Student || !course.homeroom_course
}

export default async function coursesQuery({signal}: QueryFunctionContext): Promise<Course[]> {
  const data: Array<Course> = []
  const fetchOpts = {signal}
  let path = getFirstPageUrl()

  while (path) {
    // eslint-disable-next-line no-await-in-loop
    const {json, link} = await doFetchApi<Course[]>({path, fetchOpts})
    if (json) data.push(...json)
    path = link?.next?.url || null
  }
  return data
}
