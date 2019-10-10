/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import assert from 'assert'
import sinon from 'sinon'
import K5Uploader from '@instructure/k5uploader'
import * as actions from '../../../src/sidebar/actions/upload'
import * as filesActions from '../../../src/sidebar/actions/files'
import * as imagesActions from '../../../src/sidebar/actions/images'
import {spiedStore} from './utils'
import Bridge from '../../../src/bridge'

const fakeFileReader = {
  readAsDataURL() {
    this.onload()
  },
  result: 'fakeDataURL'
}

describe('Upload data actions', () => {
  const results = {id: 47}
  const file = {url: 'fileurl', thumbnail_url: 'thumbnailurl'}
  const successSource = {
    fetchFolders() {
      return Promise.resolve({
        folders: [{id: 1, name: 'course files', parentId: null}]
      })
    },

    mediaServerSession() {
      return Promise.resolve({
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
      })
    },

    uploadMediaToCanvas() {
      return Promise.resolve({media_object: {media_id: 2}})
    },

    preflightUpload() {
      return Promise.resolve(results)
    },

    uploadFRD: sinon.stub(),

    setUsageRights: sinon.spy(),

    getFile: sinon.stub().returns(Promise.resolve(file)),
    fetchMediaFolder: sinon.stub().returns(Promise.resolve({folders: [{id: 24}]}))
  }

  beforeEach(() => {
    successSource.uploadFRD.resetHistory()
    successSource.uploadFRD.returns(Promise.resolve(results))
    successSource.setUsageRights.resetHistory()
  })

  const defaults = {
    jwt: 'theJWT',
    source: successSource
  }

  function setupState(props) {
    const {jwt, source} = {...defaults, ...props}
    return {jwt, source}
  }

  describe('fetchFolders', () => {
    it('fetches if there are no folders loaded yet', () => {
      const baseState = setupState()
      baseState.upload = {folders: []}
      const store = spiedStore(baseState)
      return store.dispatch(actions.fetchFolders()).then(() => {
        assert.ok(
          store.spy.calledWith({
            type: actions.RECEIVE_FOLDER,
            id: 1,
            name: 'course files',
            parentId: null
          })
        )
      })
    })

    it('skips the fetch if there are folders already', () => {
      const baseState = setupState()
      baseState.upload = {folders: [{id: 1, name: 'course files'}]}
      const store = spiedStore(baseState)
      store.dispatch(actions.fetchFolders())
      assert.ok(
        store.spy.neverCalledWith({
          type: actions.RECEIVE_FOLDER,
          id: 1,
          name: 'course files',
          parentId: null
        })
      )
    })

    it('fetches the next page if a bookmark is passed', () => {
      const bookmarkSource = {
        fetchFolders(s, bm) {
          if (bm) {
            return Promise.resolve({
              folders: [{id: 2, name: 'blah', parentId: 1}]
            })
          } else {
            return Promise.resolve({
              folders: [{id: 1, name: 'course files', parentId: null}],
              bookmark: 'bm'
            })
          }
        }
      }

      const baseState = {
        source: bookmarkSource,
        jwt: 'theJWT',
        upload: {folders: []}
      }
      const store = spiedStore(baseState)
      return store.dispatch(actions.fetchFolders()).then(() => {
        assert.ok(
          store.spy.calledWith({
            type: actions.RECEIVE_FOLDER,
            id: 1,
            name: 'course files',
            parentId: null
          })
        )
        assert.ok(
          store.spy.calledWith({
            type: actions.RECEIVE_FOLDER,
            id: 2,
            name: 'blah',
            parentId: 1
          })
        )
      })
    })

    it('dispatches a batch action', () => {
      const baseState = setupState()
      baseState.upload = {folders: []}
      const store = spiedStore(baseState)
      return store.dispatch(actions.fetchFolders()).then(() => {
        // folder is empty because we didn't actually process the action
        assert.ok(
          store.spy.calledWith({
            type: actions.PROCESSED_FOLDER_BATCH,
            folders: []
          })
        )
      })
    })
  })

  describe('setUsageRights', () => {
    it('make request to set usage rights if file has usage rights', () => {
      const file = {usageRights: {usageRight: 'foo'}}
      actions.setUsageRights(successSource, file, results)
      sinon.assert.calledWith(successSource.setUsageRights, results.id, file.usageRights)
    })

    it('does not make request if file has no usage rights', () => {
      const file = {}
      actions.setUsageRights(successSource, file, results)
      sinon.assert.notCalled(successSource.setUsageRights)
    })
  })

  describe('uploadToMediaFolder', () => {
    const fakeFileMetaData = {
      parentFolderId: 'media',
      name: 'foo.png',
      size: 3000,
      contentType: 'image/png',
      domObject: {
        name: 'foo.png',
        size: 3000,
        type: 'image/png'
      }
    }
    it('dispatches a uploadPreflight with the proper parentFolderId set', () => {
      const baseState = setupState()
      const store = spiedStore(baseState)
      return store.dispatch(actions.uploadToMediaFolder('images', fakeFileMetaData)).then(() => {
        assert.ok(
          store.spy.calledWith({
            type: actions.START_FILE_UPLOAD,
            file: {
              parentFolderId: 24,
              name: 'foo.png',
              size: 3000,
              contentType: 'image/png',
              domObject: {
                name: 'foo.png',
                size: 3000,
                type: 'image/png'
              }
            }
          })
        )
      })
    })

    it('results in a START_MEDIA_UPLOADING action being fired', () => {
      const baseState = setupState()
      const store = spiedStore(baseState)
      return store.dispatch(actions.uploadToMediaFolder('images', fakeFileMetaData)).then(() => {
        sinon.assert.calledWith(store.spy, {
          type: 'START_MEDIA_UPLOADING',
          payload: fakeFileMetaData
        })
      })
    })
  })

  describe('generateThumbnailUrl', () => {
    it('returns the results if the file is not an image', () => {
      const results = {'content-type': 'application/pdf'}
      return actions.generateThumbnailUrl(results).then(returnResults => {
        assert.deepEqual(results, returnResults)
      })
    })

    it('sets a data url for the thumbnail', () => {
      const results = {
        'content-type': 'image/jpeg'
      }

      const fakeFileDOMObject = {}

      return actions
        .generateThumbnailUrl(results, fakeFileDOMObject, fakeFileReader)
        .then(returnResults => {
          assert.deepEqual(returnResults, {
            'content-type': 'image/jpeg',
            thumbnail_url: 'fakeDataURL'
          })
        })
    })
  })

  describe('uploadPreflight', () => {
    let store, props

    function getBaseState() {
      const baseState = setupState()
      return {
        ...baseState,
        contextId: 42,
        contextType: 'course',
        ui: {
          selectedTabIndex: 2
        }
      }
    }

    beforeEach(() => {
      Bridge.focusEditor(null)
      const baseState = getBaseState()
      store = spiedStore(baseState)
      props = {}
    })

    afterEach(() => {
      if (Bridge.insertImage.restore) {
        Bridge.insertImage.restore()
      }
      if (Bridge.insertLink.restore) {
        Bridge.insertLink.restore()
      }
    })

    it('follows chain preflight -> upload -> complete', () => {
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        assert.ok(store.spy.calledWith({type: actions.START_FILE_UPLOAD, file: {}}))
        assert.ok(
          store.spy.calledWith({
            type: actions.COMPLETE_FILE_UPLOAD,
            results
          })
        )
        assert.ok(store.spy.calledWithMatch({type: filesActions.INSERT_FILE}))
      })
    })

    it('sets usage rights', () => {
      props.usageRights = {}
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        sinon.assert.calledWith(successSource.setUsageRights, results.id, props.usageRights)
      })
    })

    it('dispatches ADD_FILE with correct payload', () => {
      props.contentType = 'image/png'
      successSource.uploadFRD.returns(
        Promise.resolve({
          id: 47,
          display_name: 'foo',
          preview_url: 'http://someurl'
        })
      )
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        sinon.assert.calledWithMatch(store.spy, {
          type: filesActions.ADD_FILE,
          id: 47,
          name: 'foo',
          url: 'http://someurl',
          fileType: 'image/png'
        })
      })
    })

    it('dispatches INSERT_FILE with folder and file ids', () => {
      props.parentFolderId = 74
      successSource.uploadFRD.returns(Promise.resolve({id: 47}))
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        sinon.assert.calledWithMatch(store.spy, {
          type: filesActions.INSERT_FILE,
          id: 74,
          fileId: 47
        })
      })
    })

    it('dispatches ADD_IMAGE if content type is image/*', () => {
      props.fileReader = fakeFileReader
      successSource.uploadFRD.returns(
        Promise.resolve({
          'content-type': 'image/png',
          thumbnail_url: 'thumbnailurl'
        })
      )
      return store.dispatch(actions.uploadPreflight('images', props)).then(() => {
        assert.ok(store.spy.calledWithMatch({type: imagesActions.ADD_IMAGE}))
      })
    })

    it('does not dispatch ADD_IMAGE if content type is not image/*', () => {
      props.contentType = 'text/plain'
      return store.dispatch(actions.uploadPreflight('images', props)).then(() => {
        assert.ok(store.spy.neverCalledWithMatch({type: imagesActions.INSERT_IMAGE}))
      })
    })

    it('inserts the image content through the bridge', () => {
      props.fileReader = fakeFileReader
      const bridgeSpy = sinon.spy(Bridge, 'insertImage')
      successSource.uploadFRD.returns(
        Promise.resolve({
          'content-type': 'image/jpeg',
          thumbnail_url: 'thumbnailurl'
        })
      )
      return store.dispatch(actions.uploadPreflight('images', props)).then(() => {
        assert.ok(bridgeSpy.called)
      })
    })

    it('inserts the file content through the bridge', () => {
      props.fileReader = fakeFileReader
      const bridgeSpy = sinon.spy(Bridge, 'insertLink')
      const state = getBaseState()
      state.ui.selectedTabIndex = 1
      store = spiedStore(state)
      successSource.uploadFRD.returns(
        Promise.resolve({
          'content-type': 'image/jpeg',
          thumbnail_url: 'thumbnailurl'
        })
      )
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        assert.ok(bridgeSpy.called)
      })
    })
  })

  describe('allUploadCompleteActions', () => {
    it('returns a list of actions', () => {
      const fileMetaProps = {
        pranetFolderId: 12
      }
      const results = {}
      const actionSet = actions.allUploadCompleteActions(results, fileMetaProps)
      assert.equal(actionSet.length, 3)
    })
  })

  describe('embedUploadResult', () => {
    beforeEach(() => {
      sinon.stub(Bridge, 'insertLink')
      sinon.stub(Bridge, 'insertImage')
    })

    afterEach(() => {
      Bridge.insertLink.restore()
      Bridge.insertImage.restore()
    })

    describe('link embed', () => {
      it('inserts link with display_name as title', () => {
        const expected = 'foo'
        actions.embedUploadResult({display_name: expected})
        sinon.assert.calledWithMatch(Bridge.insertLink, {title: expected}, false)
      })

      it('inserts link with url as href', () => {
        const expected = 'http://github.com'
        actions.embedUploadResult({url: expected})
        sinon.assert.calledWithMatch(Bridge.insertLink, {href: expected}, false)
      })

      it('inserts link with data-canvas-previewable if the content-type is previewable by canvas', () => {
        const uploadResult = {
          display_name: 'display_name',
          url: 'http://somewhere',
          'content-type': 'application/pdf'
        }
        actions.embedUploadResult(uploadResult)
        sinon.assert.calledWithMatch(
          Bridge.insertLink,
          {
            'data-canvas-previewable': true,
            title: uploadResult.display_name,
            href: uploadResult.url
          },
          false
        )
      })

      it('delegates to fileEmbed for embed data', () => {
        actions.embedUploadResult({preview_url: 'http://a.preview.com/url'})
        sinon.assert.calledWithMatch(Bridge.insertLink, {
          embed: {type: 'scribd'}
        })
      })

      it('insert image on image type and text not selected', () => {
        const expected = {'content-type': 'image/png'}
        actions.embedUploadResult(expected)
        sinon.assert.calledWithMatch(Bridge.insertLink, {
          embed: {type: 'image'}
        })
      })

      it('link image on image type and text selected', () => {
        sinon.stub(Bridge, 'existingContentToLink').callsFake(() => true)
        sinon.stub(Bridge, 'existingContentToLinkIsImg').callsFake(() => false)
        actions.embedUploadResult({'content-type': 'image/png'}, 'files')
        sinon.assert.calledWithMatch(Bridge.insertLink, {
          embed: {type: 'image'}
        })
        Bridge.existingContentToLink.restore()
        Bridge.existingContentToLinkIsImg.restore()
      })
    })
  })

  describe('handleFailures', () => {
    it('calls quota exceeded when the file size exceeds the quota', () => {
      const fakeDispatch = sinon.spy()
      const error = {
        response: new Response('{ "message": "file size exceeds quota" }', {status: 400})
      }
      return actions.handleFailures(error, fakeDispatch).then(() => {
        sinon.assert.calledWith(
          fakeDispatch,
          sinon.match({
            type: 'QUOTA_EXCEEDED_UPLOAD',
            error
          })
        )
      })
    })
    it('calls failUpload for other errors', () => {
      const fakeDispatch = sinon.spy()
      const error = {
        response: new Response('{ "message": "we don\'t like you " }', {status: 400})
      }
      return actions.handleFailures(error, fakeDispatch).then(() => {
        sinon.assert.calledWith(
          fakeDispatch,
          sinon.match({
            type: 'FAIL_FILE_UPLOAD',
            error
          })
        )
      })
    })

    it('calls failUpload if there is no response property on the error', () => {
      const fakeDispatch = sinon.spy()
      const error = new Error('Fake Client Side Error')
      return actions.handleFailures(error, fakeDispatch).then(() => {
        sinon.assert.calledWith(
          fakeDispatch,
          sinon.match({
            type: 'FAIL_FILE_UPLOAD',
            error
          })
        )
      })
    })
  })

  describe('activateMediaUpload', () => {
    it('inserts the placeholder through the bridge', () => {
      const bridgeSpy = sinon.spy(Bridge, 'insertImagePlaceholder')
      const store = spiedStore({})
      store.dispatch(actions.activateMediaUpload({}))
      sinon.assert.called(bridgeSpy)
    })

    it('dispatches a START_MEDIA_UPLOADING action', () => {
      const store = spiedStore({})
      store.dispatch(actions.activateMediaUpload({}))
      sinon.assert.calledWith(store.spy, {type: 'START_MEDIA_UPLOADING', payload: {}})
    })
  })

  describe('removePlaceholdersFor', () => {
    it('removes the placeholder through the bridge', () => {
      const bridgeSpy = sinon.spy(Bridge, 'removePlaceholders')
      const store = spiedStore({})
      store.dispatch(actions.removePlaceholdersFor('image1'))
      sinon.assert.calledWith(bridgeSpy, 'image1')
    })

    it('dispatches a STOP_MEDIA_UPLOADING action', () => {
      const store = spiedStore({})
      store.dispatch(actions.removePlaceholdersFor('image1'))
      sinon.assert.calledWith(store.spy, {type: 'STOP_MEDIA_UPLOADING'})
    })
  })
})
