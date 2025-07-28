/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {addNewFoldersToCollection, parseAllPagesResponse, sendMoveRequests} from '../utils'
import {FAKE_FOLDERS, FAKE_FILES} from '../../../../../fixtures/fakeData'
import fetchMock from 'fetch-mock'
import {ResolvedName} from '../../../FilesHeader/UploadButton/FileOptions'

describe('MoveModal utils', () => {
  describe('addNewFoldersToCollection', () => {
    it('should add new folders to the collection', () => {
      const collection = {
        '1': {id: '1', name: 'Folder 1', collections: []},
        '2': {id: '2', name: 'Folder 2', collections: []},
      }
      const targetId = '1'
      const newCollections = {
        '3': {id: '3', name: 'Folder 3', collections: []},
        '4': {id: '4', name: 'Folder 4', collections: []},
      }
      const result = addNewFoldersToCollection(collection, targetId, newCollections)
      expect(result).toEqual({
        ...collection,
        [targetId]: {
          ...collection[targetId],
          collections: ['3', '4'],
        },
        ...newCollections,
      })
    })
  })

  describe('parseAllPagesResponse', () => {
    it('should parse all pages response correctly', () => {
      const response = {
        pageParams: [
          {page: '1', per_page: '15'},
          {page: '2', per_page: '15'},
        ],
        pages: [
          {
            nextPage: '1',
            json: [
              {id: '1', name: 'Folder 1'},
              {id: '2', name: 'Folder 2'},
            ],
          },
          {
            nextPage: '2',
            json: [
              {id: '3', name: 'Folder 3'},
              {id: '4', name: 'Folder 4'},
            ],
          },
        ],
      }
      const result = parseAllPagesResponse(response)
      expect(result).toEqual({
        '1': {id: '1', name: 'Folder 1'},
        '2': {id: '2', name: 'Folder 2'},
        '3': {id: '3', name: 'Folder 3'},
        '4': {id: '4', name: 'Folder 4'},
      })
    })
  })

  describe('sendMoveRequests', () => {
    beforeEach(() => {
      fetchMock.reset()
    })

    it('sends move requests for all selected items', async () => {
      fetchMock.put(`/api/v1/files/178`, {
        status: 200,
        headers: {'Content-Type': 'application/json'},
        body: {parent_folder_id: FAKE_FILES[0].id},
      })
      fetchMock.put(`/api/v1/files/179`, {
        status: 200,
        headers: {'Content-Type': 'application/json'},
        body: {parent_folder_id: FAKE_FILES[0].id},
      })
      const selectedFolder = FAKE_FOLDERS[0]
      const selectedItems = [
        {file: FAKE_FILES[0], dup: 'error', name: 'File 1', expandZip: false},
        {file: FAKE_FILES[1], dup: 'rename', name: 'File 2', expandZip: false},
      ]

      await sendMoveRequests(selectedFolder, undefined, selectedItems as unknown as ResolvedName[])
      expect(fetchMock.calls()).toHaveLength(2)
      expect(fetchMock.calls()[0][0]).toContain(`/api/v1/files/178`)
      expect(fetchMock.calls()[1][0]).toContain(`/api/v1/files/179`)
    })

    it('sends move requests for folders', async () => {
      fetchMock.put(`/api/v1/folders/44`, {
        status: 200,
        headers: {'Content-Type': 'application/json'},
        body: {parent_folder_id: FAKE_FOLDERS[0].id},
      })
      const selectedFolder = FAKE_FOLDERS[0]
      const selectedItems = [
        {file: FAKE_FOLDERS[1], dup: 'overwrite', name: 'Folder X', expandZip: false},
      ]
      await sendMoveRequests(selectedFolder, undefined, selectedItems)
      expect(fetchMock.calls()).toHaveLength(1)
      expect(fetchMock.calls()[0][0]).toContain(`/api/v1/folders/44`)
    })

    it('handles 409 conflict (name collision) for files', async () => {
      fetchMock.put(`/api/v1/files/181`, {
        status: 409,
        headers: {'Content-Type': 'application/json'},
        body: {parent_folder_id: FAKE_FILES[0].id},
      })

      const selectedFolder = FAKE_FOLDERS[0]
      const selectedItems = [
        {
          file: FAKE_FILES[2] as unknown as globalThis.File,
          dup: 'error',
          name: 'File Conflict',
          expandZip: false,
        },
      ]
      const resolveCollisions = jest.fn()
      await sendMoveRequests(selectedFolder, resolveCollisions, selectedItems)
      expect(resolveCollisions).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({file: expect.anything(), name: 'File Conflict'}),
        ]),
      )
    })

    it('resolves immediately if selectedItems is empty', async () => {
      const selectedFolder = FAKE_FOLDERS[0]
      await expect(sendMoveRequests(selectedFolder, undefined, [])).resolves.toBeUndefined()
      expect(fetchMock.calls()).toHaveLength(0)
    })
  })
})
