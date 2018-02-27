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

import _ from 'underscore'
import Folder from '../../models/Folder'
import File from '../../models/File'
import ModuleFile from '../../models/ModuleFile'

/*
  * Sets usage rights on the models in memory based on the response from the
  * API.
  *    apiData - the response from the API
  *    models - an array containing the files/folders to update
  */
// Grab the ids affected from the apiData
export default function updateModelsUsageRights(apiData, models) {
  const affectedIds = apiData && apiData.file_ids
  // Seperate the models array into a file group and a folder group.
  const {files, folders} = _.groupBy(models, function(item) {
    if (item instanceof File) return 'files'
    if (item instanceof ModuleFile) return 'files'
    if (item instanceof Folder) return 'folders'
  })
  // We'll go ahead and update the files and remove the id from our list.
  if (files) {
    files.map(function(file, index) {
      const id = parseInt(file[file.idAttribute], 10)
      const idx = affectedIds.indexOf(id)

      if (affectedIds.includes(id)) {
        file.set({
          usage_rights: {
            legal_copyright: apiData && apiData.legal_copyright,
            license: apiData && apiData.license,
            use_justification: apiData && apiData.use_justification,
            own_copyright: apiData && apiData.own_copyright,
            license_name: apiData && apiData.license_name
          }
        })

        return affectedIds.splice(idx, 1)
      }
    })
  }

  if (affectedIds.length === 0) return

  // Now that we have the files out of the way we can continue to the folders
  if (folders) {
    folders.forEach(folder => {
      // Combine the models from the files and folders collection
      const combinedCollection = folder.files.models.concat(folder.folders.models)
      // The function expects us to give it apiData with file ids, so we
      // update it then give it back to the function recursively.
      apiData.file_ids = affectedIds
      updateModelsUsageRights(apiData, combinedCollection)
    })
  }
}
