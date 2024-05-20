/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import * as uploadFileModule from '@canvas/upload-file'

import {addAttachmentsFn, removeAttachmentFn} from '../attachments'

const fileInput = {
  currentTarget: {
    files: [
      {
        url: 'https://example.com/FakeFile1.txt',
        name: 'FakeFile1.txt',
      },
      {
        url: 'https://example.com/FakeFile2.txt',
        name: 'FakeFile2.txt',
      },
    ],
  },
}

const getRemoveAttachment = (mockSetAttachments = jest.fn()) => {
  return removeAttachmentFn(mockSetAttachments)
}

const getAddAttachments = ({
  mockSetAttachments = jest.fn(),
  mockSetPendingUploads = jest.fn(),
  attachmentFolderId = '1983',
  mockSetOnFailure = jest.fn(),
  mockSetOnSuccess = jest.fn(),
} = {}) => {
  return addAttachmentsFn(
    mockSetAttachments,
    mockSetPendingUploads,
    attachmentFolderId,
    mockSetOnFailure,
    mockSetOnSuccess
  )
}

// VICE-4065 - remove or rewrite to remove spies on uploadFileModule import
describe.skip('addAttachmentsFn', () => {
  beforeEach(() => {
    uploadFileModule.uploadFiles = jest.fn().mockResolvedValue([])
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('returns a function', () => {
    expect(getAddAttachments()).toBeInstanceOf(Function)
  })

  describe('returned function', () => {
    it('uploads files', async () => {
      const addAttachments = getAddAttachments()

      await addAttachments(fileInput)

      await expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith(
        [
          {name: 'FakeFile1.txt', url: 'https://example.com/FakeFile1.txt'},
          {name: 'FakeFile2.txt', url: 'https://example.com/FakeFile2.txt'},
        ],
        '/api/v1/folders/1983/files'
      )
    })

    it('tracks pending uploads', async () => {
      const mockSetPendingUploads = jest.fn()
      const addAttachments = getAddAttachments({mockSetPendingUploads})
      expect(mockSetPendingUploads).toHaveBeenCalledTimes(0)

      await addAttachments(fileInput)

      await expect(mockSetPendingUploads).toHaveBeenCalledTimes(2)
    })

    it('saves added attachments', async () => {
      const mockSetAttachments = jest.fn()
      const addAttachments = getAddAttachments({mockSetAttachments})

      await addAttachments(fileInput)

      expect(mockSetAttachments).toHaveBeenCalledTimes(1)
    })

    it('sets success message', async () => {
      const mockSetOnSuccess = jest.fn()
      const mockSetOnFailure = jest.fn()
      const addAttachments = getAddAttachments({mockSetOnSuccess, mockSetOnFailure})

      await addAttachments(fileInput)

      expect(mockSetOnFailure).not.toHaveBeenCalled()
      expect(mockSetOnSuccess).toHaveBeenCalled()
    })

    it('sets failure message when no files', async () => {
      const mockSetOnSuccess = jest.fn()
      const mockSetOnFailure = jest.fn()
      const addAttachments = getAddAttachments({mockSetOnSuccess, mockSetOnFailure})

      await addAttachments({currentTarget: {files: []}})

      expect(mockSetOnFailure).toHaveBeenCalled()
      expect(mockSetOnSuccess).not.toHaveBeenCalled()
    })

    it('sets failure message when upload fails', async () => {
      uploadFileModule.uploadFiles = jest.fn().mockImplementation(() => {
        throw new Error()
      })
      const mockSetOnSuccess = jest.fn()
      const mockSetOnFailure = jest.fn()
      const addAttachments = getAddAttachments({mockSetOnSuccess, mockSetOnFailure})

      await addAttachments(fileInput)

      expect(mockSetOnFailure).toHaveBeenCalled()
    })
  })
})

describe('removeAttachmentFn', () => {
  it('returns a function', () => {
    expect(getRemoveAttachment()).toBeInstanceOf(Function)
  })

  describe('returned function', () => {
    it('removes correct attachment', () => {
      const mockSetAttachments = jest.fn().mockImplementation(fn => {
        return fn([{id: '1983'}, {id: '9999'}])
      })
      const removeAttachment = getRemoveAttachment(mockSetAttachments)

      removeAttachment('1983')

      expect(mockSetAttachments).toHaveReturnedWith([{id: '9999'}])
    })

    it('removes no attachments when no match', () => {
      const mockSetAttachments = jest.fn().mockImplementation(fn => {
        return fn([{id: '1983'}, {id: '9999'}])
      })
      const removeAttachment = getRemoveAttachment(mockSetAttachments)

      removeAttachment('1984')

      expect(mockSetAttachments).toHaveReturnedWith([{id: '1983'}, {id: '9999'}])
    })

    it('removes no attachments when empty id', () => {
      const mockSetAttachments = jest.fn().mockImplementation(fn => {
        return fn([{id: '1983'}, {id: '9999'}])
      })
      const removeAttachment = getRemoveAttachment(mockSetAttachments)

      removeAttachment('')

      expect(mockSetAttachments).toHaveReturnedWith([{id: '1983'}, {id: '9999'}])
    })

    it('removes no attachments when invalid id', () => {
      const mockSetAttachments = jest.fn().mockImplementation(fn => {
        return fn([{id: '1983'}, {id: '9999'}])
      })
      const removeAttachment = getRemoveAttachment(mockSetAttachments)

      removeAttachment(null)

      expect(mockSetAttachments).toHaveReturnedWith([{id: '1983'}, {id: '9999'}])
    })
  })
})
