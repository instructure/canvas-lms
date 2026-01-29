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

/**
 * Environment data for usage metrics.
 */

export interface EnvUsageMetrics {
  USAGE_METRICS_METADATA: {
    sub_account_id?: string
    sub_account_name?: string
    course_id?: string
    course_long_name?: string
    course_sis_source_id?: string | null
    course_sis_batch_id?: string | null
    course_enrollment_term_id?: string | null
  }
}
