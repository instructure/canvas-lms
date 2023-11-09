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

import {deleteEnrollment, fetchTemporaryEnrollments} from '../../api/enrollment'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Enrollment, ITEMS_PER_PAGE, User} from '../../types'

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
  id: 1,
  course_id: 101,
  start_at: '2023-01-01T00:00:00Z',
  end_at: '2023-06-01T00:00:00Z',
  role_id: '5',
  user: mockSomeUser,
  temporary_enrollment_pairing_id: 2,
  temporary_enrollment_source_user_id: 3,
  type: 'TeacherEnrollment',
}

describe('enrollment api', () => {
  describe('Enrollment functions', () => {
    const mockConsoleError = jest.fn()

    let originalConsoleError: typeof console.error

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
      beforeEach(() => {
        jest.clearAllMocks()
      })

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
          new Error(`Failed to fetch recipients data. Status: ${status}`)
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
              temporary_enrollments: true,
              state: ['current_and_future'],
              per_page: ITEMS_PER_PAGE,
              temporary_enrollment_recipients: true,
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
              temporary_enrollments: true,
              state: ['current_and_future'],
              per_page: ITEMS_PER_PAGE,
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

      it('successfully deletes an enrollment and calls onDelete', async () => {
        const onDeleteMock = jest.fn()
        ;(doFetchApi as jest.Mock).mockResolvedValue({response: {status: 200}})

        await deleteEnrollment(1, 2, onDeleteMock)

        expect(onDeleteMock).toHaveBeenCalledWith(2)
      })

      // TODO remove skip once deleteEnrollment is implemented
      it.skip('handles errors gracefully', async () => {
        ;(doFetchApi as jest.Mock).mockRejectedValue(new Error('An error occurred'))

        try {
          await deleteEnrollment(1, 2)
        } catch (e) {
          // eslint-disable-next-line no-console
          console.log('Caught error:', e)
        }

        // eslint-disable-next-line no-console
        console.log('mockConsoleError calls:', mockConsoleError.mock.calls.length)

        expect(mockConsoleError).toHaveBeenCalled()
      })

      it.skip('handles deletion without onDelete gracefully', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({response: {status: 200}})

        await expect(deleteEnrollment(1, 2)).resolves.not.toThrow()
      })

      it.skip('handles non-200 status code gracefully', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({response: {status: 404}})

        try {
          await deleteEnrollment(1, 2)
        } catch (e: any) {
          expect(e.message).toBe('Failed to delete enrollment: HTTP status code 404')
        }
      })
    })
  })
})
