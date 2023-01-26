/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {PENDING_MEDIA_ENTRY_ID} from '../FileBrowser'

const folderFor = (context, overrides, bookmark) => {
  const id = overrides?.id || 26
  return {
    folders: [
      {
        id,
        parentId: null,
        name: `${context.type} files`,
        filesUrl: `http://rce.canvas.docker/api/files/${id}`,
        foldersUrl: `http://rce.canvas.docker/api/folders/${id}`,
        lockedForUser: false,
        contextType: context.type,
        contextId: context.id,
        canUpload: true,
        ...overrides,
      },
    ],
    bookmark,
  }
}

const filesFor = (folder, overrides, bookmark) => ({
  files: [
    {
      id: 172,
      uuid: 'KEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'image/jpeg',
      name: 'its-working-its-working.jpg',
      url: 'http://canvas.docker/files/172/download?download_frd=1',
      embed: {type: 'image'},
      folderId: folder.id,
      thumbnailUrl:
        'http://canvas.docker/images/thumbnails/172/KEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      ...overrides,
    },
    {
      id: 173,
      uuid: 'BEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'image/jpeg',
      name: 'no-thumbnail.jpg',
      url: 'http://canvas.docker/files/173/download?download_frd=1',
      embed: {type: 'image'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 174,
      uuid: 'CEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'application/msword',
      name: 'doc.docx',
      url: 'http://canvas.docker/files/174/download?download_frd=1',
      embed: {type: 'file'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 175,
      uuid: 'DEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'application/vnd.ms-powerpoint',
      name: 'slides.pptx',
      url: 'http://canvas.docker/files/175/download?download_frd=1',
      embed: {type: 'file'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 176,
      uuid: 'EEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'application/pdf',
      name: 'pdf.pdf',
      url: 'http://canvas.docker/files/176/download?download_frd=1',
      embed: {type: 'file'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 177,
      uuid: 'FEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'application/vnd.ms-excel',
      name: 'spreadsheet.xlsx',
      url: 'http://canvas.docker/files/177/download?download_frd=1',
      embed: {type: 'file'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 178,
      uuid: 'GEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'application/x-yaml',
      name: 'docker-compose.override.yml',
      url: 'http://canvas.docker/files/178/download?download_frd=1',
      embed: {type: 'file'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 179,
      uuid: 'HEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'video/mp4',
      name: 'vid.mov',
      url: 'http://canvas.docker/files/179/download?download_frd=1',
      embed: {type: 'video'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 180,
      uuid: 'IEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'audio/mp4',
      name: 'sound.mp4',
      url: 'http://canvas.docker/files/180/download?download_frd=1',
      embed: {type: 'audio'},
      folderId: folder.id,
      ...overrides,
    },
    {
      id: 181,
      uuid: 'JEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'audio/mp4',
      name: 'im-still-pending.mp4',
      url: 'http://canvas.docker/files/181/download?download_frd=1',
      embed: {type: 'audio'},
      folderId: folder.id,
      mediaEntryId: PENDING_MEDIA_ENTRY_ID,
      ...overrides,
    },
    {
      id: 182,
      uuid: 'KEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ',
      type: 'image/svg+xml',
      name: 'icon-maker-icon.svg',
      url: 'http://canvas.docker/files/182/download?download_frd=1',
      embed: {type: 'image'},
      folderId: folder.id,
      thumbnailUrl: 'http://canvas.docker/files/182/download?download_frd=1',
      mediaEntryId: null,
      ...overrides,
    },
  ],
  bookmark,
})

export const apiSource = () => ({
  fetchRootFolder: jest.fn().mockImplementation(({contextType}) => {
    if (contextType === 'course') {
      return Promise.resolve(folderFor({type: 'course', id: 1}, {id: 26}))
    } else {
      return Promise.resolve(folderFor({type: 'user', id: 2}, {id: 277}))
    }
  }),
  fetchBookmarkedData: jest.fn().mockImplementation((_fn, args, onSuccess) => {
    let responseData

    if (args.folderId) {
      responseData = folderFor({type: 'Course', id: 1, parentId: 26})
    } else {
      const folderId = args.filesUrl?.split('/files/')?.pop()
      if (!folderId) return

      const filesFolder = folderFor({type: 'course', id: 1}).folders[0]
      responseData = filesFor(filesFolder, {folderId: parseInt(folderId, 10)})
    }
    onSuccess(responseData)
    return Promise.resolve(responseData)
  }),
  fetchFilesForFolder: jest.fn().mockRejectedValue(),
  fetchSubFolders: jest.fn().mockResolvedValue(),
})
