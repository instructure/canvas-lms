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
import K5Uploader from '@instructure/k5uploader'
import moxios from 'moxios'
import sinon from 'sinon'
import saveMediaRecording, {saveClosedCaptions} from '../saveMediaRecording'

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
      partnerData: 'data from our partners'
    }
  }
}

describe('saveMediaRecording', () => {
  beforeEach(() => {
    moxios.install()
  })
  afterEach(() => {
    moxios.uninstall()
  })
  it('fails if request for kaltura session fails', async done => {
    moxios.stubRequest('/api/v1/services/kaltura_session?include_upload_config=1', {
      status: 500,
      response: {error: 'womp womp'}
    })
    const doneFunction = jest.fn()
    sinon.stub(K5Uploader.prototype, 'loadUiConf').callsFake(() => 'mock')
    await saveMediaRecording({}, '1', 'course', doneFunction)
    expect(doneFunction).toHaveBeenCalledTimes(1)
    expect(doneFunction.mock.calls[0][0].message).toBe('Request failed with status code 500')
    done()
  })

  it('returns error if k5.fileError is dispatched', () => {
    moxios.stubRequest('/api/v1/services/kaltura_session?include_upload_config=1', {
      status: 200,
      response: mediaServerSession()
    })
    const doneFunction = jest.fn()
    const progressFunction = jest.fn()
    return saveMediaRecording({}, '1', 'course', doneFunction, progressFunction).then(uploader => {
      uploader.dispatchEvent('K5.fileError', {error: 'womp womp'}, uploader)
      expect(doneFunction).toHaveBeenCalledTimes(1)
      expect(doneFunction.mock.calls[0][0].error).toBe('womp womp')
    })
  })

  it('k5.ready calls uploaders uploadFile with file', () => {
    moxios.stubRequest('/api/v1/services/kaltura_session?include_upload_config=1', {
      status: 200,
      response: mediaServerSession()
    })
    const doneFunction = jest.fn()
    const progressFunction = jest.fn()
    const uploadFileFunc = jest.fn()
    return saveMediaRecording({file: 'thing'}, '1', 'course', doneFunction, progressFunction).then(
      uploader => {
        uploader.uploadFile = uploadFileFunc
        uploader.dispatchEvent('K5.ready', uploader)
        expect(uploadFileFunc).toHaveBeenCalledTimes(1)
        expect(uploadFileFunc.mock.calls[0][0].file).toBe('thing')
      }
    )
  })

  it('k5.progress calls progress function when dispatched', () => {
    moxios.stubRequest('/api/v1/services/kaltura_session?include_upload_config=1', {
      status: 200,
      response: mediaServerSession()
    })
    const doneFunction = jest.fn()
    const progressFunction = jest.fn()
    const uploadFileFunc = jest.fn()
    return saveMediaRecording({file: 'thing'}, '1', 'course', doneFunction, progressFunction).then(
      uploader => {
        uploader.uploadFile = uploadFileFunc
        uploader.dispatchEvent('K5.progress', uploader)
        expect(progressFunction).toHaveBeenCalled()
      }
    )
  })

  it('k5.complete calls done with canvasMediaObject data if succeeds', () => {
    moxios.stubRequest('/api/v1/services/kaltura_session?include_upload_config=1', {
      status: 200,
      response: mediaServerSession()
    })
    moxios.stubRequest('/api/v1/media_objects', {
      status: 200,
      response: {data: 'media object data'}
    })
    const doneFunction2 = jest.fn()
    const progressFunction = jest.fn()
    return saveMediaRecording({file: 'thing'}, '1', 'course', doneFunction2, progressFunction).then(
      async uploader => {
        uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
        await new Promise(setTimeout)
        expect(doneFunction2).toHaveBeenCalledTimes(1)
        expect(doneFunction2.mock.calls[0][1]).toEqual({
          mediaObject: {data: 'media object data'},
          uploadedFile: {file: 'thing'}
        })
        expect(doneFunction2.mock.calls[0][0]).toBe(null)
      }
    )
  })

  it('fails if request to create media object fails', async () => {
    moxios.stubRequest('/api/v1/services/kaltura_session?include_upload_config=1', {
      status: 200,
      response: mediaServerSession()
    })
    moxios.stubRequest('/api/v1/media_objects', {
      status: 500,
      response: {error: 'womp womp'}
    })
    const doneFunction2 = jest.fn()
    const progressFunction = jest.fn()
    return saveMediaRecording({file: 'thing'}, '1', 'course', doneFunction2, progressFunction).then(
      async uploader => {
        uploader.dispatchEvent('K5.complete', {stuff: 'datatatatatatatat'}, uploader)
        await new Promise(setTimeout)
        expect(doneFunction2).toHaveBeenCalledTimes(1)
        expect(doneFunction2.mock.calls[0][0].message).toBe('Request failed with status code 500')
      }
    )
  })
})

describe('saveClosedCaptions', () => {
  beforeEach(() => {
    moxios.install()
  })
  afterEach(() => {
    moxios.uninstall()
  })
  it('returns success promise if axios requests returns correctly', done => {
    const mediaId = '4'
    const fileContents = 'file contents'
    const file = new Blob([fileContents], {type: 'text/plain'})
    const fileAndLanguage = {
      language: {selectedOptionId: 'en'},
      file
    }
    moxios.stubRequest(`/media_objects/${mediaId}/media_tracks`, {
      status: 200,
      response: {data: 'media object data'}
    })
    const successPromise = saveClosedCaptions(mediaId, [fileAndLanguage])
    return successPromise
      .then(() => {
        expect(true).toBe(true)
        done()
      })
      .catch(() => {
        expect(false).toBe(true)
        done()
      })
  })

  it('returns failure promise if axios request fails', done => {
    const mediaId = '4'
    const fileContents = 'file contents'
    const file = new Blob([fileContents], {type: 'text/plain'})
    const fileAndLanguage = {
      language: {selectedOptionId: 'en'},
      file
    }
    moxios.stubRequest(`/media_objects/${mediaId}/media_tracks`, {
      status: 500,
      response: {data: 'media object data'}
    })
    const successPromise = saveClosedCaptions(mediaId, [fileAndLanguage])
    return successPromise
      .then(() => {
        expect(false).toBe(true)
        done()
      })
      .catch(() => {
        expect(true).toBe(true)
        done()
      })
  })
})
