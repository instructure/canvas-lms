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
    instance_domain?: string
    sub_account_id?: string
    sub_account_name?: string
    sub_account_sis_id?: string
    user_id?: string
    user_uuid?: string
    user_display_name?: string
    user_email?: string
    user_time_zone?: string
    user_sis_id?: string
    course_id?: string
    course_long_name?: string
    course_status?: string
    course_is_blueprint?: boolean
    course_is_k5?: boolean
    course_has_no_students?: boolean
    course_sis_source_id?: string
    course_sis_batch_id?: string
    course_enrollment_term_id?: string
    course_enrollment_term_name?: string
    course_enrollment_term_sis_id?: string
    course_enrollment_term_start_at?: string
    course_enrollment_term_end_at?: string
  }
}
