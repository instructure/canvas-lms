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

import {createCourseCopyMutation} from '../createCourseCopyMutation'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {convertFormDataToMigrationCreateRequest} from '@canvas/content-migrations/react/CommonMigratorControls/converter/form_data_converter'
import type {CopyCourseFormSubmitData} from '../../types'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/content-migrations/react/CommonMigratorControls/converter/form_data_converter')

describe('createCourseCopyMutation', () => {
  const accountId = '1'
  const courseId = '2'
  const formData: CopyCourseFormSubmitData = {
    courseName: 'New Course',
    courseCode: 'NC101',
    newCourseStartDate: new Date(),
    newCourseEndDate: new Date(),
    selectedTerm: {id: '3', name: 'Test Term'},
    adjust_dates: {enabled: false, operation: 'shift_dates'},
    date_shift_options: {
      old_start_date: '2024-01-01T00:00:00Z',
      new_start_date: '2024-01-01T00:00:00Z',
      old_end_date: '2024-01-01T00:00:00Z',
      new_end_date: '2024-01-01T00:00:00Z',
      day_substitutions: [],
    },
    selective_import: true,
    settings: {},
    restrictEnrollmentsToCourseDates: true,
    courseTimeZone: 'America/Detroit',
  }
  const mockReturnValue = {settings: {}}
  const courseCreationResult = {id: '4'}
  const contentMigrationResponseOk = {ok: true}
  const contentMigrationResponseFailed = {ok: false}

  beforeEach(() => {
    jest.clearAllMocks()
  })

  const mockDoFetchApi = doFetchApi as jest.Mock
  const mockConvertFormDataToMigrationCreateRequest =
    convertFormDataToMigrationCreateRequest as jest.Mock

  it('should throw an error if course creation fails', async () => {
    mockDoFetchApi.mockResolvedValueOnce({json: null})

    await expect(createCourseCopyMutation({accountId, courseId, formData})).rejects.toThrow(
      'Failed to create course',
    )
  })

  it('should throw an error if content migration fails', async () => {
    mockDoFetchApi.mockResolvedValueOnce({json: courseCreationResult})
    mockDoFetchApi.mockResolvedValueOnce({response: contentMigrationResponseFailed})
    mockConvertFormDataToMigrationCreateRequest.mockReturnValueOnce(mockReturnValue)

    await expect(createCourseCopyMutation({accountId, courseId, formData})).rejects.toThrow(
      'Failed to create course',
    )
  })

  describe('when restrictEnrollmentsToCourseDates is true', () => {
    const modifiedFormData = {...formData, restrictEnrollmentsToCourseDates: true}

    it('should create a new course and copy content', async () => {
      mockDoFetchApi.mockResolvedValueOnce({json: courseCreationResult})
      mockDoFetchApi.mockResolvedValueOnce({response: contentMigrationResponseOk})
      mockConvertFormDataToMigrationCreateRequest.mockReturnValueOnce(mockReturnValue)

      const result = await createCourseCopyMutation({
        accountId,
        courseId,
        formData: modifiedFormData,
      })

      expect(doFetchApi).toHaveBeenCalledTimes(2)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/accounts/${accountId}/courses`,
        method: 'POST',
        body: {
          course: {
            name: formData.courseName,
            course_code: formData.courseCode,
            start_at: formData.newCourseStartDate?.toISOString(),
            end_at: formData.newCourseEndDate?.toISOString(),
            term_id: formData.selectedTerm?.id,
            restrict_enrollments_to_course_dates: true,
            time_zone: formData.courseTimeZone,
          },
          enroll_me: true,
        },
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/courses/${courseCreationResult.id}/content_migrations`,
        method: 'POST',
        body: mockReturnValue,
      })
      expect(result).toBe(courseCreationResult.id)
    })
  })

  describe('when restrictEnrollmentsToCourseDates is false', () => {
    const modifiedFormData = {...formData, restrictEnrollmentsToCourseDates: false}

    it('should not include start_at and end_at in course creation params', async () => {
      mockDoFetchApi.mockResolvedValueOnce({json: courseCreationResult})
      mockDoFetchApi.mockResolvedValueOnce({response: contentMigrationResponseOk})
      mockConvertFormDataToMigrationCreateRequest.mockReturnValueOnce(mockReturnValue)

      const result = await createCourseCopyMutation({
        accountId,
        courseId,
        formData: modifiedFormData,
      })

      expect(doFetchApi).toHaveBeenCalledTimes(2)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/accounts/${accountId}/courses`,
        method: 'POST',
        body: {
          course: {
            name: formData.courseName,
            course_code: formData.courseCode,
            term_id: formData.selectedTerm?.id,
            restrict_enrollments_to_course_dates: false,
            time_zone: formData.courseTimeZone,
          },
          enroll_me: true,
        },
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/courses/${courseCreationResult.id}/content_migrations`,
        method: 'POST',
        body: mockReturnValue,
      })
      expect(result).toBe(courseCreationResult.id)
    })
  })
})
