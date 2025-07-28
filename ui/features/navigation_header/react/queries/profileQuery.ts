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

import doFetchApi from '@canvas/do-fetch-api-effect'

import type {QueryFunctionContext} from '@tanstack/react-query'
import type {ProfileTab} from '../../../../api.d'

const PROFILE_TABS_PATH = '/api/v1/users/self/tabs'

export default async function profileQuery({signal}: QueryFunctionContext): Promise<ProfileTab[]> {
  const data: Array<ProfileTab> = []
  const fetchOpts = {signal}
  let path = PROFILE_TABS_PATH

  while (path) {
    const {json, link} = await doFetchApi<ProfileTab[]>({path, fetchOpts})
    if (json) data.push(...json)
    // @ts-expect-error
    path = link?.next?.url || null
  }
  return data
}
