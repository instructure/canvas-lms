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

import {Enrollment} from '@canvas/temporary-enrollment/react/types'
import doFetchApi from '@canvas/do-fetch-api-effect'

/**
 * Fetches temporary enrollment data for a user
 *
 * If isRecipient is true:
 *  - Fetches enrollments where the user is a recipient
 *  - These are enrollments that the user has permission to read and that are
 *    active or pending
 *
 * If isRecipient is false:
 *  - Fetches enrollments where the user is a provider
 *  - Looks for temporary enrollments for the recipient and returns
 *    corresponding provider enrollments that are active or pending by date
 *
 * @param {number} userId ID of the user to fetch data for
 * @param {boolean} isRecipient Whether to fetch recipients or providers
 * @returns {Promise} Resolves to an array of enrollment data
 */
export async function fetchTemporaryEnrollments(
  userId: number,
  isRecipient: boolean
): Promise<Enrollment[]> {
  let responseStatus = -1
  const entityType = isRecipient ? 'recipients' : 'providers'

  try {
    // destructuring for clarity
    const {response, json} = await doFetchApi({
      path: `/api/v1/users/${userId}/enrollments`,
      params: {
        state: ['active', 'invited'],
        [`temporary_enrollment_${entityType}`]: true,
      },
    })

    responseStatus = response.status

    if (responseStatus === 204) {
      // No enrollments found
      return []
    } else if (!response.ok) {
      throw new Error(`Failed to fetch ${entityType} data. Status: ${responseStatus}`)
    } else {
      return await json
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(
      `Failed to fetch ${entityType} data for user ${userId}. Status: ${responseStatus}`,
      error
    )

    return []
  }
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
  courseId: number,
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
