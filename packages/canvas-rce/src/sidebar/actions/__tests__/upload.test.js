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

import moxios from 'moxios'
import * as actions from '../upload'
import * as filesActions from '../files'
import * as imagesActions from '../images'
import {buildSvg} from '../../../rce/plugins/instructure_icon_maker/svg'
import {spiedStore} from './utils'
import Bridge from '../../../bridge'
import {K5Uploader} from '@instructure/k5uploader'
import {
  DEFAULT_SETTINGS,
  SVG_TYPE,
  ICON_MAKER_ICONS,
  TYPE,
} from '../../../rce/plugins/instructure_icon_maker/svg/constants'

const fakeFileReader = {
  readAsDataURL() {
    this.onload()
  },
  result: 'fakeDataURL',
}

describe('Upload data actions', () => {
  const results = {id: 47}
  const file = {url: 'http://canvas.test/files/17/download', thumbnail_url: 'thumbnailurl'}
  const successSource = {
    fetchIconMakerFolder() {
      return Promise.resolve({
        folders: [{id: 2, name: 'Icon Maker', parentId: 1}],
      })
    },

    fetchFolders() {
      return Promise.resolve({
        folders: [{id: 1, name: 'course files', parentId: null}],
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
          partnerData: 'data from our partners',
        },
      })
    },

    uploadMediaToCanvas() {
      return Promise.resolve({media_object: {media_id: 2}})
    },

    preflightUpload: jest.fn().mockResolvedValue(results),
    uploadFRD: jest.fn().mockResolvedValue(results),
    setUsageRights: jest.fn(),
    getFile: jest.fn().mockResolvedValue(file),
    fetchMediaFolder: jest.fn().mockResolvedValue({folders: [{id: 24}]}),
  }

  beforeEach(() => {
    Bridge.focusEditor(null)
    successSource.uploadFRD.mockClear()
    successSource.setUsageRights.mockClear()
  })

  const defaults = {
    host: 'http://host:port',
    jwt: 'theJWT',
    source: successSource,
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
        expect(store.spy).toHaveBeenCalledWith({
          type: actions.RECEIVE_FOLDER,
          id: 1,
          name: 'course files',
          parentId: null,
        })
      })
    })

    it('skips the fetch if there are folders already', () => {
      const baseState = setupState()
      baseState.upload = {folders: [{id: 1, name: 'course files'}]}
      const store = spiedStore(baseState)
      store.dispatch(actions.fetchFolders())
      expect(store.spy).not.toHaveBeenCalledWith({
        type: actions.RECEIVE_FOLDER,
        id: 1,
        name: 'course files',
        parentId: null,
      })
    })

    it('fetches the next page if a bookmark is passed', () => {
      const bookmarkSource = {
        fetchFolders(s, bm) {
          if (bm) {
            return Promise.resolve({
              folders: [{id: 2, name: 'blah', parentId: 1}],
            })
          } else {
            return Promise.resolve({
              folders: [{id: 1, name: 'course files', parentId: null}],
              bookmark: 'bm',
            })
          }
        },
      }

      const baseState = {
        source: bookmarkSource,
        jwt: 'theJWT',
        upload: {folders: []},
      }
      const store = spiedStore(baseState)
      return store.dispatch(actions.fetchFolders()).then(() => {
        expect(store.spy).toHaveBeenCalledWith({
          type: actions.RECEIVE_FOLDER,
          id: 1,
          name: 'course files',
          parentId: null,
        })
        expect(store.spy).toHaveBeenCalledWith({
          type: actions.RECEIVE_FOLDER,
          id: 2,
          name: 'blah',
          parentId: 1,
        })
      })
    })

    it('dispatches a batch action', () => {
      const baseState = setupState()
      baseState.upload = {folders: []}
      const store = spiedStore(baseState)
      return store.dispatch(actions.fetchFolders()).then(() => {
        expect(store.spy).toHaveBeenCalledWith({
          type: actions.PROCESSED_FOLDER_BATCH,
          folders: [],
        })
      })
    })
  })

  describe('setUsageRights', () => {
    it('make request to set usage rights if file has usage rights', () => {
      const file = {usageRights: {usageRight: 'foo'}}
      actions.setUsageRights(successSource, file, results)
      expect(successSource.setUsageRights).toHaveBeenCalledWith(results.id, file.usageRights)
    })

    it('does not make request if file has no usage rights', () => {
      const file = {}
      actions.setUsageRights(successSource, file, results)
      expect(successSource.setUsageRights).not.toHaveBeenCalled()
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
        parentFolderId: 2,
      }

      const canvasProps = {
        host: 'http://host:port',
        contextId: 101,
        contextType: 'course',
        onDuplicate: undefined,
        category: ICON_MAKER_ICONS,
      }

      return store.dispatch(actions.uploadToIconMakerFolder(svg)).then(() => {
        expect(successSource.preflightUpload).toHaveBeenCalledWith(fileMetaProps, canvasProps)
      })
    })

    it('dispatches uploadFRD with the svg domElement', () => {
      const store = spiedStore(baseState)

      return store.dispatch(actions.uploadToIconMakerFolder(svg)).then(() => {
        expect(successSource.uploadFRD).toHaveBeenCalledWith(
          new File([svg.domElement.outerHTML], svg.name, {type: 'image/svg+xml'}),
          results,
        )
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

        expect(successSource.preflightUpload).toHaveBeenCalledWith(
          {
            file: {
              name: 'icon.svg',
              type: 'image/svg+xml',
            },
            name: 'icon.svg',
            parentFolderId: 2,
          },
          {
            category: ICON_MAKER_ICONS,
            contextId: 101,
            contextType: 'course',
            host: 'http://host:port',
            onDuplicate: 'overwrite',
          },
        )
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
        type: 'image/png',
      },
    }

    it('dispatches a uploadPreflight with the proper parentFolderId set', () => {
      const baseState = setupState()
      const store = spiedStore(baseState)
      return store.dispatch(actions.uploadToMediaFolder('images', fakeFileMetaData)).then(() => {
        expect(store.spy).toHaveBeenCalledWith({
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
              type: 'image/png',
            },
          },
        })
      })
    })

    it('results in a START_MEDIA_UPLOADING action being fired', () => {
      const baseState = setupState()
      const store = spiedStore(baseState)
      return store.dispatch(actions.uploadToMediaFolder('images', fakeFileMetaData)).then(() => {
        expect(store.spy).toHaveBeenCalledWith({
          type: 'START_MEDIA_UPLOADING',
          payload: fakeFileMetaData,
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
        type: 'video/mov',
      },
    }
    let k5uploaderstub

    beforeEach(() => {
      moxios.install()
      k5uploaderstub = jest
        .spyOn(K5Uploader.prototype, 'loadUiConf')
        .mockImplementation(() => 'mock')
    })
    afterEach(() => {
      moxios.uninstall()
      k5uploaderstub.mockRestore()
    })

    it('uploads directly to notorious/kaltura', () => {
      const baseState = setupState()
      const store = spiedStore(baseState)

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
              partnerData: 'data from our partners',
            },
          },
        },
      )

      return store.dispatch(actions.uploadToMediaFolder('media', fakeFileMetaData)).then(() => {
        expect(k5uploaderstub).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('generateThumbnailUrl', () => {
    it('returns the results if the file is not an image', () => {
      const results = {'content-type': 'application/pdf'}
      return actions.generateThumbnailUrl(results).then(returnResults => {
        expect(returnResults).toEqual(results)
      })
    })

    it('sets a data url for the thumbnail', () => {
      const results = {
        'content-type': 'image/jpeg',
      }

      const fakeFileDOMObject = {}

      return actions
        .generateThumbnailUrl(results, fakeFileDOMObject, fakeFileReader)
        .then(returnResults => {
          expect(returnResults).toEqual({
            'content-type': 'image/jpeg',
            thumbnail_url: 'fakeDataURL',
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
          selectedTabIndex: 2,
        },
      }
    }

    beforeEach(() => {
      const baseState = getBaseState()
      store = spiedStore(baseState)
      props = {}
    })

    afterEach(() => {
      if (Bridge.insertImage.mockRestore) {
        Bridge.insertImage.mockRestore()
      }
      if (Bridge.insertLink.mockRestore) {
        Bridge.insertLink.mockRestore()
      }
    })

    describe('when the file is svg', () => {
      let fileText

      const file = () => ({
        slice: () => ({
          text: async () => fileText,
        }),
        type: SVG_TYPE,
      })

      const fileProps = () => ({
        domObject: file(),
      })

      const subject = () => store.dispatch(actions.uploadPreflight('files', fileProps()))

      describe('when the file is an icon maker svg', () => {
        beforeEach(() => {
          fileText = 'something something ' + TYPE
        })

        it('sets the category to "icon_maker_icons"', () => {
          subject().then(() => {
            expect(successSource.preflightUpload).toHaveBeenCalledWith(
              expect.objectContaining({}),
              expect.objectContaining({
                category: ICON_MAKER_ICONS,
              }),
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
            expect(successSource.preflightUpload).toHaveBeenCalledWith(
              expect.objectContaining({}),
              expect.objectContaining({
                category: undefined,
              }),
            )
          })
        })
      })
    })

    describe('when the file is not an svg', () => {
      let fileText

      const file = () => ({
        slice: () => ({
          text: async () => fileText,
        }),
        type: 'image/png',
      })

      const fileProps = () => ({
        domObject: file(),
      })

      const subject = () => store.dispatch(actions.uploadPreflight('files', fileProps()))

      it('sets the category to undefined', () => {
        subject().then(() => {
          expect(successSource.preflightUpload).toHaveBeenCalledWith(
            expect.objectContaining({}),
            expect.objectContaining({category: undefined}),
          )
        })
      })
    })

    it('follows chain preflight -> upload -> complete', () => {
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        expect(store.spy).toHaveBeenCalledWith({
          type: actions.START_FILE_UPLOAD,
          file: {},
        })
        expect(store.spy).toHaveBeenCalledWith({
          type: actions.COMPLETE_FILE_UPLOAD,
          results: {
            contextType: 'course',
            contextId: 42,
            ...results,
          },
        })
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({type: filesActions.INSERT_FILE}),
        )
      })
    })

    it('sets usage rights', () => {
      props.usageRights = {}
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        expect(successSource.setUsageRights).toHaveBeenCalledWith(results.id, props.usageRights)
      })
    })

    it('dispatches ADD_FILE with correct payload', () => {
      props.contentType = 'image/png'
      successSource.uploadFRD.mockResolvedValueOnce({
        id: 47,
        display_name: 'foo',
        preview_url: 'http://someurl',
      })
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            type: filesActions.ADD_FILE,
            id: 47,
            name: 'foo',
            url: 'http://someurl',
            fileType: 'image/png',
          }),
        )
      })
    })

    it('dispatches INSERT_FILE with folder and file ids', () => {
      props.parentFolderId = 74
      successSource.uploadFRD.mockResolvedValueOnce({id: 47})
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            type: filesActions.INSERT_FILE,
            id: 74,
            fileId: 47,
          }),
        )
      })
    })

    it('dispatches ADD_IMAGE if content type is image/*', () => {
      props.fileReader = fakeFileReader
      successSource.uploadFRD.mockResolvedValueOnce({
        'content-type': 'image/png',
        thumbnail_url: 'thumbnailurl',
      })
      return store.dispatch(actions.uploadPreflight('images', props)).then(() => {
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({type: imagesActions.ADD_IMAGE}),
        )
      })
    })

    it('does not dispatch ADD_IMAGE if content type is not image/*', () => {
      props.contentType = 'text/plain'
      return store.dispatch(actions.uploadPreflight('images', props)).then(() => {
        expect(store.spy).not.toHaveBeenCalledWith(
          expect.objectContaining({type: imagesActions.INSERT_IMAGE}),
        )
      })
    })

    it('inserts the image content through the bridge', () => {
      props.fileReader = fakeFileReader
      const bridgeSpy = jest.spyOn(Bridge, 'insertImage')
      successSource.uploadFRD.mockResolvedValueOnce({
        'content-type': 'image/jpeg',
        thumbnail_url: 'thumbnailurl',
      })
      return store.dispatch(actions.uploadPreflight('images', props)).then(() => {
        expect(bridgeSpy).toHaveBeenCalledTimes(1)
      })
    })

    it('inserts the file content through the bridge', () => {
      props.fileReader = fakeFileReader
      const bridgeSpy = jest.spyOn(Bridge, 'insertLink')
      const state = getBaseState()
      state.ui.selectedTabIndex = 1
      store = spiedStore(state)
      successSource.uploadFRD.mockResolvedValueOnce({
        'content-type': 'image/jpeg',
        thumbnail_url: 'thumbnailurl',
      })
      return store.dispatch(actions.uploadPreflight('files', props)).then(() => {
        expect(bridgeSpy).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('allUploadCompleteActions', () => {
    it('returns a list of actions', () => {
      const fileMetaProps = {
        parentFolderId: 12,
      }
      const results = {}
      const actionSet = actions.allUploadCompleteActions(results, fileMetaProps)
      expect(actionSet).toHaveLength(3)
    })
  })

  describe('embedUploadResult', () => {
    beforeEach(() => {
      jest.spyOn(Bridge, 'insertLink')
      jest.spyOn(Bridge, 'insertImage')
    })

    afterEach(() => {
      Bridge.insertLink.mockRestore()
      Bridge.insertImage.mockRestore()
    })

    describe('link embed', () => {
      describe('when the content-type is previewable by canvas', () => {
        const uploadResult = {
          display_name: 'display_name',
          url: 'http://somewhere',
          'content-type': 'application/pdf',
        }

        it('inserts link with data-canvas-previewable', () => {
          actions.embedUploadResult(uploadResult)
          expect(Bridge.insertLink).toHaveBeenCalledWith(
            expect.objectContaining({
              'data-canvas-previewable': true,
              title: uploadResult.display_name,
              href: uploadResult.url,
            }),
            false,
          )
        })

        it('sets "disableInlinePreview" embed data to true', () => {
          actions.embedUploadResult(uploadResult)
          expect(Bridge.insertLink).toHaveBeenCalledWith(
            expect.objectContaining({
              embed: expect.objectContaining({
                disableInlinePreview: true,
              }),
            }),
            false,
          )
        })
      })

      it('inserts link with display_name as title', () => {
        const expected = 'foo'
        actions.embedUploadResult({display_name: expected})
        expect(Bridge.insertLink).toHaveBeenCalledWith(
          expect.objectContaining({
            title: expected,
          }),
          false,
        )
      })

      it('inserts link with url as href', () => {
        const expected = 'http://example.com'
        actions.embedUploadResult({url: expected})
        expect(Bridge.insertLink).toHaveBeenCalledWith(
          expect.objectContaining({
            href: expected,
          }),
          false,
        )
      })

      it('delegates to fileEmbed for embed data', () => {
        actions.embedUploadResult({preview_url: 'http://a.preview.com/url'})
        expect(Bridge.insertLink).toHaveBeenCalledWith(
          expect.objectContaining({
            embed: expect.objectContaining({
              type: 'scribd',
            }),
          }),
          false,
        )
      })

      it('insert image on image type and text not selected', () => {
        const expected = {'content-type': 'image/png'}
        actions.embedUploadResult(expected)
        expect(Bridge.insertLink).toHaveBeenCalledWith(
          expect.objectContaining({
            embed: expect.objectContaining({
              type: 'image',
            }),
          }),
          false,
        )
      })

      it('link image on image type and text selected', () => {
        jest.spyOn(Bridge, 'existingContentToLink').mockImplementation(() => true)
        jest.spyOn(Bridge, 'existingContentToLinkIsImg').mockImplementation(() => false)
        actions.embedUploadResult({'content-type': 'image/png'}, 'files')
        expect(Bridge.insertLink).toHaveBeenCalledWith(
          expect.objectContaining({
            embed: expect.objectContaining({
              type: 'image',
            }),
          }),
          false,
        )
        Bridge.existingContentToLink.mockRestore()
        Bridge.existingContentToLinkIsImg.mockRestore()
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
      const fakeDispatch = jest.fn()
      const error = {
        response: new Response('{ "message": "file size exceeds quota" }', {status: 400}),
      }
      return actions.handleFailures(error, fakeDispatch).then(() => {
        expect(fakeDispatch).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'QUOTA_EXCEEDED_UPLOAD',
            error,
          }),
        )
      })
    })
    it('calls failUpload for other errors', () => {
      const fakeDispatch = jest.fn()
      const error = {
        response: new Response('{ "message": "we don\'t like you " }', {status: 400}),
      }
      return actions.handleFailures(error, fakeDispatch).then(() => {
        expect(fakeDispatch).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'FAIL_FILE_UPLOAD',
            error,
          }),
        )
      })
    })

    it('calls failUpload if there is no response property on the error', () => {
      const fakeDispatch = jest.fn()
      const error = new Error('Fake Client Side Error')
      return actions.handleFailures(error, fakeDispatch).then(() => {
        expect(fakeDispatch).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'FAIL_FILE_UPLOAD',
            error,
          }),
        )
      })
    })
  })

  describe('activateMediaUpload', () => {
    it('inserts the placeholder through the bridge', () => {
      const bridgeSpy = jest.spyOn(Bridge, 'insertImagePlaceholder')
      const store = spiedStore({})
      store.dispatch(actions.activateMediaUpload({}))
      expect(bridgeSpy).toHaveBeenCalledTimes(1)
    })

    it('dispatches a START_MEDIA_UPLOADING action', () => {
      const store = spiedStore({})
      store.dispatch(actions.activateMediaUpload({}))
      expect(store.spy).toHaveBeenCalledWith({
        type: 'START_MEDIA_UPLOADING',
        payload: {},
      })
    })
  })

  describe('removePlaceholdersFor', () => {
    let bridgeSpy
    afterEach(() => {
      bridgeSpy && bridgeSpy.mockRestore()
    })
    it('removes the placeholder through the bridge', () => {
      bridgeSpy = jest.spyOn(Bridge, 'removePlaceholders')
      const store = spiedStore({})
      store.dispatch(actions.removePlaceholdersFor('image1'))
      expect(bridgeSpy).toHaveBeenCalledWith('image1')
    })

    it('dispatches a STOP_MEDIA_UPLOADING action', () => {
      const store = spiedStore({})
      store.dispatch(actions.removePlaceholdersFor('image1'))
      expect(store.spy).toHaveBeenCalledWith({
        type: 'STOP_MEDIA_UPLOADING',
      })
    })
  })

  describe('media upload failure', () => {
    let showErrorSpy
    let removePlaceholdersSpy

    beforeEach(() => {
      showErrorSpy = jest.spyOn(Bridge, 'showError')
      removePlaceholdersSpy = jest.spyOn(Bridge, 'removePlaceholders')
    })

    afterEach(() => {
      showErrorSpy.mockRestore()
      removePlaceholdersSpy.mockRestore()
    })

    it('removes placeholders', () => {
      const error = new Error('uh oh')
      const action = actions.failMediaUpload(error)
      expect(showErrorSpy).toHaveBeenCalledWith(error)
      expect(action).toEqual(
        expect.objectContaining({
          type: actions.FAIL_MEDIA_UPLOAD,
          error,
        }),
      )
    })

    it('handles failure', () => {
      const store = spiedStore({})
      const error = new Error('uh oh')
      store.dispatch(actions.mediaUploadComplete(error, {uploadedFile: {name: 'bob'}}))
      expect(removePlaceholdersSpy).toHaveBeenCalledWith('bob')
      expect(showErrorSpy).toHaveBeenCalledWith(error)
    })
  })
})
