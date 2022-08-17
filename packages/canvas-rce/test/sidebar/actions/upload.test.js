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
import moxios from 'moxios'
import sinon from 'sinon'
import * as actions from '../../../src/sidebar/actions/upload'
import * as filesActions from '../../../src/sidebar/actions/files'
import * as imagesActions from '../../../src/sidebar/actions/images'
import {buildSvg} from '../../../src/rce/plugins/instructure_icon_maker/svg'
import {spiedStore} from './utils'
import Bridge from '../../../src/bridge'
import K5Uploader from '@instructure/k5uploader'
import {
  DEFAULT_SETTINGS,
  SVG_TYPE,
  ICON_MAKER_ICONS,
  TYPE
} from '../../../src/rce/plugins/instructure_icon_maker/svg/constants'

const fakeFileReader = {
  readAsDataURL() {
    this.onload()
  },
  result: 'fakeDataURL'
}

describe('Upload data actions', () => {
  const results = {id: 47}
  const file = {url: 'http://canvas.test/files/17/download', thumbnail_url: 'thumbnailurl'}
  const successSource = {
    fetchIconMakerFolder() {
      return Promise.resolve({
        folders: [{id: 2, name: 'Icon Maker', parentId: 1}]
      })
    },

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

    preflightUpload: sinon.stub().returns(Promise.resolve(results)),

    uploadFRD: sinon.stub(),

    setUsageRights: sinon.spy(),

    getFile: sinon.stub().returns(Promise.resolve(file)),
    fetchMediaFolder: sinon.stub().returns(Promise.resolve({folders: [{id: 24}]}))
  }

  beforeEach(() => {
    Bridge.focusEditor(null)
    successSource.uploadFRD.resetHistory()
    successSource.uploadFRD.returns(Promise.resolve(results))
    successSource.setUsageRights.resetHistory()
  })

  const defaults = {
    host: 'http://host:port',
    jwt: 'theJWT',
    source: successSource
  }

  function setupState(props) {
    return {...defaults, ...props}
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

  describe('uploadToIconMakerFolder', () => {
    let baseState, svg, getContextOriginal

    beforeEach(() => {
      getContextOriginal = HTMLCanvasElement.prototype.getContext
      HTMLCanvasElement.prototype.getContext = () => ({})

      baseState = setupState({contextId: 101, contextType: 'course'})
      svg = {name: 'icon.svg', domElement: buildSvg(DEFAULT_SETTINGS)}
    })

    afterEach(() => {
      HTMLCanvasElement.prototype.getContext = getContextOriginal
    })

    it('dispatches a preflightUpload with the proper parentFolderId set', () => {
      const store = spiedStore(baseState)

      const fileMetaProps = {
        file: {name: svg.name, type: 'image/svg+xml'},
        name: svg.name,
        parentFolderId: 2
      }

      const canvasProps = {
        host: 'http://host:port',
        contextId: 101,
        contextType: 'course',
        onDuplicate: undefined,
        category: ICON_MAKER_ICONS
      }

      return store.dispatch(actions.uploadToIconMakerFolder(svg)).then(() => {
        assert.deepEqual(baseState.source.preflightUpload.firstCall.args, [
          fileMetaProps,
          canvasProps
        ])
      })
    })

    it('dispatches uploadFRD with the svg domElement', () => {
      const store = spiedStore(baseState)

      return store.dispatch(actions.uploadToIconMakerFolder(svg)).then(() => {
        assert.deepEqual(baseState.source.uploadFRD.firstCall.args, [
          new File([svg.domElement.outerHTML], svg.name, {type: 'image/svg+xml'}),
          results
        ])
      })
    })

    describe('with "onDuplicate" upload setting set', () => {
      let uploadSettings, store

      beforeEach(() => {
        store = spiedStore(baseState)
        uploadSettings = {onDuplicate: 'overwrite'}
      })

      it('includes the specified duplicate strategy setting', async () => {
        await store.dispatch(actions.uploadToIconMakerFolder(svg, uploadSettings))

        assert.deepEqual(baseState.source.preflightUpload.lastCall.args, [
          {
            file: {
              name: 'icon.svg',
              type: 'image/svg+xml'
            },
            name: 'icon.svg',
            parentFolderId: 2
          },
          {
            category: ICON_MAKER_ICONS,
            contextId: 101,
            contextType: 'course',
            host: 'http://host:port',
            onDuplicate: 'overwrite'
          }
        ])
      })
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
              bookmark: undefined,
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

  describe('uploadToMediaFolder for media files', () => {
    const fakeFileMetaData = {
      parentFolderId: 'media',
      name: 'foo.mov',
      size: 3000,
      contentType: 'video/mov',
      domObject: {
        name: 'foo.mov',
        size: 3000,
        type: 'video/mov'
      }
    }
    let k5uploaderstub

    beforeEach(() => {
      moxios.install()
      k5uploaderstub = sinon.stub(K5Uploader.prototype, 'loadUiConf').callsFake(() => 'mock')
    })
    afterEach(() => {
      moxios.uninstall()
      k5uploaderstub.restore()
    })

    it('uploads directly to notorious/kaltura', () => {
      const baseState = setupState()
      const store = spiedStore(baseState)

      // I really just wanted to stub saveMediaRecording and assert that it's called,
      // but sinon can't stub functions from es6 modules.
      // The next best thing is to check that the K5Uploader is exercised
      moxios.stubRequest(
        'http://host:port/api/v1/services/kaltura_session?include_upload_config=1',
        {
          status: 200,
          response: {
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
      )

      return store.dispatch(actions.uploadToMediaFolder('media', fakeFileMetaData)).then(() => {
        sinon.assert.called(k5uploaderstub)
      })
    })
  })

  describe('generateThumbnailUrl', () => {
    it('returns the results if the file is not an image', () => {
      const results = {'content-type': 'application/pdf'}
      return actions.generateThumbnailUrl(results).then(returnResults => {
        assert.deepStrictEqual(results, returnResults)
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
          assert.deepStrictEqual(returnResults, {
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

    describe('when the file is svg', () => {
      let fileText

      const file = () => ({
        slice: () => ({
          text: async () => fileText
        }),
        type: SVG_TYPE
      })

      const fileProps = () => ({
        domObject: file()
      })

      const subject = () => store.dispatch(actions.uploadPreflight('files', fileProps()))

      describe('when the file is an icon maker svg', () => {
        beforeEach(() => {
          fileText = 'something something ' + TYPE
        })

        it('sets the category to "icon_maker_icons"', () => {
          subject().then(() => {
            sinon.assert.calledWith(
              successSource.preflightUpload,
              sinon.match.object,
              sinon.match({
                category: ICON_MAKER_ICONS
              })
            )
          })
        })
      })

      describe('when the file is not an icon maker svg', () => {
        beforeEach(() => {
          fileText = 'something something not icon maker'
        })

        it('sets the category to undefined', () => {
          subject().then(() => {
            sinon.assert.calledWith(
              successSource.preflightUpload,
              sinon.match.object,
              sinon.match({
                category: undefined
              })
            )
          })
        })
      })
    })

    describe('when the file is not an svg', () => {
      let fileText

      const file = () => ({
        slice: () => ({
          text: async () => fileText
        }),
        type: 'image/png'
      })

      const fileProps = () => ({
        domObject: file()
      })

      const subject = () => store.dispatch(actions.uploadPreflight('files', fileProps()))

      it('sets the category to undefined', () => {
        subject().then(() => {
          sinon.assert.calledWith(
            successSource.preflightUpload,
            sinon.match.object,
            sinon.match({category: undefined})
          )
        })
      })
    })

    it('follows chain preflight -> upload -> complete', () => {
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        assert.ok(store.spy.calledWith({type: actions.START_FILE_UPLOAD, file: {}}))
        assert.ok(
          store.spy.calledWith({
            type: actions.COMPLETE_FILE_UPLOAD,
            results: {
              contextType: 'course',
              contextId: 42,
              ...results
            }
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
      describe('when the content-type is preveiewable by canvas', () => {
        const uploadResult = {
          display_name: 'display_name',
          url: 'http://somewhere',
          'content-type': 'application/pdf'
        }

        it('inserts link with data-canvas-previewable', () => {
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

        it('sets "disableInlinePreview" embed data to true', () => {
          actions.embedUploadResult(uploadResult)
          sinon.assert.calledWithMatch(
            Bridge.insertLink,
            {
              embed: {disableInlinePreview: true}
            },
            false
          )
        })
      })

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
    const R = global.Response
    beforeEach(() => {
      if (typeof Response !== 'function') {
        global.Response = function (body, status) {
          this.status = status
          this.json = () => {
            return Promise.resolve(JSON.parse(body))
          }
        }
      }
    })
    afterEach(() => {
      global.Response = R
    })

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
    let bridgeSpy
    afterEach(() => {
      bridgeSpy && bridgeSpy.restore()
    })
    it('removes the placeholder through the bridge', () => {
      bridgeSpy = sinon.spy(Bridge, 'removePlaceholders')
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

  describe('media upload failure', () => {
    let showErrorSpy
    let removePlaceholdersSpy

    beforeEach(() => {
      showErrorSpy = sinon.spy(Bridge, 'showError')
      removePlaceholdersSpy = sinon.spy(Bridge, 'removePlaceholders')
    })

    afterEach(() => {
      showErrorSpy.restore()
      removePlaceholdersSpy.restore()
    })

    it('removes placeholders', () => {
      const error = new Error('uh oh')
      const action = actions.failMediaUpload(error)
      sinon.assert.calledWith(showErrorSpy, error)
      assert.deepStrictEqual(action, {type: actions.FAIL_MEDIA_UPLOAD, error})
    })

    it('handles failure', () => {
      const store = spiedStore({})
      const error = new Error('uh oh')
      store.dispatch(actions.mediaUploadComplete(error, {uploadedFile: {name: 'bob'}}))
      sinon.assert.calledWith(removePlaceholdersSpy, 'bob')
      sinon.assert.calledWith(showErrorSpy, error)
    })
  })
})
