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

export interface LMGBRating {
  points: number
  color: string
  description?: string
  mastery?: boolean
}

interface LMGBOutcome {
  id: string | number
  title: string
  context_type?: string
  context_id?: string
  description?: string
  display_name?: string
  friendly_description?: string
  calculation_method: string
  calculation_int?: number
  points_possible: number
  mastery_points: number
  ratings: LMGBRating[]
}

interface LMGBScore {
  score: number
  links: {
    outcome: string | number
  }
}

interface LMGBStudent {
  id: string
  name: string
  display_name: string
  sortable_name: string
  sis_id?: string
  integration_id?: string
  login_id?: string
  avatar_url?: string
  status?: string
}

export interface LMGBOutcomeReporting extends LMGBOutcome {
  alignments?: any[]
}

export interface LMGBScoreReporting extends LMGBScore {
  count?: number
}

export interface RollupsResponseReporting {
  rollups: Array<{
    scores: LMGBScoreReporting[]
    links: {
      user: string | number
      status: string
    }
  }>
  linked: {
    users: LMGBStudent[]
    outcomes: LMGBOutcomeReporting[]
  }
  meta: {
    pagination: {
      per_page: number
      page: number
      count: number
      page_count: number
    }
  }
}

export type MasteryLevel =
  | 'exceeds_mastery'
  | 'mastery'
  | 'near_mastery'
  | 'remediation'
  | 'unassessed'

export type SortColumn = 'code' | 'assessed' | 'mastery'

export interface Outcome {
  id: number | string
  code: string
  name: string
  description: string
  assessedAlignmentsCount: number
  totalAlignmentsCount: number
  masteryScore: number | null
  masteryLevel: MasteryLevel
}
