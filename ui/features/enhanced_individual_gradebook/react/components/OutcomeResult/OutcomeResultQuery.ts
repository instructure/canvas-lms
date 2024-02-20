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

import getCookie from '@instructure/get-cookie'

export type OutcomeRollupScore = {
  score: string
  links: {
    outcome_id: string
    user: string
  }
}

export type OutcomeRollup = {
  scores?: OutcomeRollupScore[] | []
  links: {
    user: string
    section: string
    status: string
  }
}

export type OutcomeRollupsResultResponse = OutcomeRollup[]

const fetchOutcomeResult = async (): Promise<OutcomeRollupsResultResponse | null> => {
  const url = ENV.GRADEBOOK_OPTIONS.outcome_rollups_url

  if (!url) {
    return null
  }

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to get outcome rollups: ${response.statusText}`)
  }

  const {rollups, error} = await response.json()

  if (error) {
    throw new Error(`Failed to get outcome rubrics`)
  }

  return rollups
}

export default fetchOutcomeResult
