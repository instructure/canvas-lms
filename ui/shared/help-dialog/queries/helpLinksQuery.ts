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
import type {HelpLink} from '../../../api.d'

const HELP_LINKS_PATH = '/help_links'

export default async function helpLinksQuery({signal}: QueryFunctionContext): Promise<HelpLink[]> {
  const data: Array<HelpLink> = []
  const fetchOpts = {signal}
  let path = HELP_LINKS_PATH

  while (path) {
    const {json, link} = await doFetchApi<HelpLink[]>({path, fetchOpts})
    if (json) data.push(...json)
    // @ts-expect-error
    path = link?.next?.url || null
  }
  return data
}
