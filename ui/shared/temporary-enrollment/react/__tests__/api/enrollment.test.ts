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

import {fetchTemporaryEnrollments, deleteEnrollment} from '../../api/enrollment'
import doFetchApi from '@canvas/do-fetch-api-effect'

// Mock the API call
jest.mock('@canvas/do-fetch-api-effect')

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
        const mockJson = Promise.resolve([{id: 1}])
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status: 200, ok: true},
          json: mockJson,
        })

        const result = await fetchTemporaryEnrollments(1, true)
        expect(result).toEqual(await mockJson)
      })

      it('fetches enrollments where the user is a provider', async () => {
        const mockJson = Promise.resolve([{id: 2}])
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status: 200, ok: true},
          json: mockJson,
        })

        const result = await fetchTemporaryEnrollments(1, false)
        expect(result).toEqual(await mockJson)
      })

      it('returns empty array when no enrollments are found', async () => {
        ;(doFetchApi as jest.Mock).mockResolvedValue({
          response: {status: 204, ok: true},
        })

        const result = await fetchTemporaryEnrollments(1, true)
        expect(result).toEqual([])
      })

      it('handles errors gracefully', async () => {
        ;(doFetchApi as jest.Mock).mockRejectedValue(new Error('An error occurred'))

        const result = await fetchTemporaryEnrollments(1, true)

        expect(result).toEqual([])
        expect(mockConsoleError).toHaveBeenCalled()
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
    })
  })
})
