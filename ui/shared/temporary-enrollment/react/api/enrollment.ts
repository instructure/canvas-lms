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

import type {Enrollment, TemporaryEnrollmentPairing} from '../types'
import {ITEMS_PER_PAGE} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('temporary_enrollment')

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
    const errorMessage = isRecipient
      ? I18n.t('Failed to get temporary enrollments for recipient')
      : I18n.t('Failed to get temporary enrollments for provider')
    throw new Error(errorMessage)
  }

  return json
}

/**
 * Creates a temporary enrollment pairing object
 *
 * @param {string} accountId ID of the account
 * @param {string} endingEnrollmentState Ending enrollment state (e.g., “deleted”, “completed”, “inactive”)
 * @returns {Promise<TemporaryEnrollmentPairing>} Resolves to a temporary enrollment pairing object
 */
export async function createTemporaryEnrollmentPairing(
  accountId: string,
  endingEnrollmentState: string
): Promise<TemporaryEnrollmentPairing> {
  try {
    const response = await doFetchApi({
      path: `/api/v1/accounts/${accountId}/temporary_enrollment_pairings`,
      method: 'POST',
      params: {
        ending_enrollment_state: endingEnrollmentState,
      },
    })
    return response.json.temporary_enrollment_pairing
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(I18n.t('Failed to create temporary enrollment pairing'))
    } else {
      throw new Error(
        I18n.t('Failed to create temporary enrollment pairing due to an unknown error')
      )
    }
  }
}

/**
 * Retrieves a single temporary enrollment pairing object, by its ID
 *
 * @param {string} accountId ID of the account
 * @param {number} pairingId ID of the temporary enrollment pairing to retrieve
 * @returns {Promise<TemporaryEnrollmentPairing>} Resolves to the temporary enrollment pairing object
 */
export async function getTemporaryEnrollmentPairing(
  accountId: string,
  pairingId: number
): Promise<TemporaryEnrollmentPairing> {
  try {
    const response = await doFetchApi({
      path: `/api/v1/accounts/${accountId}/temporary_enrollment_pairings/${pairingId}`,
      method: 'GET',
    })

    return response.json.temporary_enrollment_pairing
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(I18n.t('Failed to retrieve temporary enrollment pairing'))
    } else {
      throw new Error(
        I18n.t('Failed to retrieve temporary enrollment pairing due to an unknown error')
      )
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
    await doFetchApi({
      path: `/api/v1/courses/${courseId}/enrollments/${enrollmentId}`,
      params: {
        task: 'delete',
      },
      method: 'DELETE',
    })
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(I18n.t('Failed to delete temporary enrollment'))
    } else {
      throw new Error(I18n.t('Failed to delete temporary enrollment due to an unknown error'))
    }
  }
}

/**
 * Creates a temporary enrollment
 *
 * @param {string} sectionId ID of the section
 * @param {string} enrollmentUserId ID of the recipient user
 * @param {string} userId ID of the provider user
 * @param {string} pairingId ID of the pairing
 * @param {Date} startDate Start date of the temporary enrollment
 * @param {Date} endDate End date of the temporary enrollment
 * @param {string} roleId ID of the role
 * @returns {Promise<void>} Promise that resolves when the temporary enrollment
 *                          is successfully created
 * @throws {Error} If an error occurs while creating the temporary enrollment
 */
export async function createEnrollment(
  sectionId: string,
  enrollmentUserId: string,
  userId: string,
  pairingId: string,
  enrollmentLimitPrivilegesToSection: boolean,
  startDate: Date,
  endDate: Date,
  roleId: string
): Promise<void> {
  try {
    await doFetchApi({
      path: `/api/v1/sections/${sectionId}/enrollments`,
      params: {
        enrollment: {
          user_id: enrollmentUserId,
          temporary_enrollment_source_user_id: userId,
          temporary_enrollment_pairing_id: pairingId,
          limit_privileges_to_course_section: enrollmentLimitPrivilegesToSection,
          start_at: startDate.toISOString(),
          end_at: endDate.toISOString(),
          role_id: roleId,
        },
      },
      method: 'POST',
    })
  } catch (error) {
    const defaultErrorMessage = I18n.t(
      'Failed to create temporary enrollment, please try again later'
    )
    // @ts-expect-error because doFetchApi is not type safe (yet)
    const serverErrorMessage: string = (await error.response?.json())?.message || ''
    const serverErrorTranslations: {[key: string]: string} = {
      "Can't add an enrollment to a concluded course.": I18n.t(
        'Cannot add a temporary enrollment to a concluded course'
      ),
      'Cannot create an enrollment with this role because it is inactive.': I18n.t(
        'Cannot create a temporary enrollment with an inactive role'
      ),
      'The specified type must match the base type for the role': I18n.t(
        'The specified type must match the base type for the role'
      ),
    }
    const errorMessage = serverErrorTranslations[serverErrorMessage] || defaultErrorMessage
    throw new Error(errorMessage)
  }
}
