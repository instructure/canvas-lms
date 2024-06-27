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

import type {HelpLink} from '../../../api.d'
import doFetchApi from '@canvas/do-fetch-api-effect'

export default function helpLinksQuery(): Promise<HelpLink[]> {
  return new Promise((resolve, reject) => {
    const data: HelpLink[] = []
    const firstPageUrl = '/help_links'

    async function load(path: string) {
      try {
        const {json, link} = await doFetchApi<HelpLink[]>({path})
        if (json) data.push(...json)
        if (link?.next?.url) await load(link.next.url)
        else resolve(data)
      } catch (e) {
        reject(e)
      }
    }
    load(firstPageUrl)
  })
}
