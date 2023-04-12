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

import * as URI from 'uri-js'
import {parseUrlOrNull} from './url-util'

const fileIdPatterns = [/\/\w+s\/\d+\/files\/(\d+)/]

export function guessCanvasFileIdFromUrl(
  inputUrlStr: string,
  restrictToOrigin?: string | null
): string | null {
  const uri = URI.parse(inputUrlStr)

  if (restrictToOrigin != null) {
    const url = parseUrlOrNull(inputUrlStr)
    const originUrl = parseUrlOrNull(restrictToOrigin)

    if (url?.origin !== originUrl?.origin) {
      return null
    }
  }

  if (uri.path == null || uri.path.length === 0) return null

  for (const pattern of fileIdPatterns) {
    const match = uri.path.match(pattern)
    if (match) {
      return match[1]
    }
  }

  return null
}
