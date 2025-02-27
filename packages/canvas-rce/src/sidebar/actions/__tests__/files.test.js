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

import * as actions from '../files'
import {spiedStore} from './utils'

describe('Sidebar files actions', () => {
  describe('createToggle()', () => {
    it('has the right type', () => {
      const action = actions.createToggle()
      expect(action.type).toBe(actions.TOGGLE)
    })

    it('includes id from first argument', () => {
      const id = 47
      expect(actions.createToggle(id).id).toBe(id)
    })
  })

  describe('createAddFile()', () => {
    const file = {
      id: 47,
      name: 'foo',
      url: 'bar.com',
      type: 'text/plain',
      embed: {type: 'scribd'},
    }

    it('has the right type', () => {
      const action = actions.createAddFile({})
      expect(action.type).toBe(actions.ADD_FILE)
    })

    it('includes properties from file object', () => {
      const action = actions.createAddFile(file)
      expect(action.id).toBe(file.id)
      expect(action.name).toBe(file.name)
      expect(action.url).toBe(file.url)
      expect(action.fileType).toBe(file.type)
    })

    it('passes the embed through to the action', () => {
      const action = actions.createAddFile(file)
      expect(action.embed).toBe(file.embed)
    })
  })

  describe('createRequestFiles()', () => {
    it('has the right type', () => {
      const action = actions.createRequestFiles()
      expect(action.type).toBe(actions.REQUEST_FILES)
    })

    it('includes id from first argument', () => {
      const id = 47
      expect(actions.createRequestFiles(id).id).toBe(id)
    })
  })

  describe('createReceiveFiles()', () => {
    it('has the right type', () => {
      const action = actions.createReceiveFiles(null, [])
      expect(action.type).toBe(actions.RECEIVE_FILES)
    })

    it('includes id from first argument', () => {
      const id = 47
      const action = actions.createReceiveFiles(id, [])
      expect(action.id).toBe(id)
    })

    it('inclues a fileIds array plucked from the files array', () => {
      const files = [{id: 1}, {id: 2}, {id: 3}]
      const action = actions.createReceiveFiles(null, files)
      expect(action.fileIds).toEqual([1, 2, 3])
    })
  })

  describe('createAddFolder()', () => {
    it('has the right type', () => {
      const action = actions.createAddFolder({})
      expect(action.type).toBe(actions.ADD_FOLDER)
    })

    it('includes properties from folder object', () => {
      const folder = {
        id: 47,
        name: 'foo',
        parentId: 42,
        filesUrl: 'bar.com/files',
        foldersUrl: 'bar.com/folders',
      }
      const action = actions.createAddFolder(folder)
      expect(action.id).toBe(folder.id)
      expect(action.name).toBe(folder.name)
      expect(action.filesUrl).toBe(folder.filesUrl)
      expect(action.foldersUrl).toBe(folder.foldersUrl)
      expect(action.parentId).toBe(folder.parentId)
    })
  })

  describe('createRequestSubfolders()', () => {
    it('has the right type', () => {
      const action = actions.createRequestSubfolders()
      expect(action.type).toBe(actions.REQUEST_SUBFOLDERS)
    })

    it('includes id from first argument', () => {
      const id = 47
      expect(actions.createRequestSubfolders(id).id).toBe(id)
    })
  })

  describe('createReceiveSubfolders()', () => {
    it('has the right type', () => {
      const action = actions.createReceiveSubfolders(null, [])
      expect(action.type).toBe(actions.RECEIVE_SUBFOLDERS)
    })

    it('includes id from first argument', () => {
      const id = 47
      const action = actions.createReceiveSubfolders(id, [])
      expect(action.id).toBe(id)
    })

    it('inclues a folderIds array plucked from the folders array', () => {
      const folders = [{id: 1}, {id: 2}, {id: 3}]
      const action = actions.createReceiveSubfolders(null, folders)
      expect(action.folderIds).toEqual([1, 2, 3])
    })
  })

  describe('createSetRoot()', () => {
    it('has the right type', () => {
      const action = actions.createSetRoot()
      expect(action.type).toBe(actions.SET_ROOT)
    })

    it('includes id from first argument', () => {
      const id = 47
      expect(actions.createSetRoot(id).id).toBe(id)
    })
  })

  describe('async actions', () => {
    const id = 47
    const noopPromise = new Promise(() => {})

    let source
    let folders
    let state
    let store

    beforeEach(() => {
      source = {
        fetchPage: jest.fn().mockReturnValue(noopPromise),
        fetchFiles: jest.fn().mockReturnValue(noopPromise),
      }
      folders = {
        [id]: {
          id,
          filesUrl: 'filesUrl',
          foldersUrl: 'foldersUrl',
        },
      }
      state = {source, folders}
      store = spiedStore(state)
    })

    describe('requestFiles()', () => {
      it('dispatches a REQUEST_FILES action', () => {
        store.dispatch(actions.requestFiles(id))
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.REQUEST_FILES,
          }),
        )
      })

      it('calls fetchFiles for source with filesUrl', () => {
        store.dispatch(actions.requestFiles(id))
        expect(source.fetchFiles).toHaveBeenCalledWith(folders[id].filesUrl)
      })

      it('calls fetchFiles for source with optional bookmark', () => {
        const bookmark = 'bookmarkUrl'
        store.dispatch(actions.requestFiles(id, bookmark))
        expect(source.fetchFiles).toHaveBeenCalledWith(bookmark)
      })

      it('dispatches ADD_FILE for each file from fetchFiles', async () => {
        const files = [{}, {}, {}]
        source.fetchFiles.mockResolvedValueOnce({files})
        await store.dispatch(actions.requestFiles(id))
        const addFileCount = store.spy.mock.calls.filter(args => {
          return args[0].type === actions.ADD_FILE
        }).length
        expect(addFileCount).toBe(files.length)
      })

      it('dispatches RECEIVE_FILES action', async () => {
        const files = [{}, {}, {}]
        source.fetchFiles.mockResolvedValueOnce({files})
        await store.dispatch(actions.requestFiles(id))
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            type: actions.RECEIVE_FILES,
            id,
          }),
        )
      })

      it('calls fetchFiles w/ bookmark if returned by fetchFiles', async () => {
        const files = []
        const bookmark = 'someurl'
        source.fetchFiles.mockResolvedValueOnce({files, bookmark}).mockResolvedValueOnce({files})

        await store.dispatch(actions.requestFiles(id))
        expect(source.fetchFiles).toHaveBeenCalledWith(bookmark)
      })
    })

    describe('requestSubfolders()', () => {
      it('dispatches a REQUEST_SUBFOLDERS action', () => {
        store.dispatch(actions.requestSubfolders(id))
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.REQUEST_SUBFOLDERS,
          }),
        )
      })

      it('calls fetchPage for source with foldersUrl', () => {
        store.dispatch(actions.requestSubfolders(id))
        expect(source.fetchPage).toHaveBeenCalledWith(folders[id].foldersUrl)
      })

      it('calls fetchPage for source with optional bookmark', () => {
        const bookmark = 'bookmarkUrl'
        store.dispatch(actions.requestSubfolders(id, bookmark))
        expect(source.fetchPage).toHaveBeenCalledWith(bookmark)
      })

      it('dispatches ADD_FOLDER for each folder from fetchPage', async () => {
        const folders = [{}, {}, {}]
        source.fetchPage.mockResolvedValueOnce({folders})
        await store.dispatch(actions.requestSubfolders(id))
        const addFolderCount = store.spy.mock.calls.filter(args => {
          return args[0].type === actions.ADD_FOLDER
        }).length
        expect(addFolderCount).toBe(folders.length)
      })

      it('dispatches RECEIVE_SUBFOLDERS action', async () => {
        const folders = [{}, {}, {}]
        source.fetchPage.mockResolvedValueOnce({folders})
        await store.dispatch(actions.requestSubfolders(id))
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            type: actions.RECEIVE_SUBFOLDERS,
            id,
          }),
        )
      })

      it('calls fetchPage w/ bookmark if returned by fetchPage', async () => {
        const folders = []
        const bookmark = 'someurl'
        source.fetchPage.mockResolvedValueOnce({folders, bookmark}).mockResolvedValueOnce({folders})

        await store.dispatch(actions.requestSubfolders(id))
        expect(source.fetchPage).toHaveBeenCalledWith(bookmark)
      })
    })

    describe('toggle()', () => {
      it('dispatches TOGGLE action', () => {
        store.dispatch(actions.toggle(id))
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.TOGGLE,
          }),
        )
      })

      it('requests subfolders/files if not requested and expanded', () => {
        folders[id].requested = false
        folders[id].expanded = true
        store.dispatch(actions.toggle(id))
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.REQUEST_FILES,
          }),
        )
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.REQUEST_SUBFOLDERS,
          }),
        )
      })

      it('does not request subfolders/files if already requested', () => {
        folders[id].requested = true
        folders[id].expanded = true
        store.dispatch(actions.toggle(id))
        expect(store.spy).not.toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.REQUEST_FILES,
          }),
        )
        expect(store.spy).not.toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.REQUEST_FOLDERS,
          }),
        )
      })
    })

    describe('init()', () => {
      beforeEach(() => {
        source.fetchRootFolder = jest.fn().mockReturnValue(noopPromise)
      })

      it('calls fetchRootFolder for source with state', () => {
        store.dispatch(actions.init)
        expect(source.fetchRootFolder).toHaveBeenCalledWith(state)
      })

      it('calls dispatches SET_ROOT', async () => {
        const id = 47
        const folders = [{id}]
        source.fetchRootFolder.mockResolvedValueOnce({folders})
        await store.dispatch(actions.init)
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.SET_ROOT,
          }),
        )
      })

      it('dispatches ADD_FOLDER for root folder', async () => {
        const id = 47
        const folders = [{id}]
        source.fetchRootFolder.mockResolvedValueOnce({folders})
        await store.dispatch(actions.init)
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.ADD_FOLDER,
          }),
        )
      })

      it('dispatches TOGGLE for root folder', async () => {
        const id = 47
        const folders = [{id}]
        source.fetchRootFolder.mockResolvedValueOnce({folders})
        await store.dispatch(actions.init)
        expect(store.spy).toHaveBeenCalledWith(
          expect.objectContaining({
            id,
            type: actions.TOGGLE,
          }),
        )
      })
    })
  })
})
