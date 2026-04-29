/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {makeBulkItemRequests} from '../makeBulkItemRequests'
import {BulkItemRequestsError} from '../BultItemRequestsError'
import {UnauthorizedError} from '../../../utils/apiUtils'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'

describe('makeBulkItemRequests', () => {
  const mockRequestFn = vi.fn()

  beforeEach(() => {
    mockRequestFn.mockReset()
  })

  describe('successful execution', () => {
    it('should execute request function for all items', async () => {
      const items = [FAKE_FILES[0], FAKE_FOLDERS[0]]
      mockRequestFn.mockResolvedValue(undefined)

      await makeBulkItemRequests(items, mockRequestFn)

      expect(mockRequestFn).toHaveBeenCalledTimes(2)
      expect(mockRequestFn).toHaveBeenCalledWith(FAKE_FILES[0])
      expect(mockRequestFn).toHaveBeenCalledWith(FAKE_FOLDERS[0])
    })

    it('should not call request function when items array is empty', async () => {
      await makeBulkItemRequests([], mockRequestFn)

      expect(mockRequestFn).not.toHaveBeenCalled()
    })
  })

  describe('error handling', () => {
    it('re-throws UnauthorizedError immediately', async () => {
      const items = [FAKE_FILES[0], FAKE_FOLDERS[0], FAKE_FILES[1]]
      const unauthorizedError = new UnauthorizedError('Not authorized')

      mockRequestFn
        .mockResolvedValueOnce(undefined)
        .mockRejectedValueOnce(unauthorizedError)
        .mockResolvedValueOnce(undefined)

      await expect(makeBulkItemRequests(items, mockRequestFn)).rejects.toThrow(UnauthorizedError)

      expect(mockRequestFn).toHaveBeenCalledTimes(2)
    })

    it('collects failed items and throws BulkItemRequestsError when some items fail', async () => {
      const items = [FAKE_FILES[0], FAKE_FOLDERS[0], FAKE_FILES[1]]
      const genericError = new Error('Generic error')

      mockRequestFn
        .mockResolvedValueOnce(undefined)
        .mockRejectedValueOnce(genericError)
        .mockResolvedValueOnce(undefined)

      try {
        await makeBulkItemRequests(items, mockRequestFn)
      } catch (error) {
        expect(error).toBeInstanceOf(BulkItemRequestsError)
        expect((error as BulkItemRequestsError).failedItems).toEqual([FAKE_FOLDERS[0]])
      }

      expect(mockRequestFn).toHaveBeenCalledTimes(3)
    })

    it('collects multiple failed items correctly', async () => {
      const items = [FAKE_FILES[0], FAKE_FOLDERS[0], FAKE_FILES[1], FAKE_FOLDERS[1]]
      const genericError = new Error('Generic error')

      mockRequestFn
        .mockRejectedValueOnce(genericError)
        .mockResolvedValueOnce(undefined)
        .mockRejectedValueOnce(genericError)
        .mockResolvedValueOnce(undefined)

      try {
        await makeBulkItemRequests(items, mockRequestFn)
      } catch (error) {
        expect(error).toBeInstanceOf(BulkItemRequestsError)
        expect((error as BulkItemRequestsError).failedItems).toEqual([FAKE_FILES[0], FAKE_FILES[1]])
      }

      expect(mockRequestFn).toHaveBeenCalledTimes(4)
    })
  })
})
