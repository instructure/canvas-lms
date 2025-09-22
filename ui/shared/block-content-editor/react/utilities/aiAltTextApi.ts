/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import doFetchApi from '@canvas/do-fetch-api-effect'

export interface AiAltTextRequest {
  image: {
    base64_source: string
    type: 'Base64'
  }
  lang?: string
}

export interface AiAltTextResponse {
  image: {
    altText: string
  }
}

export interface AiAltTextApiParams {
  url: string
  requestData: AiAltTextRequest
  signal?: AbortSignal
}

export const generateAiAltText = async (params: AiAltTextApiParams): Promise<AiAltTextResponse> => {
  const {url, requestData, signal} = params

  const {json} = await doFetchApi<AiAltTextResponse>({
    path: url,
    method: 'POST',
    body: requestData,
    signal,
  })

  if (!json) throw new Error('AI Alt Text API response is null or undefined')

  return json
}
