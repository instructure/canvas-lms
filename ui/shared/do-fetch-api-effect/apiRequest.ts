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

import doFetchApi from './index'

export type ApiResponse<T> = {
  data: T
  status: number
  link?: {
    next?: {
      url: string
    }
  }
}

export type ApiRequest = {
  path: string
  method: string
  body?: string | object
  headers?: Record<string, string>
}

export async function executeApiRequest<T>(request: ApiRequest): Promise<ApiResponse<T>> {
  // @ts-expect-error
  const {json, response, link} = await doFetchApi(request)

  return {
    data: json as T,
    status: (response as Response).status,
    link,
  }
}

export enum ApiCallStatus {
  NOT_STARTED = 'NOT_STARTED',
  NO_CHANGE = 'NO_CHANGE',
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}
