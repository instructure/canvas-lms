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

import {z} from 'zod'
import {ZNextPageInfo} from '../PaginatedResult'
import {executeQuery} from '@canvas/graphql'
import {GET_ENROLLMENTS_QUERY} from './getEnrollmentsQuery'

const ZEnrollmentState = z.enum([
  'active',
  'completed',
  'creation_pending',
  'deleted',
  'inactive',
  'invited',
  'rejected',
])

const ZEnrollmentType = z.enum([
  'StudentEnrollment',
  'TeacherEnrollment',
  'TaEnrollment',
  'ObserverEnrollment',
  'DesignerEnrollment',
  'StudentViewEnrollment',
])

const ZEnrollmentGrades = z
  .object({
    htmlUrl: z.string().nullable(),
    currentGrade: z.string().nullable(),
    currentScore: z.number().nullable(),
    finalGrade: z.string().nullable(),
    finalScore: z.number().nullable(),
    unpostedCurrentGrade: z.string().nullable(),
    unpostedCurrentScore: z.number().nullable(),
    unpostedFinalGrade: z.string().nullable(),
    unpostedFinalScore: z.number().nullable(),
  })
  .strict()

const ZEnrollment = z
  .object({
    _id: z.string(),
    associatedUser: z.object({_id: z.string()}).strict().nullable(),
    course: z.object({_id: z.string()}).strict().nullable(),
    createdAt: z.string().nullable(),
    endAt: z.string().nullable(),
    startAt: z.string().nullable(),
    updatedAt: z.string().nullable(),
    lastActivityAt: z.string().nullable(),
    limitPrivilegesToCourseSection: z.boolean().nullable(),
    courseSectionId: z.string().nullable(),
    htmlUrl: z.string().nullable(),
    role: z
      .object({
        _id: z.string().nullable(),
        name: z.string().nullable(),
      })
      .strict()
      .nullable(),
    sisSectionId: z.string().nullable(),
    state: ZEnrollmentState,
    enrollmentState: ZEnrollmentState,
    type: ZEnrollmentType,
    userId: z.string().nullable(),
    grades: ZEnrollmentGrades,
  })
  .strict()
export type Enrollment = z.infer<typeof ZEnrollment>

const ZGetEnrollmentsResult = z
  .object({
    course: z.object({
      enrollmentsConnection: z.object({
        pageInfo: ZNextPageInfo,
        nodes: z.array(ZEnrollment),
      }),
    }),
  })
  .strict()

export type GetEnrollmentsResult = z.infer<typeof ZGetEnrollmentsResult>

export type GetEnrollmentsParams = {
  courseId: string
  userIds?: string[]
  after?: string
}
export const getEnrollments = async ({after, courseId, userIds}: GetEnrollmentsParams) => {
  const data = await executeQuery<GetEnrollmentsResult>(GET_ENROLLMENTS_QUERY, {
    courseId,
    userIds,
    after,
  })

  const validation = ZGetEnrollmentsResult.safeParse(data)
  if (!validation.success) {
    console.error('Validation failed:', validation.error.format())
  }
  return data
}
