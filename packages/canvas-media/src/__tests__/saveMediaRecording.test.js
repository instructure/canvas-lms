/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import sinon from 'sinon'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import saveMediaRecording, {
  saveClosedCaptions,
  saveClosedCaptionsForAttachment,
} from '../saveMediaRecording'
import {vi} from 'vitest'

// Mock K5Uploader
vi.mock('@instructure/k5uploader', () => {
  const eventListeners = new WeakMap()

  class MockK5Uploader {
    constructor() {
      eventListeners.set(this, {})
    }

    addEventListener(event, handler) {
      const listeners = eventListeners.get(this)
      listeners[event] = handler
    }

    dispatchEvent(event, data) {
      const listeners = eventListeners.get(this)
      if (listeners[event]) {
        listeners[event](data)
      }
    }

    uploadFile = vi.fn()
    destroy = vi.fn()
    loadUiConf = vi.fn(() => 'mock')
  }

  return {K5Uploader: MockK5Uploader}
})

function mediaServerSession() {
  return {
    ks: 'averylongstring',
    subp_id: '0',
    partner_id: '9',
    uid: '1234_567',
    serverTime: 1234,
    kaltura_setting: {
      uploadUrl: 'url.url.url',
      entryUrl: 'url.url.url',
      uiconfUrl: 'url.url.url',
      partnerData: 'data from our partners',
      partner_data: 'data from our partners',
    },
  }
}

const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
afterEach(() => {
  server.resetHandlers()
  sinon.restore()
})
afterAll(() => server.close())

describe('saveMediaRecording', () => {
  let rcsConfig

  beforeEach(() => {
    rcsConfig = {
      contentId: '1',
      contentType: 'course',
      contextId: '1',
      contextType: 'course',
      origin: 'http://localhost:3000',
      headers: {Authorization: 'Bearer doesnotmatter'},
    }
  })

  it('fails if request for kaltura session fails', async () => {
    server.use(
      http.post(
        '**/api/v1/services/kaltura_session*',
        () => new HttpResponse(JSON.stringify({error: 'womp womp'}), {status: 500}),
      ),
    )
    const doneFunction = vi.fn()
    await saveMediaRecording({}, rcsConfig, doneFunction)
    expect(doneFunction).toHaveBeenCalledTimes(1)
    expect(doneFunction.mock.calls[0][0].message).toBe('Request failed with status code 500')
  })

  it('returns error if k5.fileError is dispatched', () => {
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
    )
    const doneFunction = vi.fn()
    const progressFunction = vi.fn()

    return saveMediaRecording({}, rcsConfig, doneFunction, progressFunction).then(uploader => {
      uploader.dispatchEvent('K5.fileError', {error: 'womp womp'}, uploader)
      expect(doneFunction).toHaveBeenCalledTimes(1)
      expect(doneFunction.mock.calls[0][0].error).toBe('womp womp')
    })
  })

  it('k5.ready calls uploaders uploadFile with file', () => {
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
    )
    const doneFunction = vi.fn()
    const progressFunction = vi.fn()
    const uploadFileFunc = vi.fn()
    return saveMediaRecording({file: 'thing'}, rcsConfig, doneFunction, progressFunction).then(
      uploader => {
        uploader.uploadFile = uploadFileFunc
        uploader.dispatchEvent('K5.ready', uploader)
        expect(uploadFileFunc).toHaveBeenCalledTimes(1)
        expect(uploadFileFunc.mock.calls[0][0].file).toBe('thing')
      },
    )
  })

  it('k5.progress calls progress function when dispatched', () => {
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
    )
    const doneFunction = vi.fn()
    const progressFunction = vi.fn()
    const uploadFileFunc = vi.fn()
    return saveMediaRecording({file: 'thing'}, rcsConfig, doneFunction, progressFunction).then(
      uploader => {
        uploader.uploadFile = uploadFileFunc
        uploader.dispatchEvent('K5.progress', uploader)
        expect(progressFunction).toHaveBeenCalled()
      },
    )
  })

  it('uploads with the user entered title, if one is provided', () => {
    let capturedRequest
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
      http.post('**/api/media_objects', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({data: 'media object data'})
      }),
    )

    return saveMediaRecording(
      {name: 'hi', userEnteredTitle: 'my awesome video'},
      rcsConfig,
      () => {},
      () => {},
    ).then(async uploader => {
      uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
      await new Promise(setTimeout)
      expect(capturedRequest.user_entered_title).toEqual('my awesome video')
    })
  })

  it('uploads with the file name if no user entered title is provided', () => {
    let capturedRequest
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
      http.post('**/api/media_objects', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({data: 'media object data'})
      }),
    )

    return saveMediaRecording(
      {name: 'hi'},
      rcsConfig,
      () => {},
      () => {},
    ).then(async uploader => {
      uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
      await new Promise(setTimeout)
      expect(capturedRequest.user_entered_title).toEqual('hi')
    })
  })

  it('uploads with the content type from the file', () => {
    let capturedRequest
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
      http.post('**/api/media_objects', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({data: 'media object data'})
      }),
    )
    const doneFunction2 = vi.fn()
    const progressFunction = vi.fn()
    return saveMediaRecording(
      {file: 'thing', type: 'video/mp4'},
      rcsConfig,
      doneFunction2,
      progressFunction,
    ).then(async uploader => {
      uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
      await new Promise(setTimeout)
      expect(capturedRequest.type).toEqual('video/mp4')
    })
  })

  it('k5.complete calls done with canvasMediaObject data if succeeds', () => {
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
      http.post('**/api/media_objects', () => HttpResponse.json({data: 'media object data'})),
    )
    const doneFunction2 = vi.fn()
    const progressFunction = vi.fn()
    return saveMediaRecording({file: 'thing'}, rcsConfig, doneFunction2, progressFunction).then(
      async uploader => {
        uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
        await new Promise(setTimeout)
        expect(doneFunction2).toHaveBeenCalledTimes(1)
        expect(doneFunction2.mock.calls[0][1]).toEqual({
          mediaObject: {data: 'media object data'},
          uploadedFile: {file: 'thing'},
        })
        expect(doneFunction2.mock.calls[0][0]).toBe(null)
      },
    )
  })

  it('fails if request to create media object fails', async () => {
    server.use(
      http.post('**/api/v1/services/kaltura_session*', () =>
        HttpResponse.json(mediaServerSession()),
      ),
      http.post('**/api/media_objects', () =>
        HttpResponse.json({error: 'womp womp'}, {status: 500}),
      ),
    )
    const doneFunction2 = vi.fn()
    const progressFunction = vi.fn()
    return saveMediaRecording({file: 'thing'}, rcsConfig, doneFunction2, progressFunction).then(
      async uploader => {
        uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
        await new Promise(setTimeout)
        expect(doneFunction2).toHaveBeenCalledTimes(1)
        expect(doneFunction2.mock.calls[0][0].message).toBe('Request failed with status code 500')
      },
    )
  })

  it('calls canvas api if rcsConfig.origin is not provided', async () => {
    delete rcsConfig.origin
    delete rcsConfig.headers

    server.use(
      http.post('/api/v1/services/kaltura_session*', () => HttpResponse.json(mediaServerSession())),
      http.post('/api/v1/media_objects', () =>
        HttpResponse.json({error: 'womp womp'}, {status: 500}),
      ),
    )
    const doneFunction2 = vi.fn()
    const progressFunction = vi.fn()
    return saveMediaRecording({file: 'thing'}, rcsConfig, doneFunction2, progressFunction).then(
      async uploader => {
        uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
        await new Promise(setTimeout)
        expect(doneFunction2).toHaveBeenCalledTimes(1)
        expect(doneFunction2.mock.calls[0][0].message).toBe('Request failed with status code 500')
      },
    )
  })
})

describe('saveClosedCaptions', () => {
  let rcsConfig

  beforeEach(() => {
    rcsConfig = {
      origin: 'http://localhost:3000',
      headers: {Authorization: 'Bearer doesnotmatter'},
      method: 'PUT',
    }
  })
  it('returns success promise if axios requests returns correctly', () => {
    const mediaId = '4'
    const fileContents = 'file contents'
    const file = new Blob([fileContents], {type: 'text/plain'})
    const fileAndLanguage = {
      language: {selectedOptionId: 'en'},
      file,
    }
    server.use(
      http.put('**/api/media_objects/*/media_tracks', () =>
        HttpResponse.json({data: 'media object data'}),
      ),
    )
    const successPromise = saveClosedCaptions(mediaId, [fileAndLanguage], rcsConfig)
    return expect(successPromise).resolves.toMatchObject({data: {data: 'media object data'}})
  })

  it('returns failure promise if axios request fails', () => {
    const mediaId = '4'
    const fileContents = 'file contents'
    const file = new Blob([fileContents], {type: 'text/plain'})
    const fileAndLanguage = {
      language: {selectedOptionId: 'en'},
      file,
    }
    server.use(
      http.put('**/api/media_objects/*/media_tracks', () =>
        HttpResponse.json({data: 'media object data'}, {status: 500}),
      ),
    )
    const successPromise = saveClosedCaptions(mediaId, [fileAndLanguage], rcsConfig)
    return expect(successPromise).rejects.toMatchObject({response: {status: 500}})
  })

  describe('when the CC file size is too large', () => {
    let mediaId, fileAndLanguage

    const subject = () => saveClosedCaptions(mediaId, [fileAndLanguage], rcsConfig, 1)

    beforeEach(() => {
      mediaId = '4'
      fileAndLanguage = {
        language: {selectedOptionId: 'en'},
        file: new Blob(['file contents'], {type: 'text/plain'}),
        isNew: true,
      }
    })

    it('rejects with a "file size" error', async () => {
      await subject()
        .then(() => {})
        .catch(e => expect(e.name).toEqual('FileSizeError'))
    })
  })

  it('calls canvas api if rcsConfig.origin is not provided', () => {
    delete rcsConfig.origin
    delete rcsConfig.headers
    const mediaId = '4'
    const fileContents = 'file contents'
    const file = new Blob([fileContents], {type: 'text/plain'})
    const fileAndLanguage = {
      language: {selectedOptionId: 'en'},
      file,
    }
    server.use(
      http.put('/api/v1/media_objects/*/media_tracks', () =>
        HttpResponse.json({data: 'media object data'}),
      ),
    )
    const successPromise = saveClosedCaptions(mediaId, [fileAndLanguage], rcsConfig)
    return expect(successPromise).resolves.toMatchObject({data: {data: 'media object data'}})
  })
})

describe('saveClosedCaptionsForAttachment', () => {
  let rcsConfig, attachmentId, fileAndLanguage

  beforeEach(() => {
    rcsConfig = {
      origin: 'http://localhost:3000',
      headers: {Authorization: 'Bearer doesnotmatter'},
      method: 'PUT',
    }
    attachmentId = 4
    const fileContents = 'file contents'
    const file = new Blob([fileContents], {type: 'text/plain'})
    fileAndLanguage = {
      language: {selectedOptionId: 'en'},
      file,
    }
  })

  it('returns success promise if axios requests returns correctly', () => {
    server.use(
      http.put('**/api/media_attachments/*/media_tracks', () =>
        HttpResponse.json({data: 'media object data'}),
      ),
    )
    const successPromise = saveClosedCaptionsForAttachment(
      attachmentId,
      [fileAndLanguage],
      rcsConfig,
    )
    return expect(successPromise).resolves.toMatchObject({data: {data: 'media object data'}})
  })

  it('returns failure promise if axios request fails', () => {
    server.use(
      http.put(
        '**/api/media_attachments/*/media_tracks',
        () => new HttpResponse(null, {status: 500}),
      ),
    )
    const successPromise = saveClosedCaptionsForAttachment(
      attachmentId,
      [fileAndLanguage],
      rcsConfig,
    )
    return expect(successPromise).rejects.toMatchObject({response: {status: 500}})
  })

  it('when the CC file size is too large rejects with a "file size" error', async () => {
    fileAndLanguage.isNew = true
    await saveClosedCaptionsForAttachment(attachmentId, [fileAndLanguage], rcsConfig, 1).catch(e =>
      expect(e.name).toEqual('FileSizeError'),
    )
  })

  it('calls canvas api if rcsConfig.origin is not provided', () => {
    delete rcsConfig.origin
    delete rcsConfig.headers
    server.use(
      http.put('/api/v1/media_attachments/*/media_tracks', () =>
        HttpResponse.json({data: 'media attachment data'}),
      ),
    )
    const successPromise = saveClosedCaptionsForAttachment(
      attachmentId,
      [fileAndLanguage],
      rcsConfig,
    )
    return expect(successPromise).resolves.toMatchObject({data: {data: 'media attachment data'}})
  })
})
