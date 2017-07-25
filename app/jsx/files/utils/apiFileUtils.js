// Copyright (C) 2017 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import axios from 'axios'

const stringIds = {Accept: 'application/json+canvas-string-ids'}

export function getRootFolder (contextType, contextId) {
  return axios.get(`/api/v1/${contextType}/${contextId}/folders/root`, stringIds)
}

function createFormData (data) {
  const formData = new FormData()
  Object.keys(data).forEach(key => formData.append(key, data[key]))
  return formData
}

function onFileUploadInfoReceived (file, uploadInfo, onSuccess, onFailure) {
  const formData = createFormData({...uploadInfo.upload_params, 'file': file})
  const config = {'Content-Type': 'multipart/form-data', ...stringIds}
  axios.post(uploadInfo.upload_url, formData, config)
    .then(response => onSuccess(response.data))
    .catch(response => onFailure(response))
}

export function uploadFile (file, folderId, onSuccess, onFailure) {
  axios.post(`/api/v1/folders/${folderId}/files`, {
    name: file.name,
    size: file.size,
    parent_folder_id: folderId,
    on_duplicate: 'rename'
  }, stringIds)
  .then(response => onFileUploadInfoReceived(file, response.data, onSuccess, onFailure))
  .catch(response => onFailure(response))
}
