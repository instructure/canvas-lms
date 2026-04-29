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
import {type Enrollment, ITEMS_PER_PAGE, type User} from '../../types'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

// Track captured requests for verification
let lastCapturedRequest: {
  path: string
  method: string
  searchParams?: Record<string, string>
  body?: any
} | null = null

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
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  describe('Enrollment functions', () => {
    const mockConsoleError = vi.fn()

    let originalConsoleError: typeof console.error

    beforeEach(() => {
      vi.clearAllMocks()
      lastCapturedRequest = null
    })

    afterEach(() => {
      vi.restoreAllMocks()
    })

    beforeAll(() => {
      originalConsoleError = console.error

      console.error = mockConsoleError
    })

    afterAll(() => {
      console.error = originalConsoleError
    })

    describe('fetchTemporaryEnrollments', () => {
      it('fetches enrollments where the user is a recipient', async () => {
        const mockJson = {
          ...mockEnrollment,
          user: mockRecipientUser,
          temporary_enrollment_provider: mockProviderUser,
        }
        server.use(
          http.get('/api/v1/users/:userId/enrollments', () => {
            return HttpResponse.json(mockJson, {
              headers: {
                Link: '<http://example.com/api/v1/users/1/enrollments?page=1>; rel="current"',
              },
            })
          }),
        )

        const result = await fetchTemporaryEnrollments('1', true, '')
        expect(result.enrollments).toEqual(mockJson)
      })

      it('fetches enrollments where the user is a provider', async () => {
        const mockJson = {
          ...mockEnrollment,
          user: mockRecipientUser,
        }
        server.use(
          http.get('/api/v1/users/:userId/enrollments', () => {
            return HttpResponse.json(mockJson, {
              headers: {
                Link: '<http://example.com/api/v1/users/1/enrollments?page=1>; rel="current"',
              },
            })
          }),
        )

        const result = await fetchTemporaryEnrollments('1', false, 'first')
        expect(result.enrollments).toEqual(mockJson)
      })

      it('returns empty array when no enrollments are found', async () => {
        server.use(
          http.get('/api/v1/users/:userId/enrollments', () => {
            return HttpResponse.json([], {
              status: 204,
              headers: {
                Link: '<http://example.com/api/v1/users/1/enrollments?page=1>; rel="current"',
              },
            })
          }),
        )

        const result = await fetchTemporaryEnrollments('1', true, 'first')
        expect(result.enrollments).toEqual([])
      })

      it('should throw an error when fetch fails', async () => {
        server.use(http.get('/api/v1/users/:userId/enrollments', () => HttpResponse.error()))
        await expect(fetchTemporaryEnrollments('1', true, 'first')).rejects.toThrow()
      })

      it.each([
        [400, 'Bad Request'],
        [401, 'Unauthorized'],
        [403, 'Forbidden'],
        [404, 'Not Found'],
        [500, 'Internal Server Error'],
      ])('should throw an error when API returns status %i', async (status, statusText) => {
        server.use(
          http.get('/api/v1/users/:userId/enrollments', () => {
            return HttpResponse.json({error: 'Error'}, {status, statusText})
          }),
        )
        // doFetchApi throws FetchApiError which propagates directly
        // (the else if (!response.ok) code path in fetchTemporaryEnrollments is unreachable)
        await expect(fetchTemporaryEnrollments('1', true, 'first')).rejects.toThrow(
          `doFetchApi received a bad response: ${status} ${statusText}`,
        )
      })

      it('should return enrollment data with the correct type for a provider', async () => {
        server.use(
          http.get('/api/v1/users/:userId/enrollments', ({request}) => {
            const url = new URL(request.url)
            lastCapturedRequest = {
              path: url.pathname,
              method: 'GET',
              searchParams: Object.fromEntries(url.searchParams.entries()),
            }
            return HttpResponse.json([{}])
          }),
        )
        await fetchTemporaryEnrollments('1', false, 'first')
        expect(lastCapturedRequest).not.toBeNull()
        expect(lastCapturedRequest!.path).toBe('/api/v1/users/1/enrollments')
        expect(lastCapturedRequest!.searchParams).toMatchObject({
          'state[]': 'current_future_and_restricted',
          per_page: String(ITEMS_PER_PAGE),
          temporary_enrollment_recipients_for_provider: 'true',
        })
      })

      it('should return enrollment data with the correct type for a recipient', async () => {
        server.use(
          http.get('/api/v1/users/:userId/enrollments', ({request}) => {
            const url = new URL(request.url)
            lastCapturedRequest = {
              path: url.pathname,
              method: 'GET',
              searchParams: Object.fromEntries(url.searchParams.entries()),
            }
            return HttpResponse.json([{}])
          }),
        )
        await fetchTemporaryEnrollments('1', true, 'first')
        expect(lastCapturedRequest).not.toBeNull()
        expect(lastCapturedRequest!.path).toBe('/api/v1/users/1/enrollments')
        expect(lastCapturedRequest!.searchParams).toMatchObject({
          'state[]': 'current_future_and_restricted',
          per_page: String(ITEMS_PER_PAGE),
          temporary_enrollments_for_recipient: 'true',
        })
      })
    })

    describe('deleteEnrollment', () => {
      beforeEach(() => {
        vi.clearAllMocks()
        lastCapturedRequest = null
      })

      it('completes successful deletion without errors', async () => {
        const courseId = '1'
        const enrollmentId = '2'
        server.use(
          http.delete('/api/v1/courses/:courseId/enrollments/:enrollmentId', ({request}) => {
            const url = new URL(request.url)
            lastCapturedRequest = {
              path: url.pathname,
              method: 'DELETE',
              searchParams: Object.fromEntries(url.searchParams.entries()),
            }
            return new HttpResponse(null, {status: 204})
          }),
        )
        await expect(deleteEnrollment(courseId, enrollmentId)).resolves.not.toThrow()
        expect(lastCapturedRequest).not.toBeNull()
        expect(lastCapturedRequest!.path).toBe(`/api/v1/courses/${courseId}/enrollments/${enrollmentId}`)
        expect(lastCapturedRequest!.method).toBe('DELETE')
        expect(lastCapturedRequest!.searchParams).toMatchObject({task: 'delete'})
        expect(mockConsoleError).not.toHaveBeenCalled()
      })

      it('throws a specific error message on failure', async () => {
        const courseId = '1'
        const enrollmentId = '2'
        server.use(
          http.delete('/api/v1/courses/:courseId/enrollments/:enrollmentId', () =>
            HttpResponse.error(),
          ),
        )
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
        server.use(
          http.delete('/api/v1/courses/:courseId/enrollments/:enrollmentId', () =>
            HttpResponse.json({error: 'Not found'}, {status: 404}),
          ),
        )
        try {
          await deleteEnrollment('1', '2')
        } catch (e: any) {
          // The function catches all errors and throws a generic message
          expect(e.message).toBe('Failed to delete temporary enrollment')
        }
      })
    })

    describe('fetchTemporaryEnrollmentPairing', () => {
      it('creates temporary enrollment pairing successfully', async () => {
        const mockPairing = {
          id: '143',
          root_account_id: '2',
          workflow_state: 'active',
          created_at: '2024-01-12T20:02:47Z',
          updated_at: '2024-01-12T20:02:47Z',
          created_by_id: '1',
          deleted_by_id: null,
          ending_enrollment_state: 'completed',
        }
        server.use(
          http.post('/api/v1/accounts/:accountId/temporary_enrollment_pairings', () => {
            return HttpResponse.json({temporary_enrollment_pairing: mockPairing})
          }),
        )
        const rootAccountId = '2'
        const result = await createTemporaryEnrollmentPairing(rootAccountId, 'completed')
        expect(result).toEqual(mockPairing)
      })

      it('throws a specific error message on failure', async () => {
        server.use(
          http.post('/api/v1/accounts/:accountId/temporary_enrollment_pairings', () =>
            HttpResponse.error(),
          ),
        )
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
        const mockPairing = {
          id: '143',
          root_account_id: '2',
          workflow_state: 'active',
          created_at: '2024-01-12T20:02:47Z',
          updated_at: '2024-01-12T20:02:47Z',
          created_by_id: '1',
          deleted_by_id: null,
          ending_enrollment_state: 'completed',
        }
        server.use(
          http.get('/api/v1/accounts/:accountId/temporary_enrollment_pairings/:pairingId', () => {
            return HttpResponse.json({temporary_enrollment_pairing: mockPairing})
          }),
        )
        const result = await getTemporaryEnrollmentPairing(accountId, pairingId)
        expect(result).toEqual(mockPairing)
      })

      it('throws a specific error message on failure', async () => {
        const accountId = '2'
        const pairingId = 143
        server.use(
          http.get('/api/v1/accounts/:accountId/temporary_enrollment_pairings/:pairingId', () =>
            HttpResponse.error(),
          ),
        )
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

      it('handles network errors with standard error message', async () => {
        const accountId = '2'
        const pairingId = 143
        // With real doFetchApi, network errors are always Error instances
        // The "unknown error" code path is defensive code for edge cases
        server.use(
          http.get('/api/v1/accounts/:accountId/temporary_enrollment_pairings/:pairingId', () => {
            return HttpResponse.error()
          }),
        )
        try {
          await getTemporaryEnrollmentPairing(accountId, pairingId)
        } catch (error: any) {
          // doFetchApi throws Error instances, so we get the standard message
          expect(error.message).toBe('Failed to retrieve temporary enrollment pairing')
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

      it('calls API with correct parameters', async () => {
        server.use(
          http.post('/api/v1/sections/:sectionId/enrollments', async ({request}) => {
            const url = new URL(request.url)
            lastCapturedRequest = {
              path: url.pathname,
              method: 'POST',
              searchParams: Object.fromEntries(url.searchParams.entries()),
            }
            return new HttpResponse(null, {status: 200})
          }),
        )
        await expect(createEnrollment(...mockParams)).resolves.not.toThrow()
        expect(lastCapturedRequest).not.toBeNull()
        expect(lastCapturedRequest!.path).toBe(`/api/v1/sections/${mockParams[0]}/enrollments`)
        expect(lastCapturedRequest!.method).toBe('POST')
        // doFetchApi serializes params to URL query string with bracket notation
        expect(lastCapturedRequest!.searchParams).toMatchObject({
          'enrollment[user_id]': '1',
          'enrollment[temporary_enrollment_source_user_id]': '2',
          'enrollment[temporary_enrollment_pairing_id]': '1',
          'enrollment[limit_privileges_to_course_section]': 'false',
          'enrollment[start_at]': '2022-01-01T00:00:00.000Z',
          'enrollment[end_at]': '2022-06-01T00:00:00.000Z',
          'enrollment[role_id]': '1',
        })
        expect(mockConsoleError).not.toHaveBeenCalled()
      })

      it('handles network error', async () => {
        server.use(
          http.post('/api/v1/sections/:sectionId/enrollments', () => HttpResponse.error()),
        )
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
      describe('user-facing API server error message string translations', () => {
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
          server.use(
            http.post('/api/v1/sections/:sectionId/enrollments', () => {
              return HttpResponse.json({message: apiMessage}, {status: 500})
            }),
          )
          await expect(createEnrollment(...mockParams)).rejects.toThrow(translatedMessage)
        })
      })
    })
  })
})
