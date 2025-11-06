/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import type {QueryFunctionContext} from '@tanstack/react-query'
import {Enrollment} from 'api'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {EnvCourseSettings} from '@canvas/global/env/EnvCourse'

declare const ENV: GlobalEnv & EnvCourseSettings

type FetchSectionsOptions = {
  exclude: string[]
  searchTerm?: string
  courseId: string
}

export type ResponseSection = {
  id: string
  name: string
  avatar_url: string
  user_count: number
}

export async function fetchSections({
  queryKey,
}: QueryFunctionContext<[string, FetchSectionsOptions]>): Promise<ResponseSection[]> {
  const [, {exclude, searchTerm, courseId}] = queryKey
  const {json} = await doFetchApi<{sections: ResponseSection[]}>({
    path: `/courses/${courseId}/sections/user_count`,
    params: {
      exclude,
      search: searchTerm,
    },
  })
  return json!.sections
}

export async function deleteExistingSectionEnrollments(enrollmentsForDeletion: string[]) {
  const promises = enrollmentsForDeletion.map(async id => {
    return await doFetchApi({
      method: 'DELETE',
      path: `${ENV.COURSE_ROOT_URL}/unenroll/${id}`,
    })
  })
  await Promise.all(promises)
}

export async function createSectionEnrollments(newSections: string[], enrollmentForm: FormData) {
  const promises = newSections.map(async sectionId => {
    const {json} = await doFetchApi<Enrollment>({
      method: 'POST',
      path: `/api/v1/sections/${sectionId}/enrollments`,
      body: enrollmentForm,
    })
    return {...json, can_be_removed: true}
  })
  return await Promise.all(promises)
}
