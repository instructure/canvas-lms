/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import getCookie from '@instructure/get-cookie'

interface BasicFileSystemObject {
  id: number | string
  type: 'Folder' | 'File'
}

interface UsageRights {
  use_justification: string
  legal_copyright: string
}

type UsageRightsFunc = (
  filesystemObject: BasicFileSystemObject[],
  usageRights: UsageRights,
  contextId: string,
  contextType: string
) => void

/**
 * Sets usage rights for an array of files and folders within the specified context.
 *
 * This function updates the usage rights for a collection of file and folder objects
 * based on the provided context. It constructs a payload with the file and folder IDs
 * and the desired usage rights, then sends a PUT request to the appropriate API endpoint.
 *
 * Note: This function will only successfully update the usage rights of active attachments and folders
 * that are contained within the given context specified by `contextId` and `contextType`.
 * Any ids that belong to files/folders that are not active or not contained within the given context
 * Will be ignored.
 *
 * @param {BasicFileSystemObject[]} filesystemObject - An array of basic file and folder objects to update.
 * @param {UsageRights} usageRights - The usage rights to apply to the file and folder objects.
 * @param {string} contextId - The ID of the context (e.g., course) containing the files and folders.
 * @param {string} contextType - The type of context (e.g., 'Course') which is case-insensitive.
 *
 * @returns {Promise<any>} A promise that resolves with the response data from the API or rejects with an error.
 *
 * @example
 * setUsageRights(
 *   [{ id: 1, type: 'File' }, { id: 2, type: 'Folder' }],
 *   { use_justification: 'fair_use', legal_copyright: 'copyright owner' },
 *   '123',
 *   'Course'
 * );
 */
export const setUsageRights: UsageRightsFunc = async (
  filesystemObject,
  usageRights,
  contextId,
  contextType
) => {
  const folderIds: (number | string)[] = []
  const fileIds: (number | string)[] = []

  // separate the file and folder ids
  filesystemObject.forEach(item => {
    if (item.type === 'Folder') {
      folderIds.push(item.id)
    } else {
      fileIds.push(item.id)
    }
  })

  const contextTypePath = contextType.toLowerCase().replace(/([^s])$/, '$1s')
  const apiUrl = `/api/v1/${contextTypePath}/${contextId}/usage_rights`

  // Construct the payload
  const payload = new URLSearchParams()
  fileIds.filter(id => id != null).forEach(id => payload.append('file_ids[]', id.toString()))
  folderIds.filter(id => id != null).forEach(id => payload.append('folder_ids[]', id.toString()))

  Object.entries(usageRights)
    .filter(([value]) => value != null)
    .forEach(([key, value]) => {
      payload.append(`usage_rights[${key}]`, value.toString())
    })

  // Request options
  const requestOptions = {
    method: 'PUT',
    body: payload,
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
  }

  try {
    const response = await fetch(apiUrl, requestOptions)
    const responseData = await response.json()
    return Promise.resolve(responseData)
  } catch (error) {
    return Promise.reject(error)
  }
}
