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

import {executeQuery} from '@canvas/query/graphql'
import {
  LOAD_DASHBOARD_CARDS_QUERY,
  DASHBOARD_ACTIVITY_STREAM_SUMMARY_QUERY,
} from './graphql/Queries'

interface DashboardQueryKeyParams {
  userID: string | null
  observedUserID: string | null
}

export async function fetchDashboardCardsAsync(params: DashboardQueryKeyParams): Promise<any> {
  const {userID, observedUserID} = params
  if (!userID) {
    throw new Error('User ID is required')
  }

  const data = await executeQuery<any>(LOAD_DASHBOARD_CARDS_QUERY, {userID, observedUserID})
  return data
}

interface ActivityStreamSummaryQueryKeyParams {
  userID: string | null
}

export async function fetchActivityStreamSummariesAsync(
  params: ActivityStreamSummaryQueryKeyParams
): Promise<any> {
  const {userID} = params
  if (!userID) {
    throw new Error('User ID is required')
  }

  const data = await executeQuery<any>(DASHBOARD_ACTIVITY_STREAM_SUMMARY_QUERY, {userID})
  return data
}
