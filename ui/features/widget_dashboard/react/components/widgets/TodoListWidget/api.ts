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
import type {PlannerItem, PlannerOverride} from './types'

export interface FetchPlannerItemsParams {
  start_date?: string
  end_date?: string
  per_page?: number
  order?: 'asc' | 'desc'
}

export interface FetchPlannerItemsResponse {
  items: PlannerItem[]
  nextUrl: string | null
}

export async function fetchPlannerItems(
  params: FetchPlannerItemsParams,
  nextUrl?: string | null,
): Promise<FetchPlannerItemsResponse> {
  let url: string

  if (nextUrl) {
    url = nextUrl
  } else {
    const queryParams = new URLSearchParams()

    if (params.start_date) queryParams.append('start_date', params.start_date)
    if (params.end_date) queryParams.append('end_date', params.end_date)
    if (params.per_page) queryParams.append('per_page', params.per_page.toString())
    if (params.order) queryParams.append('order', params.order)

    url = `/api/v1/planner/items?${queryParams.toString()}`
  }

  const {json, link} = await doFetchApi<PlannerItem[]>({
    path: url,
    method: 'GET',
  })

  const items = json || []
  const next = link?.next?.url || null

  return {
    items,
    nextUrl: next,
  }
}

export interface CreatePlannerOverrideParams {
  plannable_type: string
  plannable_id: string
  marked_complete: boolean
}

export async function createPlannerOverride(
  params: CreatePlannerOverrideParams,
): Promise<PlannerOverride> {
  const {json} = await doFetchApi<PlannerOverride>({
    path: '/api/v1/planner/overrides',
    method: 'POST',
    body: params,
  })

  if (!json) {
    throw new Error('Failed to create planner override')
  }

  return json
}

export interface UpdatePlannerOverrideParams {
  marked_complete: boolean
}

export async function updatePlannerOverride(
  overrideId: number,
  params: UpdatePlannerOverrideParams,
): Promise<PlannerOverride> {
  const {json} = await doFetchApi<PlannerOverride>({
    path: `/api/v1/planner/overrides/${overrideId}`,
    method: 'PUT',
    body: params,
  })

  if (!json) {
    throw new Error('Failed to update planner override')
  }

  return json
}

export interface CreatePlannerNoteParams {
  title: string
  todo_date: string
  details?: string
  course_id?: string
}

export interface PlannerNote {
  id: number
  title: string
  description: string
  user_id: number
  workflow_state: string
  course_id: number | null
  todo_date: string
  created_at: string
  updated_at: string
}

export async function createPlannerNote(params: CreatePlannerNoteParams): Promise<PlannerNote> {
  const {json} = await doFetchApi<PlannerNote>({
    path: '/api/v1/planner_notes',
    method: 'POST',
    body: params,
  })

  if (!json) {
    throw new Error('Failed to create planner note')
  }

  return json
}
