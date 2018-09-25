/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

// ###
// Sets the usage rights for the given items.
// - items should be an array of Files/Folders models
// - usageRights should be an object of this form:
//   {
//      use_justification: fair_use, etc.
//      legal_copyright: "(C) 2014 Instructure"
//      license: creative_commons, etc.
//   }
//
// - callback should be a function that handles what to do when complete
//   It is called with these parameters (success, data)
//     - success is a boolean indicating if the api call worked
//     - data is the data returned from the api
// ###
import $ from 'jquery'
import Folder from '../../models/Folder'
import filesEnv from '../modules/filesEnv'

export default function setUsageRights(items, usageRights, callback) {
  let contextId, contextType, parentFolder
  if (
    filesEnv.contextType === 'users' &&
    items.length > 0 &&
    (parentFolder = items[0].collection && items[0].collection.parentFolder)
  ) {
    contextType = `${parentFolder.get('context_type').toLowerCase()}s`
    contextId = parentFolder.get('context_id')
  } else {
    ;({contextType, contextId} = filesEnv)
  }

  const apiUrl = `/api/v1/${contextType}/${contextId}/usage_rights`
  const folder_ids = []
  const file_ids = []

  items.forEach(item => {
    if (item instanceof Folder) {
      folder_ids.push(item.get('id'))
    } else {
      file_ids.push(item.get('id'))
    }
  })

  return $.ajax({
    url: apiUrl,
    type: 'PUT',
    data: {
      folder_ids,
      file_ids,
      usage_rights: usageRights
    },
    success(data) {
      return callback(true, data)
    },
    error(data) {
      return callback(false, data)
    }
  })
}
