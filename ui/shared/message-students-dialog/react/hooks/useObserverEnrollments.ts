/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useMemo} from 'react'
import {useAllPages} from '@canvas/query'
import {Student} from '../MessageStudentsWhoDialog'
import {executeQuery} from '@canvas/graphql'
import {
  OBSERVER_ENROLLMENTS_QUERY,
  ObserverEnrollmentQueryResult,
} from '@canvas/message-students-dialog/graphql/Queries'
import type {InfiniteData} from '@tanstack/react-query'

const getNextPageParam = (lastPage: ObserverEnrollmentQueryResult) => {
  const {hasNextPage, endCursor} = lastPage.course.enrollmentsConnection.pageInfo

  if (hasNextPage && endCursor) {
    return endCursor
  }

  return null
}

export const useObserverEnrollments = (courseId: string | undefined, students: Student[]) => {
  const studentIds = students.map(student => student.id)
  const keyStudentIds = studentIds.sort().join(',')
  const {data, isLoading, isFetchingNextPage} = useAllPages<
    ObserverEnrollmentQueryResult,
    unknown,
    InfiniteData<ObserverEnrollmentQueryResult>
  >({
    enabled: courseId !== undefined,
    queryKey: ['ObserversForStudents', courseId, keyStudentIds],
    queryFn: async ({pageParam}) => {
      return executeQuery<ObserverEnrollmentQueryResult>(OBSERVER_ENROLLMENTS_QUERY, {
        courseId,
        cursor: pageParam,
        studentIds,
      })
    },
    initialPageParam: null,
    getNextPageParam,
  })

  const loading = isLoading || isFetchingNextPage
  const observerEnrollments = useMemo(
    () => data?.pages.flatMap(page => page?.course?.enrollmentsConnection?.nodes) ?? [],
    [data],
  )

  return {loading, observerEnrollments}
}
