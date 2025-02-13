/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import filesEnv from '@canvas/files_v2/react/modules/filesEnv'

export const generateFolderByPathUrl = (path: string) => {
  let contextType = filesEnv.contexts[0].contextType
  let contextId = filesEnv.contexts[0].contextId
  let uriEscapedPath = encodeURIComponent(path).replace(/%2F/g, '/')

  if (filesEnv.showingAllContexts) {
    const LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH = /^\/[^/]*/
    // users_1 or courses_102
    const pluralAssetString = uriEscapedPath.split('/')[1]
    const context = filesEnv.contextsDictionary[pluralAssetString] || filesEnv.contexts[0]
    // this removes users_1 or course_102 from the path for the correct api call
    uriEscapedPath = uriEscapedPath.replace(LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH, '')
    contextType = context.contextType
    contextId = context.contextId
  }

  return `/api/v1/${contextType}/${contextId}/folders/by_path${uriEscapedPath}`
}

export const generateFilesQuotaUrl = (singularContextType: string, contextId: string) => {
  return `/api/v1/${singularContextType}s/${contextId}/files/quota`
}

export const generateFolderPostUrl = (parentFolderId: string) => {
  return `/api/v1/folders/${parentFolderId}/folders`
}

export const parseLinkHeader = (header: string | null) => {
  if (!header) return {}
  const links: Record<string, string> = {}
  header.split(',').forEach(part => {
    const match = part.match(/<(.*?)>; rel="(.*?)"/)
    if (match) {
      const [, url, rel] = match
      links[rel] = url
    }
  })
  return links
}
