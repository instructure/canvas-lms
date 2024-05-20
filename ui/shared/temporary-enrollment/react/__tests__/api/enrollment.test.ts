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

import {
  createEnrollment,
  createTemporaryEnrollmentPairing,
  deleteEnrollment,
  fetchTemporaryEnrollments,
  getTemporaryEnrollmentPairing,
} from '../../api/enrollment'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {type Enrollment, ITEMS_PER_PAGE, type User} from '../../types'

// Mock the API call
jest.mock('@canvas/do-fetch-api-effect')

const mockRecipientUser: User = {
  id: '123',
  name: 'Mark Rogers',
}

const mockProviderUser: User = {
  id: '789',
  name: 'Michelle Gonalez',
}

const mockSomeUser: User = {
  id: '6789',
  name: 'Some User',
  avatar_url: 'https://someurl.com/avatar.png',
}

const mockEnrollment: Enrollment = {
  id: '1',
  course_id: '101',
  start_at: '2023-01-01T00:00:00Z',
  end_at: '2023-06-01T00:00:00Z',
  role_id: '5',
  user: mockSomeUser,
  enrollment_state: 'active',
  limit_privileges_to_course_section: false,
  temporary_enrollment_pairing_id: 2,
  temporary_enrollment_source_user_id: 3,
  type: 'TeacherEnrollment',
}

describe('enrollment api', () => {
  describe('Enrollment functions', () => {
    const mockConsoleError = jest.fn()

    let originalConsoleError: typeof console.error

    beforeEach(() => {
      jest.clearAllMocks()
    })

    afterEach(() => {
      jest.restoreAllMocks()
    })

    beforeAll(() => {
      // eslint-disable-next-line no-console
      originalConsoleError = console.error
      // eslint-disable-next-line no-console
      console.error = mockConsoleError
    })

    afterAll(() => {
      // eslint-disable-next-line no-console
      console.error = originalConsoleError
    })

    describe('fetchTemporaryEnrollments', () => {
      it('fetches enrollments where the user is a recipient', async () => {
        const mockJson = Promise.resolve([
          {
            ...mockEnrollment,
            user: mockRecipientUser,
            temporary_enrollment_provider: mockProviderUser,
          },
        ])
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status: 200, ok: true},
          json: mockJson,
        })

        const result = await fetchTemporaryEnrollments('1', true)
        expect(result).toEqual(await mockJson)
      })

      it('fetches enrollments where the user is a provider', async () => {
        const mockJson = Promise.resolve([
          {
            ...mockEnrollment,
            user: mockRecipientUser,
          },
        ])
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status: 200, ok: true},
          json: mockJson,
        })

        const result = await fetchTemporaryEnrollments('1', false)
        expect(result).toEqual(await mockJson)
      })

      it('returns empty array when no enrollments are found', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status: 204, ok: true},
          json: [],
        })

        const result = await fetchTemporaryEnrollments('1', true)
        expect(result).toEqual([])
      })

      it('should throw an error when doFetchApi fails', async () => {
        ;(doFetchApi as jest.Mock).mockRejectedValue(new Error('An error occurred'))
        await expect(fetchTemporaryEnrollments('1', true)).rejects.toThrow('An error occurred')
      })

      it.each([
        [400, 'Bad Request'],
        [401, 'Unauthorized'],
        [403, 'Forbidden'],
        [404, 'Not Found'],
        [500, 'Internal Server Error'],
      ])('should throw an error when doFetchApi returns status %i', async (status, statusText) => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status, statusText, ok: false},
          json: Promise.resolve({error: statusText}),
        })
        await expect(fetchTemporaryEnrollments('1', true)).rejects.toThrow(
          new Error(`Failed to get temporary enrollments for recipient`)
        )
      })

      it('should return enrollment data with the correct type for a provider', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status: 200, ok: true},
          json: Promise.resolve([{}]),
          link: null,
        })
        await fetchTemporaryEnrollments('1', false)
        expect(doFetchApi).toHaveBeenCalledWith(
          expect.objectContaining({
            path: '/api/v1/users/1/enrollments',
            params: expect.objectContaining({
              state: ['current_and_future'],
              per_page: ITEMS_PER_PAGE,
              temporary_enrollment_recipients_for_provider: true,
            }),
          })
        )
      })

      it('should return enrollment data with the correct type for a recipient', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
          response: {status: 200, ok: true},
          json: Promise.resolve([{}]),
          link: null,
        })
        await fetchTemporaryEnrollments('1', true)
        expect(doFetchApi).toHaveBeenCalledWith(
          expect.objectContaining({
            path: '/api/v1/users/1/enrollments',
            params: expect.objectContaining({
              state: ['current_and_future'],
              per_page: ITEMS_PER_PAGE,
              temporary_enrollments_for_recipient: true,
              include: 'temporary_enrollment_providers',
            }),
          })
        )
      })
    })

    describe('deleteEnrollment', () => {
      beforeEach(() => {
        jest.clearAllMocks()
      })

      it('completes successful deletion without errors', async () => {
        const mockResponse = {response: {status: 204}}
        ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
        const courseId = '1'
        const enrollmentId = '2'
        await expect(deleteEnrollment(courseId, enrollmentId)).resolves.not.toThrow()
        expect(doFetchApi).toHaveBeenCalledWith({
          path: `/api/v1/courses/${courseId}/enrollments/${enrollmentId}`,
          method: 'DELETE',
          params: {task: 'delete'},
        })
        expect(mockConsoleError).not.toHaveBeenCalled()
      })

      it('throws a specific error message on failure', async () => {
        const mockError: Error = new Error('Network error occurred')
        ;(doFetchApi as jest.Mock).mockRejectedValue(mockError)
        const courseId = '1'
        const enrollmentId = '2'
        try {
          await deleteEnrollment(courseId, enrollmentId)
        } catch (error) {
          if (error instanceof Error) {
            expect(error.message).toBe(`Failed to delete temporary enrollment`)
          } else {
            expect(error).toBeInstanceOf(Error)
          }
        }
      })

      it('handles non-200 status code gracefully', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({response: {status: 404}})
        try {
          await deleteEnrollment('1', '2')
        } catch (e: any) {
          expect(e.message).toBe('Failed to delete enrollment: HTTP status code 404')
        }
      })
    })

    describe('fetchTemporaryEnrollmentPairing', () => {
      it('creates temporary enrollment pairing successfully', async () => {
        const mockResponse = {
          json: {
            temporary_enrollment_pairing: {
              id: '143',
              root_account_id: '2',
              workflow_state: 'active',
              created_at: '2024-01-12T20:02:47Z',
              updated_at: '2024-01-12T20:02:47Z',
              created_by_id: '1',
              deleted_by_id: null,
              ending_enrollment_state: 'completed',
            },
          },
        }
        ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
        const rootAccountId = '2'
        const result = await createTemporaryEnrollmentPairing(rootAccountId, 'completed')
        expect(result).toEqual(mockResponse.json.temporary_enrollment_pairing)
      })

      it('throws a specific error message on failure', async () => {
        const mockError: Error = new Error('Network error occurred')
        ;(doFetchApi as jest.Mock).mockRejectedValue(mockError)
        const rootAccountId = '2'
        try {
          await createTemporaryEnrollmentPairing(rootAccountId, 'completed')
        } catch (error) {
          if (error instanceof Error) {
            expect(error.message).toBe(`Failed to create temporary enrollment pairing`)
          } else {
            expect(error).toBeInstanceOf(Error)
          }
        }
      })
    })

    describe('getTemporaryEnrollmentPairing', () => {
      it('retrieves temporary enrollment pairing successfully', async () => {
        const accountId = '2'
        const pairingId = 143
        const mockResponse = {
          json: {
            temporary_enrollment_pairing: {
              id: '143',
              root_account_id: '2',
              workflow_state: 'active',
              created_at: '2024-01-12T20:02:47Z',
              updated_at: '2024-01-12T20:02:47Z',
              created_by_id: '1',
              deleted_by_id: null,
              ending_enrollment_state: 'completed',
            },
          },
        }
        ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
        const result = await getTemporaryEnrollmentPairing(accountId, pairingId)
        expect(result).toEqual(mockResponse.json.temporary_enrollment_pairing)
      })

      it('throws a specific error message on failure', async () => {
        const accountId = '2'
        const pairingId = 143
        const mockError: Error = new Error('Network error occurred')
        ;(doFetchApi as jest.Mock).mockRejectedValue(mockError)
        try {
          await getTemporaryEnrollmentPairing(accountId, pairingId)
        } catch (error) {
          if (error instanceof Error) {
            expect(error.message).toBe('Failed to retrieve temporary enrollment pairing')
          } else {
            expect(error).toBeInstanceOf(Error)
          }
        }
      })

      it('throws an unknown error message when the error is not an instance of Error', async () => {
        const accountId = '2'
        const pairingId = 143
        const mockError = 'Some non-Error value'
        ;(doFetchApi as jest.Mock).mockRejectedValue(mockError)
        try {
          await getTemporaryEnrollmentPairing(accountId, pairingId)
        } catch (error: any) {
          expect(error.message).toBe(
            'Failed to retrieve temporary enrollment pairing due to an unknown error'
          )
        }
      })
    })

    describe('createEnrollment', () => {
      const mockParams: [string, string, string, string, boolean, Date, Date, string] = [
        '1',
        '1',
        '2',
        '1',
        false,
        new Date('2022-01-01'),
        new Date('2022-06-01'),
        '1',
      ]

      it('calls doFetchApi with correct parameters', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({response: {status: 204}})
        await expect(createEnrollment(...mockParams)).resolves.not.toThrow()
        expect(doFetchApi).toHaveBeenCalledWith({
          path: `/api/v1/sections/${mockParams[0]}/enrollments`,
          params: {
            enrollment: {
              user_id: '1',
              temporary_enrollment_source_user_id: '2',
              temporary_enrollment_pairing_id: '1',
              limit_privileges_to_course_section: false,
              start_at: '2022-01-01T00:00:00.000Z',
              end_at: '2022-06-01T00:00:00.000Z',
              role_id: '1',
            },
          },
          method: 'POST',
        })
        expect(mockConsoleError).not.toHaveBeenCalled()
      })

      it('handles JSON parsing error', async () => {
        ;(doFetchApi as jest.Mock).mockRejectedValueOnce({
          response: {
            status: 400,
            text: async () => {
              throw new Error('Invalid JSON data')
            },
          },
        })
        await expect(async () => {
          try {
            await createEnrollment(...mockParams)
          } catch (error: any) {
            expect(error.message).toBe('Unable to process your request, please try again later')
            throw error
          }
        }).rejects.toThrow()
      })

      // server-side error messages found here: app/controllers/enrollments_api_controller.rb
      describe('user-facing doFetchApi server error message string translations', () => {
        it.each([
          {
            // concluded_course
            apiMessage: "Can't add an enrollment to a concluded course.",
            translatedMessage: 'Cannot add a temporary enrollment to a concluded course',
          },
          {
            // inactive_role
            apiMessage: 'Cannot create an enrollment with this role because it is inactive.',
            translatedMessage: 'Cannot create a temporary enrollment with an inactive role',
          },
          {
            // base_type_mismatch
            apiMessage: 'The specified type must match the base type for the role',
            translatedMessage: 'The specified type must match the base type for the role',
          },
          {
            // default
            apiMessage: 'Some other error message',
            translatedMessage: 'Failed to create temporary enrollment, please try again later',
          },
        ])('Translate API error message', async ({apiMessage, translatedMessage}) => {
          const mockJsonFunction = jest.fn().mockResolvedValue({message: apiMessage})
          ;(doFetchApi as jest.Mock).mockRejectedValueOnce({
            response: {
              json: mockJsonFunction,
              status: 500,
            },
          })
          await expect(createEnrollment(...mockParams)).rejects.toThrow(translatedMessage)
        })
      })
    })
  })
})
