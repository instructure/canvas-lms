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

import type {CopyCourseFormSubmitData} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {ContentMigration, Course} from '../../../../api'
import {convertFormDataToMigrationCreateRequest} from '@canvas/content-migrations/react/CommonMigratorControls/converter/form_data_converter'

const convertToCourseCreationParams = (formData: CopyCourseFormSubmitData) => {
  const course = {
    name: formData.courseName,
    course_code: formData.courseCode,
    start_at: formData.newCourseStartDate?.toISOString(),
    end_at: formData.newCourseEndDate?.toISOString(),
    term_id: formData.selectedTerm?.id || null,
    restrict_enrollments_to_course_dates: formData.restrictEnrollmentsToCourseDates,
    time_zone: formData.courseTimeZone,
  }

  if (!formData.restrictEnrollmentsToCourseDates) {
    delete course.start_at
    delete course.end_at
  }

  return {course, enroll_me: true}
}

export const createCourseCopyMutation = async ({
  accountId,
  courseId,
  formData,
}: {
  accountId: string
  courseId: string
  formData: CopyCourseFormSubmitData
}): Promise<string> => {
  const createCourseParams = convertToCourseCreationParams(formData)

  const {json: courseCreationResult} = await doFetchApi<Course>({
    path: `/api/v1/accounts/${accountId}/courses`,
    method: 'POST',
    body: createCourseParams,
  })

  if (!courseCreationResult) {
    throw new Error('Failed to create course')
  }

  const copyMigrationParams = convertFormDataToMigrationCreateRequest(
    {
      adjust_dates: formData.adjust_dates,
      date_shift_options: formData.date_shift_options,
      selective_import: formData.selective_import,
      settings: formData.settings,
    },
    courseId,
    'course_copy_importer',
  )

  copyMigrationParams.settings.source_course_id = courseId

  const {response} = await doFetchApi<ContentMigration>({
    path: `/api/v1/courses/${courseCreationResult.id}/content_migrations`,
    method: 'POST',
    body: copyMigrationParams,
  })

  if (!response.ok) {
    throw new Error('Failed to create course')
  }

  return courseCreationResult.id
}
