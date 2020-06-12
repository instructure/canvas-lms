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
import {
  IconDocumentLine as IconDocumentLineSvg,
  IconMsExcelLine as IconMsExcelLineSvg,
  IconMsPptLine as IconMsPptLineSvg,
  IconMsWordLine as IconMsWordLineSvg,
  IconPdfLine as IconPdfLineSvg,
  IconVideoLine as IconVideoLineSvg,
  IconAudioLine as IconAudioLineSvg
} from '@instructure/ui-icons/es/svg'
import {isVideo, isAudio} from '../rce/plugins/shared/fileTypeUtils'

const stringIds = {Accept: 'application/json+canvas-string-ids'}

export function getRootFolder(contextType, contextId) {
  return axios.get(`/api/v1/${contextType}/${contextId}/folders/root`, stringIds)
}

function createFormData(data) {
  const formData = new FormData()
  Object.keys(data).forEach(key => formData.append(key, data[key]))
  return formData
}

function onFileUploadInfoReceived(file, uploadInfo, onSuccess, onFailure) {
  const formData = createFormData({...uploadInfo.upload_params, file})
  const config = {'Content-Type': 'multipart/form-data', ...stringIds}
  axios
    .post(uploadInfo.upload_url, formData, config)
    .then(response => onSuccess(response.data))
    .catch(response => onFailure(response))
}

export function uploadFile(file, folderId, onSuccess, onFailure) {
  axios
    .post(
      `/api/v1/folders/${folderId}/files`,
      {
        name: file.name,
        size: file.size,
        parent_folder_id: folderId,
        on_duplicate: 'rename'
      },
      stringIds
    )
    .then(response => onFileUploadInfoReceived(file, response.data, onSuccess, onFailure))
    .catch(response => onFailure(response))
}

// I wanted to put this in packages/canvas-rce/src/rce/plugins/shared/fileTypeUtils.js
// with getIconFromType on which it's based, but it gets imported when running mocha
// tests, and that blows up on the import of the svg icons.
// Moving the import and the function here gets around that problem.
// When the INSTUI TreeBrowser supports per-item icons, we can remove this
export function getSVGIconFromType(type) {
  if (isVideo(type)) {
    return IconVideoLineSvg.src
  } else if (isAudio(type)) {
    return IconAudioLineSvg.src
  }
  switch (type) {
    case 'application/msword':
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return IconMsWordLineSvg.src
    case 'application/vnd.ms-powerpoint':
    case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      return IconMsPptLineSvg.src
    case 'application/pdf':
      return IconPdfLineSvg.src
    case 'application/vnd.ms-excel':
    case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      return IconMsExcelLineSvg.src
    default:
      return IconDocumentLineSvg.src
  }
}
