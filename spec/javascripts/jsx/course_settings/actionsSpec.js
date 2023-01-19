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

import Actions from 'ui/features/course_settings/react/actions'

QUnit.module('Course Settings Actions')

test('calling setModalVisibility produces the proper object', () => {
  let actual = Actions.setModalVisibility(true)
  let expected = {
    type: 'MODAL_VISIBILITY',
    payload: {
      showModal: true,
    },
  }

  deepEqual(actual, expected, 'the objects match')

  actual = Actions.setModalVisibility(false)
  expected = {
    type: 'MODAL_VISIBILITY',
    payload: {
      showModal: false,
    },
  }

  deepEqual(actual, expected)
})

test('calling gotCourseImage produces the proper object', () => {
  const actual = Actions.gotCourseImage('http://imageUrl')
  const expected = {
    type: 'GOT_COURSE_IMAGE',
    payload: {
      imageUrl: 'http://imageUrl',
    },
  }

  deepEqual(actual, expected, 'the objects match')
})

test('getCourseImage', assert => {
  const done = assert.async()
  const fakeResponse = {
    data: {
      image: 'http://imageUrl',
    },
  }

  const fakeAjaxLib = {
    get(url) {
      return new Promise(resolve => {
        setTimeout(() => resolve(fakeResponse), 100)
      })
    },
  }

  const expectedAction = {
    type: 'GOT_COURSE_IMAGE',
    payload: {
      imageUrl: 'http://imageUrl',
    },
  }

  Actions.getCourseImage(
    1,
    'image',
    fakeAjaxLib
  )(dispatched => {
    deepEqual(dispatched, expectedAction, 'the proper action was dispatched')
    done()
  })
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

  deepEqual(actual, expected, 'the objects match')
})

test('prepareSetImage with a imageUrl calls putImageData', () => {
  sinon.spy(Actions, 'putImageData')
  Actions.prepareSetImage('http://imageUrl', 12, 0)
  ok(Actions.putImageData.called, 'putImageData was called')
  Actions.putImageData.restore()
})

test('prepareSetImage without a imageUrl calls the API to get the url', assert => {
  const done = assert.async()
  const fakeResponse = {
    data: {
      url: 'http://imageUrl',
    },
  }

  const fakeAjaxLib = {
    get(url) {
      return new Promise(resolve => {
        setTimeout(() => resolve(fakeResponse), 100)
      })
    },
  }

  sinon.spy(Actions, 'putImageData')

  Actions.prepareSetImage(
    null,
    1,
    'image',
    0,
    fakeAjaxLib
  )(dispatched => {
    ok(
      Actions.putImageData.called,
      'image',
      'putImageData was called indicating successfully hit API'
    )
    Actions.putImageData.restore()
    done()
  })
})

test('uploadFile returns false when image is not valid', assert => {
  const done = assert.async()
  const fakeDragonDropEvent = {
    dataTransfer: {
      files: [
        {
          name: 'test file',
          size: 12345,
          type: 'image/tiff',
        },
      ],
    },
    preventDefault: () => {},
  }

  const expectedAction = {
    type: 'REJECTED_UPLOAD',
    payload: {
      rejectedFiletype: 'image/tiff',
    },
  }

  Actions.uploadFile(
    fakeDragonDropEvent,
    1,
    'image'
  )(dispatched => {
    deepEqual(dispatched, expectedAction, 'the REJECTED_UPLOAD action was fired')
    done()
  })
})

test('uploadFile dispatches UPLOADING_IMAGE when file type is valid', assert => {
  const done = assert.async()
  const fakeDragonDropEvent = {
    dataTransfer: {
      files: [
        {
          name: 'test file',
          size: 12345,
          type: 'image/jpeg',
        },
      ],
    },
    preventDefault: () => {},
  }

  const expectedAction = {
    type: 'UPLOADING_IMAGE',
  }

  Actions.uploadFile(
    fakeDragonDropEvent,
    1,
    'image'
  )(dispatched => {
    if (dispatched.type === 'UPLOADING_IMAGE') {
      deepEqual(dispatched, expectedAction, 'the UPLOADING_IMAGE action was fired')
      done()
    }
  })
})

test('uploadFile dispatches prepareSetImage when successful', assert => {
  const done = assert.async()
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

  const successResponse = new Promise(resolve => {
    setTimeout(() =>
      resolve({
        data: {
          url: 'http://fileDownloadUrl',
          id: 1,
        },
      })
    )
  })

  const postStub = sinon.stub()
  const getStub = sinon.stub()
  postStub.onCall(0).returns(preflightResponse)
  postStub.onCall(1).returns(Promise.resolve({data: {}}))
  getStub.returns(successResponse)

  const fakeAjaxLib = {
    post: postStub,
    get: getStub,
  }

  const fakeDragonDropEvent = {
    dataTransfer: {
      files: [
        new File(['fake'], 'fake.jpg', {
          name: 'test file',
          size: 12345,
          type: 'image/jpeg',
        }),
      ],
    },
    preventDefault: () => {},
  }

  sinon.spy(Actions, 'prepareSetImage')

  Actions.uploadFile(
    fakeDragonDropEvent,
    1,
    'image',
    fakeAjaxLib
  )(dispatched => {
    if (dispatched.type !== 'UPLOADING_IMAGE') {
      ok(getStub.calledWith(successUrl), 'made request to success url')
      ok(Actions.prepareSetImage.called, 'prepareSetImage was called')
      Actions.prepareSetImage.restore()
      done()
    }
  })
})
