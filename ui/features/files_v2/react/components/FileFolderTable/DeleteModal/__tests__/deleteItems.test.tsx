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

import {deleteItems} from '../deleteItems'
import {DeleteItemError} from '../DeleteItemError'
import {deleteItem} from '../../../../queries/deleteItem'
import {UnauthorizedError} from '../../../../../utils/apiUtils'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../../../fixtures/fakeData'

jest.mock('../../../../queries/deleteItem', () => ({
  deleteItem: jest.fn(),
}))

const mockDeleteItem = deleteItem as jest.MockedFunction<typeof deleteItem>

describe('deleteItems', () => {
  const mockFile = FAKE_FILES[0]
  const mockFolder = FAKE_FOLDERS[0]
  const anotherMockFile = FAKE_FILES[1]

  beforeEach(() => {
    mockDeleteItem.mockReset()
  })

  describe('successful deletion', () => {
    it('should call deleteItem for each item when all deletions succeed', async () => {
      mockDeleteItem.mockResolvedValue(undefined)

      const items = [mockFile, mockFolder, anotherMockFile]

      await deleteItems(items)

      expect(mockDeleteItem).toHaveBeenCalledTimes(3)
      expect(mockDeleteItem).toHaveBeenNthCalledWith(1, mockFile)
      expect(mockDeleteItem).toHaveBeenNthCalledWith(2, mockFolder)
      expect(mockDeleteItem).toHaveBeenNthCalledWith(3, anotherMockFile)
    })

    it('should complete successfully when given an empty array', async () => {
      await deleteItems([])
    })

    it('should complete successfully when given a single item and deleteItem resolves', async () => {
      mockDeleteItem.mockResolvedValue(undefined)

      await deleteItems([mockFile])
    })
  })

  describe('error handling', () => {
    it('should throw UnauthorizedError immediately when deleteItem throws UnauthorizedError', async () => {
      const unauthorizedError = new UnauthorizedError()
      mockDeleteItem.mockResolvedValueOnce(undefined).mockRejectedValueOnce(unauthorizedError)

      const items = [mockFile, mockFolder, FAKE_FILES[1]]

      await expect(deleteItems(items)).rejects.toThrow(UnauthorizedError)

      expect(mockDeleteItem).toHaveBeenCalledTimes(2)
      expect(mockDeleteItem).toHaveBeenNthCalledWith(1, mockFile)
      expect(mockDeleteItem).toHaveBeenNthCalledWith(2, mockFolder)
    })

    it('should collect failed items and throw DeleteItemError when some deletions fail', async () => {
      mockDeleteItem
        .mockRejectedValueOnce(new Error('Delete failed'))
        .mockResolvedValueOnce(undefined)
        .mockRejectedValueOnce(new Error('Another delete failed'))

      const items = [mockFile, mockFolder, anotherMockFile]

      try {
        await deleteItems(items)
      } catch (error) {
        expect(error).toBeInstanceOf(DeleteItemError)
        expect((error as DeleteItemError).failedItems).toEqual([mockFile, anotherMockFile])
      }
    })

    it('should throw DeleteItemError when all deletions fail', async () => {
      mockDeleteItem.mockRejectedValue(new Error('Delete failed'))

      const items = [mockFile, mockFolder]

      await expect(deleteItems(items)).rejects.toThrow(DeleteItemError)
    })
  })

  describe('deleteItem calls', () => {
    it('should not call deleteItem when items array is empty', async () => {
      await deleteItems([])

      expect(mockDeleteItem).not.toHaveBeenCalled()
    })

    it('should issue exact number of calls matches number of items', async () => {
      mockDeleteItem.mockResolvedValue(undefined)

      const items = [mockFile, mockFolder, anotherMockFile, mockFile]

      await deleteItems(items)

      expect(mockDeleteItem).toHaveBeenCalledTimes(4)
    })
  })
})
