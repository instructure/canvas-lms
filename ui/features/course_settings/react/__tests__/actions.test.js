/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Actions from '../actions'
import {uploadFile as rawUploadFile} from '@canvas/upload-file'
import Helpers from '../helpers'

jest.mock('@canvas/upload-file', () => ({
  uploadFile: jest.fn(),
}))

jest.mock('../helpers', () => ({
  extractInfoFromEvent: jest.fn(),
  isValidImageType: jest.fn(),
}))

describe('Course Settings Actions', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('calling setModalVisibility produces the proper object', () => {
    let actual = Actions.setModalVisibility(true)
    let expected = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: true,
      },
    }

    expect(actual).toEqual(expected)

    actual = Actions.setModalVisibility(false)
    expected = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: false,
      },
    }

    expect(actual).toEqual(expected)
  })

  test('calling gotCourseImage produces the proper object', () => {
    const actual = Actions.gotCourseImage('http://imageUrl')
    const expected = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageUrl: 'http://imageUrl',
      },
    }

    expect(actual).toEqual(expected)
  })

  test('getCourseImage', async () => {
    const fakeResponse = {
      data: {
        image: 'http://imageUrl',
      },
    }

    const mockAjaxLib = {
      get: jest.fn().mockResolvedValue(fakeResponse),
    }

    const expectedAction = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageUrl: 'http://imageUrl',
      },
    }

    const dispatches = []
    const dispatch = action => {
      dispatches.push(action)
      return action
    }

    await Actions.getCourseImage(1, 'image', mockAjaxLib)(dispatch)

    expect(dispatches).toEqual([expect.objectContaining(expectedAction)])
  })

  test('setCourseImageId creates the proper action', () => {
    const actual = Actions.setCourseImageId('http://imageUrl', 12)
    const expected = {
      type: 'SET_COURSE_IMAGE_ID',
      payload: {
        imageUrl: 'http://imageUrl',
        imageId: 12,
      },
    }

    expect(actual).toEqual(expected)
  })

  test('prepareSetImage with a imageUrl calls putImageData', async () => {
    const mockAjaxLib = {
      put: jest.fn().mockResolvedValue({}),
    }

    const dispatches = []
    const dispatch = action => {
      dispatches.push(action)
      return action
    }

    await Actions.prepareSetImage('http://imageUrl', 12, 'image', 1, mockAjaxLib)(dispatch)

    expect(mockAjaxLib.put).toHaveBeenCalledTimes(1)
  })

  // TODO: fix with msw
  test('prepareSetImage without a imageUrl calls the API to get the url', async () => {
    const imageUrl = 'http://imageUrl'
    const fakeResponse = {
      data: {
        url: imageUrl,
      },
    }

    const mockAjaxLib = {
      get: jest.fn().mockResolvedValue(fakeResponse),
      put: jest.fn().mockResolvedValue({}),
    }

    const dispatches = []
    const dispatch = action => {
      if (typeof action === 'function') {
        return action(dispatch)
      }
      dispatches.push(action)
      return action
    }

    await Actions.prepareSetImage(null, 1, 'image', 1, mockAjaxLib)(dispatch)

    // Wait for all promises to resolve
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(mockAjaxLib.get).toHaveBeenCalledWith('/api/v1/files/1')
    expect(mockAjaxLib.put).toHaveBeenCalledTimes(1)
    expect(dispatches).toEqual([
      expect.objectContaining({
        type: 'SET_COURSE_IMAGE_ID',
        payload: {
          imageUrl,
          imageId: 1,
        },
      }),
    ])
  })

  test('uploadFile returns false when image is not valid', async () => {
    const fakeDragonDropEvent = {
      dataTransfer: {
        files: [
          new File(['fake'], 'fake.jpg', {
            name: 'test file',
            size: 12345,
            type: 'image/tiff',
          }),
        ],
      },
      preventDefault: () => {},
    }

    Helpers.extractInfoFromEvent.mockReturnValue({
      type: 'image/tiff',
      file: fakeDragonDropEvent.dataTransfer.files[0],
    })
    Helpers.isValidImageType.mockReturnValue(false)

    const dispatches = []
    const dispatch = action => {
      dispatches.push(action)
      return action
    }

    await Actions.uploadFile(fakeDragonDropEvent, 1, 'image')(dispatch)

    expect(dispatches).toEqual([
      expect.objectContaining({
        type: 'REJECTED_UPLOAD',
        payload: {
          rejectedFiletype: 'image/tiff',
        },
      }),
    ])
  })

  test('uploadFile dispatches UPLOADING_IMAGE when file type is valid', async () => {
    const fakeFile = new File(['fake'], 'fake.jpg', {
      name: 'test file',
      size: 12345,
      type: 'image/jpeg',
    })

    const fakeDragonDropEvent = {
      dataTransfer: {
        files: [fakeFile],
      },
      preventDefault: () => {},
    }

    Helpers.extractInfoFromEvent.mockReturnValue({
      type: 'image/jpeg',
      file: fakeFile,
    })
    Helpers.isValidImageType.mockReturnValue(true)
    rawUploadFile.mockResolvedValue({})

    const dispatches = []
    const dispatch = action => {
      dispatches.push(action)
      return action
    }

    await Actions.uploadFile(fakeDragonDropEvent, 1, 'image')(dispatch)

    expect(dispatches[0]).toEqual(expect.objectContaining({type: 'UPLOADING_IMAGE'}))
  })

  test('uploadFile dispatches prepareSetImage when successful', async () => {
    const fileDownloadUrl = 'http://fileDownloadUrl'
    const fakeFile = new File(['fake'], 'fake.jpg', {
      name: 'test file',
      size: 12345,
      type: 'image/jpeg',
    })

    const mockAjaxLib = {
      put: jest.fn().mockResolvedValue({}),
      get: jest.fn().mockResolvedValue({
        data: {
          url: fileDownloadUrl,
        },
      }),
    }

    Helpers.extractInfoFromEvent.mockReturnValue({
      type: 'image/jpeg',
      file: fakeFile,
    })
    Helpers.isValidImageType.mockReturnValue(true)

    rawUploadFile.mockResolvedValue({
      url: fileDownloadUrl,
      id: 1,
    })

    const fakeDragonDropEvent = {
      dataTransfer: {
        files: [fakeFile],
      },
      preventDefault: () => {},
    }

    const dispatches = []
    const dispatch = action => {
      if (typeof action === 'function') {
        return action(dispatch)
      }
      dispatches.push(action)
      return action
    }

    await Actions.uploadFile(fakeDragonDropEvent, 1, 'image', mockAjaxLib)(dispatch)

    // Wait for all promises to resolve
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(dispatches).toEqual([
      expect.objectContaining({type: 'UPLOADING_IMAGE'}),
      expect.objectContaining({
        type: 'SET_COURSE_IMAGE_ID',
        payload: {
          imageUrl: fileDownloadUrl,
          imageId: 1,
        },
      }),
    ])
  })
})
