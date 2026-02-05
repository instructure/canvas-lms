/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {Student} from './rollup'

export interface RatingDistribution {
  description: string
  points: number
  color: string
  count: number
  student_ids: string[]
}

export interface AlignmentDistribution {
  alignment_id: string
  ratings: RatingDistribution[]
  total_students: number
}

export interface OutcomeDistribution {
  outcome_id: string
  ratings: RatingDistribution[]
  total_students: number
  alignment_distributions?: Record<string, AlignmentDistribution>
}

export interface MasteryDistributionResponse {
  outcome_distributions: Record<string, OutcomeDistribution>
  students: Student[]
}
