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
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'

import type {QueryFunctionContext} from '@tanstack/react-query'
import type {Course} from '../../../../api.d'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const window: Window & {ENV: GlobalEnv}
declare const ENV: GlobalEnv

export function getFirstPageUrl() {
  const defaultFirstPageUrl =
    '/api/v1/users/self/favorites/courses?include[]=term&include[]=sections&sort=nickname'

  const isObserver = window.ENV.current_user_roles?.includes('observer')

  // if user is an observer, only retrieve the courses for the observee
  if (isObserver) {
    const observedUserId = savedObservedId(ENV.current_user_id)
    if (observedUserId) {
      return `${defaultFirstPageUrl}&observed_user_id=${observedUserId}`
    }

    // If no cookie is set yet, default to the first observee in the list.
    // If the observer is first in the list (has their own enrollments),
    // don't filter by observee - return the default URL.
    const observedUsersList = window.ENV.OBSERVED_USERS_LIST
    if (observedUsersList && observedUsersList.length > 0) {
      const firstObservee =
        observedUsersList[0].id === ENV.current_user_id ? null : observedUsersList[0]
      if (firstObservee) {
        return `${defaultFirstPageUrl}&observed_user_id=${firstObservee.id}`
      }
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
  let path: string | null = getFirstPageUrl()

  while (path) {
    const result: DoFetchApiResults<Course[]> = await doFetchApi<Course[]>({path, fetchOpts})
    if (result.json) data.push(...result.json)
    path = result.link?.next?.url ?? null
  }
  return data
}
