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

import type {submitMigrationFormData} from '@canvas/content-migrations/react/CommonMigratorControls/types'

export type NextPageTerms = {
  page?: string
  per_page?: string
}

export type Term = Readonly<{
  name: string
  id: string
  startAt?: string
  endAt?: string
}>

export type CopyCourseFormSubmitData = Readonly<
  {
    courseName: string
    courseCode: string
    newCourseStartDate: Date | null
    newCourseEndDate: Date | null
    selectedTerm: Term | null
    restrictEnrollmentsToCourseDates: boolean
    courseTimeZone: string
  } & submitMigrationFormData
>

export const courseCopyRootKey = 'copy_course'
export const courseFetchKey = 'course'
export const enrollmentTermsFetchKey = 'enrollment_terms'
export const createCourseAndMigrationKey = 'create_course_and_migration'
