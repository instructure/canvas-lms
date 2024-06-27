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
import sinon from 'sinon'

describe('Upload File', () => {
  test('uploadFile posts form data instead of json if necessary', async () => {
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_url: 'http://uploadUrl',
          },
        })
      )
    })

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.onCall(0).returns(preflightResponse)
    postStub.onCall(1).resolves({data: {}})
    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {
      name: 'fake',
      'attachment[context_code]': 'course_1',
    }
    const file = new File(['fake'], 'fake.txt')

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(
      postStub.calledWith(url, 'name=fake&attachment%5Bcontext_code%5D=course_1&no_redirect=true')
    ).toBeTruthy()
  })

  test('uploadFile requests no_redirect in preflight even if not specified', async () => {
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_url: 'http://uploadUrl',
          },
        })
      )
    })

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.onCall(0).returns(preflightResponse)
    postStub.onCall(1).resolves({data: {}})
    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new File(['fake'], 'fake.txt')

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(postStub.calledWith(url, {name: 'fake', no_redirect: true})).toBeTruthy()
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
        })
      )
    })

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.onCall(0).returns(preflightResponse)
    postStub.onCall(1).resolves({data: {}})
    getStub.resolves({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new File(['fake'], 'fake.txt')

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(getStub.calledWith(successUrl)).toBeTruthy()
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
        })
      )
    })

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          status: 201,
          data: {location: successUrl},
        })
      )
    })

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.onCall(0).returns(preflightResponse)
    postStub.onCall(1).returns(postResponse)
    getStub.resolves({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new File(['fake'], 'fake.txt')

    await uploadFile(url, data, file, fakeAjaxLib)
    expect(getStub.calledWith(successUrl)).toBeTruthy()
  })

  test('uploadFile threads through in local-storage case', async () => {
    const preflightResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {
            upload_params: {fakeKey: 'fakeValue'},
            upload_url: 'http://uploadUrl',
          },
        })
      )
    })

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          data: {id: 1},
        })
      )
    })

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.onCall(0).returns(preflightResponse)
    postStub.onCall(1).returns(postResponse)
    getStub.resolves({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const url = `/api/v1/courses/1/files`
    const data = {name: 'fake'}
    const file = new File(['fake'], 'fake.txt')

    const response = await uploadFile(url, data, file, fakeAjaxLib)
    expect(response.id).toBe(1)
  })

  test('completeUpload unpacks embedded "attachments" wrapper if any', () => {
    const upload_url = 'http://uploadUrl'
    const preflightResponse = {
      attachments: [{upload_url}],
    }

    const postStub = sinon.stub()
    postStub.resolves({data: {}})
    const fakeAjaxLib = {post: postStub}

    const file = new File(['fake'], 'fake.txt')

    return completeUpload(preflightResponse, file, {ajaxLib: fakeAjaxLib}).then(() => {
      expect(postStub.calledWith(upload_url, sinon.match.any, sinon.match.any)).toBeTruthy()
    })
  })

  test('completeUpload wires up progress callback if any', () => {
    const postStub = sinon.stub()
    postStub.resolves({data: {}})
    const fakeAjaxLib = {post: postStub}

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new File(['fake'], 'fake.txt')
    const options = {
      ajaxLib: fakeAjaxLib,
      onProgress: sinon.spy(),
    }

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(
        postStub.calledWith(
          sinon.match.any,
          sinon.match.any,
          sinon.match({
            onUploadProgress: options.onProgress,
          })
        )
      ).toBeTruthy()
    })
  })

  test('completeUpload skips GET after inst-fs upload if options.ignoreResult', () => {
    const successUrl = 'http://successUrl'

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          status: 201,
          data: {location: successUrl},
        })
      )
    })

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.returns(postResponse)
    getStub.resolves({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new File(['fake'], 'fake.txt')
    const options = {
      ajaxLib: fakeAjaxLib,
      ignoreResult: true,
    }

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(getStub.calledWith(successUrl)).toBeFalsy()
    })
  })

  test('completeUpload appends avatar include in GET after upload if options.includeAvatar', () => {
    const successUrl = 'http://successUrl'

    const postResponse = new Promise(resolve => {
      setTimeout(() =>
        resolve({
          status: 201,
          data: {location: successUrl},
        })
      )
    })

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.returns(postResponse)
    getStub.resolves({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new File(['fake'], 'fake.txt')
    const options = {
      ajaxLib: fakeAjaxLib,
      includeAvatar: true,
    }

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(getStub.calledWith(`${successUrl}?include=avatar`)).toBeTruthy()
    })
  })

  test('completeUpload to S3 posts withCredentials false', () => {
    const successUrl = 'http://successUrl'

    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.resolves({data: {}})
    getStub.resolves({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {
      upload_url: 'http://uploadUrl',
      success_url: successUrl,
    }
    const file = new File(['fake'], 'fake.txt')
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(
        postStub.calledWith(
          sinon.match.any,
          sinon.match.any,
          sinon.match({
            withCredentials: false,
          })
        )
      ).toBeTruthy()
    })
  })

  test('completeUpload to non-S3 posts withCredentials true', () => {
    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.resolves({data: {}})
    getStub.resolves({data: {}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {upload_url: 'http://uploadUrl'}
    const file = new File(['fake'], 'fake.txt')
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(() => {
      expect(
        postStub.calledWith(
          sinon.match.any,
          sinon.match.any,
          sinon.match({
            withCredentials: true,
          })
        )
      ).toBeTruthy()
    })
  })

  test('completeUpload does not add a null file to the upload POST', () => {
    const postStub = sinon.stub()
    postStub.resolves({data: {}})

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
      expect(
        postStub.calledWith(
          sinon.match.any,
          sinon.match(formData => !formData.has('file')),
          sinon.match.any
        )
      ).toBeTruthy()
    })
  })

  test('completeUpload immediately waits on progress if given a progress and no upload_url', () => {
    const results = {id: 1}
    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.resolves({data: {}})
    getStub.resolves({data: {workflow_state: 'completed', results}})

    const fakeAjaxLib = {
      post: postStub,
      get: getStub,
    }

    const preflightResponse = {progress: {workflow_state: 'queued', url: 'http://progressUrl'}}
    const file = null
    const options = {ajaxLib: fakeAjaxLib}

    return completeUpload(preflightResponse, file, options).then(data => {
      expect(postStub.called).toBeFalsy()
      expect(data).toEqual(results)
    })
  })

  test('completeUpload waits on progress after upload POST if given both a progress and upload URL', () => {
    const results = {id: 1}
    const postStub = sinon.stub()
    const getStub = sinon.stub()
    postStub.resolves({data: {}})
    getStub.resolves({data: {workflow_state: 'completed', results}})

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
      expect(postStub.called).toBeTruthy()
      expect(data).toEqual(results)
    })
  })

  test('uploadFile differentiates network failures during preflight', async () => {
    const fakeAjaxLib = {post: sinon.stub()}
    fakeAjaxLib.post.rejects({message: 'Network Error'}) // preflight attempt
    const file = new File(['fake'], 'fake.txt')
    try {
      await uploadFile('http://preflightUrl', {}, file, fakeAjaxLib)
      expect(false).toBeTruthy() // preflight should fail
    } catch ({message}) {
      expect(message.match(/failed to initiate the upload/)).toBeTruthy()
    }
  })

  test('uploadFile differentiates network failures during POST to upload_url', async () => {
    const fakeAjaxLib = {post: sinon.stub()}
    fakeAjaxLib.post.onCall(0).resolves({data: {upload_url: 'http://uploadUrl'}}) // preflight
    fakeAjaxLib.post.onCall(1).rejects({message: 'Network Error'}) // upload attempt
    const file = new File(['fake'], 'fake.txt')
    try {
      await uploadFile('http://preflightUrl', {}, file, fakeAjaxLib)
      expect(false).toBeTruthy() // upload should fail
    } catch ({message}) {
      expect(message.match(/service may be down/)).toBeTruthy()
    }
  })

  test('uploadFile differentiates network failures after upload', async () => {
    const fakeAjaxLib = {post: sinon.stub(), get: sinon.stub()}
    fakeAjaxLib.post.onCall(0).resolves({
      data: {
        upload_url: 'http://uploadUrl',
        success_url: 'http://successUrl',
      },
    }) // preflight
    fakeAjaxLib.post.onCall(1).resolves({data: {}}) // upload
    fakeAjaxLib.get.rejects({message: 'Network Error'}) // success url attempt
    const file = new File(['fake'], 'fake.txt')
    try {
      await uploadFile('http://preflightUrl', {}, file, fakeAjaxLib)
      expect(false).toBeTruthy() // finalization should fail
    } catch ({message}) {
      expect(message.match(/failed to complete the upload/)).toBeTruthy()
    }
  })
})
