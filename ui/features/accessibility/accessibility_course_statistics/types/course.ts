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

// Types specific to the /api/v1/accounts/:id/courses endpoint response
// Note: ui/api.d.ts has generic Course/Term types but they don't match
// the specific fields returned by this endpoint with our include[] params

export interface Term {
  name: string
}

export interface Teacher {
  id: string
  display_name: string
  html_url: string
  avatar_image_url?: string
}

export interface Course {
  id: string
  name: string
  workflow_state: 'unpublished' | 'available' | 'completed' | 'deleted'
  sis_course_id?: string
  total_students?: number
  teachers?: Teacher[]
  term?: Term
  subaccount_id?: string
  subaccount_name?: string
}

export interface CoursesResponse {
  courses: Course[]
}
