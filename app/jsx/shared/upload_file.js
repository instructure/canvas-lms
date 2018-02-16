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
import qs from 'qs'

/*
 * preflightUrl: usually something like
 *   `/api/v1/courses/:course_id/files` or
 *   `/api/v1/folders/:folder_id/files`
 * preflightData: see api, but something like
 *   `{ name, size, parent_folder_path, type, on_duplicate }`
 *   note that `no_redirect: true` will be forced
 * file: the file object to upload.
 *   To get this off of an input element: `input.files[0]`
 *   To get this off of a drop event: `e.dataTransfer.files[0]`
 */
export function uploadFile(preflightUrl, preflightData, file, ajaxLib = axios) {
  // force "no redirect" behavior. redirecting from the S3 POST breaks under
  // CORS in this pathway
  preflightData.no_redirect = true;

  // when preflightData is flat, won't parse right on server as JSON, so force
  // into a query string
  if (preflightData['attachment[context_code]']) {
    preflightData = qs.stringify(preflightData);
  }

  return ajaxLib.post(preflightUrl, preflightData)
    .then((response) => exports.completeUpload(response.data, file, { ajaxLib }));
}

/*
 * preflightResponse: the response from a preflight request. expected to
 *   contain an `upload_url` and `upload_params` at minimum. `file_param` and
 *   `success_url` are also recognized.
 * file: the file object to upload. see previous function
 * options: to tune or hook into the upload
 *   `filename`: a forced filename for the uploaded file
 *   `onProgress`: a callback to be triggered by upload progress events
 *   `ignoreResult`: after an upload, additional requests may be necessary to
 *     get the metadata about the file; this allows those to be skipped. any
 *     success_url will still be pinged.
 *   `includeAvatar`: if true, request avatar information when fetching file
 *     metadata after upload.
 */
export function completeUpload(preflightResponse, file, options={}) {
  // account for attachments wrapped in array per JSON API format
  if (preflightResponse && preflightResponse.attachments && preflightResponse.attachments[0]) {
    preflightResponse = preflightResponse.attachments[0];
  }

  if (!preflightResponse || !preflightResponse.upload_url) {
    throw new Error("expected a preflightResponse with an upload_url", { preflightResponse });
  }

  const { upload_url } = preflightResponse;
  let { file_param, upload_params, success_url } = preflightResponse;
  file_param = file_param || 'file';
  upload_params = upload_params || {};
  success_url = success_url || upload_params.success_url;
  const ajaxLib = options.ajaxLib || axios;
  const isToS3 = !!success_url;

  // post upload
  // xsslint xssable.receiver.whitelist formData
  const formData = new FormData();
  Object.entries(upload_params).forEach(([key, value]) => formData.append(key, value));
  formData.append(file_param, file, options.filename);
  const upload = ajaxLib.post(upload_url, formData, {
    responseType: (isToS3 ? 'document' : 'json'),
    onUploadProgress: options.onProgress,
    withCredentials: !isToS3
  });

  // finalize upload
  return upload.then((response) => {
    if (success_url) {
      // s3 upload, need to ping success_url to finalize and get back
      // attachment information
      const { Bucket, Key, ETag } = response.data;
      return ajaxLib.get(success_url, { bucket: Bucket, key: Key, etag: ETag });
    } else if (response.status === 201 && !options.ignoreResult) {
      // inst-fs upload, need to request attachment information from
      // location
      let { location } = response.data;
      if (options.includeAvatar) { location = `${location}?include=avatar`; }
      return ajaxLib.get(location);
    } else {
      // local-storage upload, this _is_ the attachment information
      return response;
    }
  }).then((response) => response.data);
}
