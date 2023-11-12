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

import {Enrollment, ITEMS_PER_PAGE} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'

/**
 * Fetches temporary enrollment data for a user
 *
 * If isRecipient is true:
 *  - Fetches enrollments where the user is a recipient
 *
 * If isRecipient is false:
 *  - Fetches enrollments where the user is a provider
 *
 * @param {number} userId ID of the user to fetch data for
 * @param {boolean} isRecipient Fetch enrollments for recipients or providers
 * @returns {Promise<Enrollment[]>} Resolves to an array of enrollment data
 */
export async function fetchTemporaryEnrollments(
  userId: string,
  isRecipient: boolean
): Promise<Enrollment[]> {
  const entityType = isRecipient ? 'recipients' : 'providers'
  const params: Record<string, any> = {
    state: ['current_and_future'],
    per_page: ITEMS_PER_PAGE,
  }

  if (isRecipient) {
    params.temporary_enrollments_for_recipient = true
    params.include = 'temporary_enrollment_providers'
  } else {
    params.temporary_enrollment_recipients_for_provider = true
  }

  const {response, json} = await doFetchApi({
    path: `/api/v1/users/${userId}/enrollments`,
    params,
  })

  if (response.status === 204) {
    return []
  } else if (!response.ok) {
    throw new Error(`Failed to fetch ${entityType} data. Status: ${response.status}`)
  }

  return json
}

/**
 * Deletes an enrollment based on its ID and course ID
 *
 * @param {string} courseId ID of the course
 * @param {string} enrollmentId ID of the enrollment to delete
 * @param {Function} onDelete Callback function to call on successful delete
 * @returns {Promise<void>}
 */
export async function deleteEnrollment(
  courseId: string,
  enrollmentId: number,
  onDelete?: (enrollmentId: number) => void
): Promise<void> {
  try {
    // Note: Temporarily commented out in preparation for near-future feature work
    // const {response} = await doFetchApi({
    //   path: `/api/v1/courses/${courseId}/enrollments/${enrollmentId}`,
    //   method: 'DELETE',
    //   params: {task: 'delete'},
    // })

    // placeholder response for testing
    const response = {status: 200}

    if (response.status === 200 && onDelete) {
      onDelete(enrollmentId)
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to delete enrollment:', error)
  }
}
