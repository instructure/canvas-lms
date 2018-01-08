/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import axios from 'axios'

/*
 * preflightUrl: usually something like
 *   `/api/v1/courses/:course_id/files` or
 *   `/api/v1/folders/:folder_id/files`
 * preflightData: see api, but something like
 *   `{ name, size, parent_folder_path, type, on_duplicate, no_redirect }`
 * file: the file object to upload.
 *   To get this off of an input element: `input.files[0]`
 *   To get this off of a drop event: `e.dataTransfer.files[0]`
 */
export default function (preflightUrl, preflightData, file, ajaxLib = axios) {
  let successUrl;

  return ajaxLib.post(preflightUrl, preflightData).then((response) => {
    const formData = new FormData();
    Object.entries(response.data.upload_params).forEach(([key, value]) => {
      formData.append(key, value);
    });
    successUrl = response.data.upload_params.success_url
    const config = {
      responseType: (successUrl ? 'document' : 'json'),
      withCredentials: true
    }
    formData.append('file', file);
    return ajaxLib.post(response.data.upload_url, formData, config);
  }).then((response) => {
    if (successUrl) {
      // s3 upload, need to ping success_url to
      // finalize and get back attachment information
      return ajaxLib.get(successUrl);
    } else if (response.status === 201) {
      // inst-fs upload, need to request attachment
      // information from location
      return ajaxLib.get(response.data.location);
    } else {
      // local-storage upload, this _is_ the attachment information
      return response;
    }
  });
}
