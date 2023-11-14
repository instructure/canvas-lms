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

import {Enrollment, ITEMS_PER_PAGE, TemporaryEnrollmentPairing} from '../types'
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
 * Creates a temporary enrollment pairing object
 *
 * @param {string} rootAccountId Root account ID
 * @returns {Promise<TemporaryEnrollmentPairing>} Resolves to a temporary enrollment pairing object
 */
export async function createTemporaryEnrollmentPairing(
  rootAccountId: string
): Promise<TemporaryEnrollmentPairing> {
  try {
    const response = await doFetchApi({
      path: `/api/v1/accounts/${rootAccountId}/temporary_enrollment_pairings`,
      method: 'POST',
    })
    return response.json.temporary_enrollment_pairing
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to fetch temporary enrollment pairing: ${error.message}`)
    } else {
      throw new Error('Failed to fetch temporary enrollment pairing due to an unknown error')
    }
  }
}

/**
 * Deletes an enrollment
 *
 * @param {string} courseId ID of the course
 * @param {string} enrollmentId ID of the enrollment to delete
 * @returns {Promise<void>} API response
 */
export async function deleteEnrollment(courseId: string, enrollmentId: string): Promise<void> {
  try {
    return await doFetchApi({
      path: `/api/v1/courses/${courseId}/enrollments/${enrollmentId}`,
      params: {
        task: 'delete',
      },
      method: 'DELETE',
    })
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to delete enrollment: ${error.message}`)
    } else {
      throw new Error('Failed to delete enrollment due to an unknown error')
    }
  }
}

/**
 * Updates or creates an enrollment
 *
 * @param sectionId
 * @param enrollmentUserId
 * @param userId
 * @param pairingId
 * @param startDate
 * @param endDate
 * @param roleId
 * @returns {Promise<any>} API response
 */
export async function createEnrollment(
  sectionId: string,
  enrollmentUserId: string,
  userId: string,
  pairingId: string,
  startDate: Date,
  endDate: Date,
  roleId: string
): Promise<void> {
  try {
    return await doFetchApi({
      path: `/api/v1/sections/${sectionId}/enrollments`,
      params: {
        enrollment: {
          user_id: enrollmentUserId,
          temporary_enrollment_source_user_id: userId,
          temporary_enrollment_pairing_id: pairingId,
          start_at: startDate.toISOString(),
          end_at: endDate.toISOString(),
          role_id: roleId,
        },
      },
      method: 'POST',
    })
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to create enrollment:`, error)
    } else {
      throw new Error(`Failed to create enrollment due to an unknown error`)
    }
  }
}
