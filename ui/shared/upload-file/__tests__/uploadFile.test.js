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

import {uploadFile, completeUpload} from '../index'

describe('Upload File', () => {
  beforeEach(() => {
    global.FormData = function () {
      const data = new Map()
      return {
        append: (key, value) => data.set(key, value),
        get: key => data.get(key),
        has: key => data.has(key),
        entries: () => data.entries(),
        toString: () => {
          const pairs = []
          data.forEach((value, key) => pairs.push(`${key}=${value}`))
          return pairs.join('&')
        },
      }
    }

    // Mock Blob
    global.Blob = function (content, options) {
      return {
        content,
        type: options?.type || '',
        size: content[0]?.length || 0,
        toString: () => content[0],
      }
    }
  })

  afterEach(() => {
    delete global.FormData
    delete global.Blob
  })

  test('uploadFile posts form data instead of json if necessary', async () => {
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_url: 'http://uploadUrl',
          },
        }),
      )
    })

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockReturnValueOnce(preflightResponse)
    postStub.mockResolvedValueOnce({data: {}})
    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {
      name: 'fake',
      'attachment[context_code]': 'course_1',
    }
    const file = new Blob(['fake'], {type: 'text/plain'})

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(postStub).toHaveBeenCalledWith(
      url,
      'name=fake&attachment%5Bcontext_code%5D=course_1&no_redirect=true',
    )
  })

  test('uploadFile requests no_redirect in preflight even if not specified', async () => {
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_url: 'http://uploadUrl',
          },
        }),
      )
    })

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockReturnValueOnce(preflightResponse)
    postStub.mockResolvedValueOnce({data: {}})
    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new Blob(['fake'], {type: 'text/plain'})

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(postStub).toHaveBeenCalledWith(url, {name: 'fake', no_redirect: true})
  })

  test('uploadFile threads through in direct to S3 case', async () => {
    const successUrl = 'http://successUrl'
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_params: {fakeKey: 'fakeValue', success_url: successUrl},
            upload_url: 'http://uploadUrl',
          },
        }),
      )
    })

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockReturnValueOnce(preflightResponse)
    postStub.mockResolvedValueOnce({data: {}})
    getStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new Blob(['fake'], {type: 'text/plain'})

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(getStub).toHaveBeenCalledWith(successUrl)
  })

  test('uploadFile threads through in inst-fs case', async () => {
    const successUrl = 'http://successUrl'
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_params: {fakeKey: 'fakeValue'},
            upload_url: 'http://uploadUrl',
          },
        }),
      )
    })

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          status: 201,
          data: {location: successUrl},
        }),
      )
    })

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockReturnValueOnce(preflightResponse)
    postStub.mockReturnValueOnce(postResponse)
    getStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new Blob(['fake'], {type: 'text/plain'})

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(getStub).toHaveBeenCalledWith(successUrl)
  })

  test('uploadFile threads through in local-storage case', async () => {
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_params: {fakeKey: 'fakeValue'},
            upload_url: 'http://uploadUrl',
          },
        }),
      )
    })

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {id: 1},
        }),
      )
    })

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockReturnValueOnce(preflightResponse)
    postStub.mockReturnValueOnce(postResponse)
    getStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new Blob(['fake'], {type: 'text/plain'})

    const response = await uploadFile(url, data, file, fakeAjaxLib)
    expect(response.id).toBe(1)
  })

  test('completeUpload unpacks embedded "attachments" wrapper if any', () => {
    const upload_url = 'http://uploadUrl'
    const preflightResponse = {
      attachments: [{upload_url}],
    }

    const postStub = jest.fn()
    postStub.mockResolvedValue({data: {}})
    const fakeAjaxLib = {post: postStub}

    const file = new Blob(['fake'], {type: 'text/plain'})

    return completeUpload(preflightResponse, file, {ajaxLib: fakeAjaxLib}).then(() => {
      expect(postStub).toHaveBeenCalledWith(upload_url, expect.any(Object), expect.any(Object))
    })
  })

  test('completeUpload wires up progress callback if any', () => {
    const postStub = jest.fn()
    postStub.mockResolvedValue({data: {}})
    const fakeAjaxLib = {post: postStub}

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new Blob(['fake'], {type: 'text/plain'})
    const onProgress = jest.fn()

    const options = {
      ajaxLib: fakeAjaxLib,
      onProgress,
    }

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(postStub).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(Object),
        expect.objectContaining({
          onUploadProgress: onProgress,
        }),
      )
    })
  })

  test('completeUpload skips GET after inst-fs upload if options.ignoreResult', () => {
    const successUrl = 'http://successUrl'

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          status: 201,
          data: {location: successUrl},
        }),
      )
    })

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockReturnValueOnce(postResponse)
    getStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new Blob(['fake'], {type: 'text/plain'})
    const options = {
      ajaxLib: fakeAjaxLib,
      ignoreResult: true,
    }

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(getStub).not.toHaveBeenCalled()
    })
  })

  test('completeUpload appends avatar include in GET after upload if options.includeAvatar', () => {
    const successUrl = 'http://successUrl'

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          status: 201,
          data: {location: successUrl},
        }),
      )
    })

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockReturnValueOnce(postResponse)
    getStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new Blob(['fake'], {type: 'text/plain'})
    const options = {
      ajaxLib: fakeAjaxLib,
      includeAvatar: true,
    }

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(getStub).toHaveBeenCalledWith(`${successUrl}?include=avatar`)
    })
  })

  test('completeUpload to S3 posts withCredentials false', () => {
    const successUrl = 'http://successUrl'

    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockResolvedValue({data: {}})
    getStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {
      upload_url: 'http://uploadUrl',
      success_url: successUrl,
    }
    const file = new Blob(['fake'], {type: 'text/plain'})
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(postStub).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(Object),
        expect.objectContaining({
          withCredentials: false,
        }),
      )
    })
  })

  test('completeUpload to non-S3 posts withCredentials true', () => {
    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockResolvedValue({data: {}})
    getStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new Blob(['fake'], {type: 'text/plain'})
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(postStub).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(Object),
        expect.objectContaining({
          withCredentials: true,
        }),
      )
    })
  })

  test('completeUpload does not add a null file to the upload POST', () => {
    const postStub = jest.fn()
    postStub.mockResolvedValue({data: {}})

    const fakeAjaxLib = {
      post: postStub,
    }

    const preflightResponse = {
      upload_url: 'http://uploadUrl',
      progress: {workflow_state: 'completed', results: {}},
    }
    const file = null
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(postStub).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(Object),
        expect.any(Object),
      )
      const formData = postStub.mock.calls[0][1]
      expect(formData.has('file')).toBe(false)
    })
  })

  test('completeUpload immediately waits on progress if given a progress and no upload_url', () => {
    const results = {id: 1}
    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockResolvedValue({data: {}})
    getStub.mockResolvedValue({data: {workflow_state: 'completed', results}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {progress: {workflow_state: 'queued', url: 'http://progressUrl'}}
    const file = null
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(data => {
      expect(postStub).not.toHaveBeenCalled()
      expect(data).toEqual(results)
    })
  })

  test('completeUpload waits on progress after upload POST if given both a progress and upload URL', () => {
    const results = {id: 1}
    const postStub = jest.fn()
    const getStub = jest.fn()
    postStub.mockResolvedValue({data: {}})
    getStub.mockResolvedValue({data: {workflow_state: 'completed', results}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {
      progress: {workflow_state: 'queued', url: 'http://progressUrl'},
      upload_url: 'http://uploadUrl',
    }
    const file = null
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(data => {
      expect(postStub).toHaveBeenCalled()
      expect(data).toEqual(results)
    })
  })

  test('uploadFile differentiates network failures during preflight', async () => {
    const fakeAjaxLib = {post: jest.fn()}
    fakeAjaxLib.post.mockRejectedValue({message: 'Network Error'}) // preflight attempt
    const file = new Blob(['fake'], {type: 'text/plain'})
    try {
      await uploadFile('http://preflightUrl', {}, file, fakeAjaxLib)
      expect(false).toBeTruthy() // preflight should fail
    } catch ({message}) {
      expect(message.match(/failed to initiate the upload/)).toBeTruthy()
    }
  })

  test('uploadFile differentiates network failures during POST to upload_url', async () => {
    const fakeAjaxLib = {post: jest.fn()}
    fakeAjaxLib.post.mockResolvedValueOnce({data: {upload_url: 'http://uploadUrl'}}) // preflight
    fakeAjaxLib.post.mockRejectedValue({message: 'Network Error'}) // upload attempt
    const file = new Blob(['fake'], {type: 'text/plain'})
    try {
      await uploadFile('http://preflightUrl', {}, file, fakeAjaxLib)
      expect(false).toBeTruthy() // upload should fail
    } catch ({message}) {
      expect(message.match(/service may be down/)).toBeTruthy()
    }
  })

  test('uploadFile differentiates network failures after upload', async () => {
    const fakeAjaxLib = {post: jest.fn(), get: jest.fn()}
    fakeAjaxLib.post.mockResolvedValueOnce({
      data: {
        upload_url: 'http://uploadUrl',
        success_url: 'http://successUrl',
      },
    }) // preflight
    fakeAjaxLib.post.mockResolvedValueOnce({data: {}}) // upload
    fakeAjaxLib.get.mockRejectedValue({message: 'Network Error'}) // success url attempt
    const file = new Blob(['fake'], {type: 'text/plain'})
    try {
      await uploadFile('http://preflightUrl', {}, file, fakeAjaxLib)
      expect(false).toBeTruthy() // finalization should fail
    } catch ({message}) {
      expect(message.match(/failed to complete the upload/)).toBeTruthy()
    }
  })
})
