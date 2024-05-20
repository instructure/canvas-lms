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

import axios from '@canvas/axios'
import {uploadFile} from '@canvas/upload-file'

async function getUploadUrl() {
  return fetch(`/api/v1/users/${ENV.current_user.id}/folders/root`)
    .then(response => response.json())
    .then(data => ({
      parent_folder_id: data.id,
      files_url: data.files_url,
    }))
}

function onProgress(progressEvent: unknown) {
  // eslint-disable-next-line no-console
  console.log('>>>progress:', progressEvent)
}

async function doFileUpload(file: File) {
  const {parent_folder_id, files_url} = await getUploadUrl()

  // const formData = new FormData()
  // formData.append('name', file.name)
  // formData.append('size', file.size)
  // formData.append('parent_folder_path', '/')
  // formData.append('on_duplicate', 'overwrite')
  // formData.append('file', file)

  return uploadFile(
    files_url,
    {
      name: file.name,
      size: file.size,
      content_type: file.type,
      parent_folder_id,
      on_duplicate: 'overwrite',
      no_redirect: true,
    },
    file,
    axios,
    onProgress,
    false
  )
}

export default doFileUpload
