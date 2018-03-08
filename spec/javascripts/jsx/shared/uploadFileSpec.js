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

import {uploadFile, completeUpload} from 'jsx/shared/upload_file'

QUnit.module('Upload File')

test('uploadFile posts form data instead of json if necessary', assert => {
  const done = assert.async()
  const preflightResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        data: {
          upload_url: 'http://uploadUrl'
        }
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.onCall(0).returns(preflightResponse)
  postStub.onCall(1).returns(Promise.resolve({data: {}}))
  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const url = `/api/v1/courses/1/files`
  const data = {
    name: 'fake',
    'attachment[context_code]': 'course_1'
  }
  const file = sinon.stub()

  uploadFile(url, data, file, fakeAjaxLib)
    .then(() => {
      ok(
        postStub.calledWith(
          url,
          'name=fake&attachment%5Bcontext_code%5D=course_1&no_redirect=true'
        ),
        'posted url encoded form data'
      )
      done()
    })
    .catch(done)
})

test('uploadFile requests no_redirect in preflight even if not specified', assert => {
  const done = assert.async()
  const preflightResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        data: {
          upload_url: 'http://uploadUrl'
        }
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.onCall(0).returns(preflightResponse)
  postStub.onCall(1).returns(Promise.resolve({data: {}}))
  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const url = `/api/v1/courses/1/files`
  const data = {name: 'fake'}
  const file = sinon.stub()

  uploadFile(url, data, file, fakeAjaxLib)
    .then(() => {
      ok(
        postStub.calledWith(url, {name: 'fake', no_redirect: true}),
        'posted with no_redirect: true'
      )
      done()
    })
    .catch(done)
})

test('uploadFile threads through in direct to S3 case', assert => {
  const done = assert.async()
  const successUrl = 'http://successUrl'
  const preflightResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        data: {
          upload_params: {fakeKey: 'fakeValue', success_url: successUrl},
          upload_url: 'http://uploadUrl'
        }
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.onCall(0).returns(preflightResponse)
  postStub.onCall(1).returns(Promise.resolve({data: {}}))
  getStub.returns(Promise.resolve({data: {}}))

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const url = `/api/v1/courses/1/files`
  const data = {name: 'fake'}
  const file = sinon.stub()

  uploadFile(url, data, file, fakeAjaxLib)
    .then(() => {
      ok(getStub.calledWith(successUrl), 'made request to success url')
      done()
    })
    .catch(done)
})

test('uploadFile threads through in inst-fs case', assert => {
  const done = assert.async()
  const successUrl = 'http://successUrl'
  const preflightResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        data: {
          upload_params: {fakeKey: 'fakeValue'},
          upload_url: 'http://uploadUrl'
        }
      })
    )
  })

  const postResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        status: 201,
        data: {location: successUrl}
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.onCall(0).returns(preflightResponse)
  postStub.onCall(1).returns(postResponse)
  getStub.returns(Promise.resolve({data: {}}))

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const url = `/api/v1/courses/1/files`
  const data = {name: 'fake'}
  const file = sinon.stub()

  uploadFile(url, data, file, fakeAjaxLib)
    .then(() => {
      ok(getStub.calledWith(successUrl), 'made request to success url')
      done()
    })
    .catch(done)
})

test('uploadFile threads through in local-storage case', assert => {
  const done = assert.async()
  const preflightResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        data: {
          upload_params: {fakeKey: 'fakeValue'},
          upload_url: 'http://uploadUrl'
        }
      })
    )
  })

  const postResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        data: {id: 1}
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.onCall(0).returns(preflightResponse)
  postStub.onCall(1).returns(postResponse)
  getStub.returns(Promise.resolve({data: {}}))

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const url = `/api/v1/courses/1/files`
  const data = {name: 'fake'}
  const file = sinon.stub()

  uploadFile(url, data, file, fakeAjaxLib)
    .then(response => {
      equal(response.id, 1, 'passed response through')
      done()
    })
    .catch(done)
})

test('completeUpload upacks embedded "attachments" wrapper if any', assert => {
  const done = assert.async()
  const upload_url = 'http://uploadUrl'
  const preflightResponse = {
    attachments: [{upload_url}]
  }

  const postStub = sinon.stub()
  postStub.returns(Promise.resolve({data: {}}))
  const fakeAjaxLib = {post: postStub}

  const file = sinon.stub()

  completeUpload(preflightResponse, file, {ajaxLib: fakeAjaxLib})
    .then(() => {
      ok(
        postStub.calledWith(upload_url, sinon.match.any, sinon.match.any),
        'posted correct upload_url'
      )
      done()
    })
    .catch(done)
})

test('completeUpload wires up progress callback if any', assert => {
  const done = assert.async()

  const postStub = sinon.stub()
  postStub.returns(Promise.resolve({data: {}}))
  const fakeAjaxLib = {post: postStub}

  const preflightResponse = {upload_url: 'http://uploadUrl'}
  const file = sinon.stub()
  const options = {
    ajaxLib: fakeAjaxLib,
    onProgress: sinon.spy()
  }

  completeUpload(preflightResponse, file, options)
    .then(() => {
      ok(
        postStub.calledWith(
          sinon.match.any,
          sinon.match.any,
          sinon.match({
            onUploadProgress: options.onProgress
          })
        ),
        'posted correct config'
      )
      done()
    })
    .catch(done)
})

test('completeUpload skips GET after inst-fs upload if options.ignoreResult', assert => {
  const done = assert.async()
  const successUrl = 'http://successUrl'

  const postResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        status: 201,
        data: {location: successUrl}
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.returns(postResponse)
  getStub.returns(Promise.resolve({data: {}}))

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const preflightResponse = {upload_url: 'http://uploadUrl'}
  const file = sinon.stub()
  const options = {
    ajaxLib: fakeAjaxLib,
    ignoreResult: true
  }

  completeUpload(preflightResponse, file, options)
    .then(() => {
      ok(getStub.neverCalledWith(successUrl), 'skipped request to success url')
      done()
    })
    .catch(done)
})

test('completeUpload appends avatar include in GET after inst-fs upload if options.includeAvatar', assert => {
  const done = assert.async()
  const successUrl = 'http://successUrl'

  const postResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        status: 201,
        data: {location: successUrl}
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.returns(postResponse)
  getStub.returns(Promise.resolve({data: {}}))

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const preflightResponse = {upload_url: 'http://uploadUrl'}
  const file = sinon.stub()
  const options = {
    ajaxLib: fakeAjaxLib,
    includeAvatar: true
  }

  completeUpload(preflightResponse, file, options)
    .then(() => {
      ok(getStub.calledWith(`${successUrl}?include=avatar`), 'skipped request to success url')
      done()
    })
    .catch(done)
})

test('completeUpload to S3 posts withCredentials false', assert => {
  const done = assert.async()
  const successUrl = 'http://successUrl'

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.returns(Promise.resolve({data: {}}))
  getStub.returns(Promise.resolve({data: {}}))

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const preflightResponse = {
    upload_url: 'http://uploadUrl',
    success_url: successUrl
  }
  const file = sinon.stub()
  const options = {ajaxLib: fakeAjaxLib}

  completeUpload(preflightResponse, file, options)
    .then(() => {
      ok(
        postStub.calledWith(
          sinon.match.any,
          sinon.match.any,
          sinon.match({
            withCredentials: false
          })
        ),
        'withCredentials is false'
      )
      done()
    })
    .catch(done)
})

test('completeUpload to non-S3 posts withCredentials true', assert => {
  const done = assert.async()

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.returns(Promise.resolve({data: {}}))
  getStub.returns(Promise.resolve({data: {}}))

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  }

  const preflightResponse = {upload_url: 'http://uploadUrl'}
  const file = sinon.stub()
  const options = {ajaxLib: fakeAjaxLib}

  completeUpload(preflightResponse, file, options)
    .then(() => {
      ok(
        postStub.calledWith(
          sinon.match.any,
          sinon.match.any,
          sinon.match({
            withCredentials: true
          })
        ),
        'withCredentials is true'
      )
      done()
    })
    .catch(done)
})
