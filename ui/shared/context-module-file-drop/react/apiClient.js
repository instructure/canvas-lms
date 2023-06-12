/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import FilesystemObject from '@canvas/files/backbone/models/FilesystemObject'

function combine(left, right) {
  return Promise.all([left, right]).then(([files1, files2]) => files1.concat(files2))
}

function parse(response) {
  return Promise.resolve(response.data.map(f => new FilesystemObject(f)))
}

function fetchFiles(url) {
  return axios.get(url).then(response => {
    const next = parseLinkHeader(response.headers?.link)?.next
    if (next) {
      return combine(parse(response), fetchFiles(next))
    } else {
      return parse(response)
    }
  })
}

export function getFolderFiles(folderId) {
  return fetchFiles(`/api/v1/folders/${folderId}/files?only[]=names`)
}

export function getCourseRootFolder(courseId) {
  return axios.get(`/api/v1/courses/${courseId}/folders/root`).then(({data}) => data)
}
