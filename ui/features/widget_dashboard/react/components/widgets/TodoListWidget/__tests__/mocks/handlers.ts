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

import {http, HttpResponse, graphql} from 'msw'
import {mockPlannerItems} from './data'
import type {PlannerOverride} from '../../types'

let currentStartIndex = 0
let overrideIdCounter = 1000

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

export const plannerOverrideHandlers = [
  http.post('/api/v1/planner/overrides', async ({request}) => {
    const body = (await request.json()) as {
      plannable_type: string
      plannable_id: string
      marked_complete: boolean
    }

    const override: PlannerOverride = {
      id: overrideIdCounter++,
      plannable_type: body.plannable_type,
      plannable_id: body.plannable_id,
      user_id: 1,
      workflow_state: 'active',
      marked_complete: body.marked_complete,
      dismissed: false,
      deleted_at: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    return HttpResponse.json(override, {status: 201})
  }),

  http.put('/api/v1/planner/overrides/:id', async ({params, request}) => {
    const overrideId = params.id as string
    const body = (await request.json()) as {marked_complete: boolean}

    const override: PlannerOverride = {
      id: parseInt(overrideId, 10),
      plannable_type: 'assignment',
      plannable_id: '1',
      user_id: 1,
      workflow_state: 'active',
      marked_complete: body.marked_complete,
      dismissed: false,
      deleted_at: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    return HttpResponse.json(override, {status: 200})
  }),
]

export const errorCreateOverrideHandler = http.post('/api/v1/planner/overrides', () => {
  return HttpResponse.json({errors: [{message: 'Failed to create override'}]}, {status: 500})
})

export const errorUpdateOverrideHandler = http.put('/api/v1/planner/overrides/:id', () => {
  return HttpResponse.json({errors: [{message: 'Failed to update override'}]}, {status: 500})
})

let plannerNoteIdCounter = 2000

export const plannerNoteHandlers = [
  http.post('/api/v1/planner_notes', async ({request}) => {
    const body = (await request.json()) as {
      title: string
      todo_date: string
      details?: string
      course_id?: string
    }

    const plannerNote = {
      id: plannerNoteIdCounter++,
      title: body.title,
      description: body.details || '',
      user_id: 1,
      workflow_state: 'active',
      course_id: body.course_id ? parseInt(body.course_id, 10) : null,
      todo_date: body.todo_date,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    return HttpResponse.json(plannerNote, {status: 201})
  }),
]

export const errorCreatePlannerNoteHandler = http.post('/api/v1/planner_notes', () => {
  return HttpResponse.json({errors: [{message: 'Failed to create planner note'}]}, {status: 500})
})

export const validationErrorPlannerNoteHandler = http.post('/api/v1/planner_notes', () => {
  return HttpResponse.json({errors: {title: [{message: 'Title is required'}]}}, {status: 400})
})

export const widgetConfigHandlers = [
  graphql.mutation('UpdateWidgetDashboardConfig', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateWidgetDashboardConfig: {
          widgetId: variables.widgetId,
          filters: variables.filters,
          errors: null,
        },
      },
    })
  }),
]
