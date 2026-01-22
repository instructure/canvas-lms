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

export interface Rating {
  points: number
  color: string
  description?: string
  mastery?: boolean
}

export interface Outcome {
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
  ratings: Rating[]
  proficiency_context_type?: string
  proficiency_context_id?: string
}

export interface Score {
  score: number
  links: {
    outcome: string | number
  }
}

export interface StudentRollup {
  scores: Score[]
  links: {
    user: string | number
    status: string
  }
}

export interface Student {
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

export interface OutcomeRollup {
  outcomeId: string | number
  score: number
  rating: Rating & {
    color: string
  }
}

export interface StudentRollupData {
  studentId: string
  outcomeRollups: OutcomeRollup[]
}

export interface Pagination {
  currentPage: number
  perPage: number
  totalPages: number
  totalCount: number
}

export interface RollupsResponse {
  data: {
    rollups: StudentRollup[]
    linked: {
      users: Student[]
      outcomes: Outcome[]
    }
    meta: {
      pagination: {
        count: number
        page: number
        page_count: number
        per_page: number
      }
    }
  }
}
