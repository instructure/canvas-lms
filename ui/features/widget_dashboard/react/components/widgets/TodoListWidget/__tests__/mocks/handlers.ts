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

import {http, HttpResponse} from 'msw'
import {mockPlannerItems} from './data'

let currentStartIndex = 0

export const plannerItemsHandlers = [
  http.get('/api/v1/planner/items', ({request}) => {
    const url = new URL(request.url)
    const perPage = parseInt(url.searchParams.get('per_page') || '15', 10)

    const fullUrl = request.url
    if (fullUrl.includes('start_index=')) {
      const startParam = url.searchParams.get('start_index')
      currentStartIndex = startParam ? parseInt(startParam, 10) : 0
    } else {
      currentStartIndex = 0
    }

    const endIndex = currentStartIndex + perPage
    const items = mockPlannerItems.slice(currentStartIndex, endIndex)

    const totalItems = mockPlannerItems.length
    const hasMore = endIndex < totalItems

    const linkHeader = []
    if (hasMore) {
      linkHeader.push(
        `</api/v1/planner/items?per_page=${perPage}&start_index=${endIndex}>; rel="next"`,
      )
    }
    linkHeader.push(`</api/v1/planner/items?per_page=${perPage}&start_index=0>; rel="first"`)

    return HttpResponse.json(items, {
      headers: {
        Link: linkHeader.join(', '),
      },
    })
  }),
]

export const emptyPlannerItemsHandler = http.get('/api/v1/planner/items', () => {
  return HttpResponse.json([], {
    headers: {
      Link: '</api/v1/planner/items?per_page=15&start_index=0>; rel="first"',
    },
  })
})

export const errorPlannerItemsHandler = http.get('/api/v1/planner/items', () => {
  return HttpResponse.json({errors: [{message: 'Internal server error'}]}, {status: 500})
})
