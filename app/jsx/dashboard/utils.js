/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {asJson, defaultFetchOptions} from '@instructure/js-utils'

export const countByCourseId = arr =>
  arr.reduce((acc, {course_id}) => {
    if (!acc[course_id]) {
      acc[course_id] = 0
    }
    acc[course_id]++
    return acc
  }, {})

export const fetchGrades = (userId = 'self') =>
  asJson(
    window.fetch(
      `/api/v1/users/${userId}/courses?include[]=total_scores&include[]=current_grading_period_scores&include[]=course_image&enrollment_type=student&enrollment_state=active`,
      defaultFetchOptions
    )
  ).then(courses =>
    courses.map(course => {
      // Grades are the same across all enrollments, just look at first one
      const hasGradingPeriods = course.has_grading_periods
      const enrollment = course.enrollments[0]
      return {
        courseId: course.id,
        courseName: course.name,
        courseImage: course.image_download_url,
        hasGradingPeriods,
        enrollment,
        score: hasGradingPeriods
          ? enrollment.current_period_computed_current_score
          : enrollment.computed_current_score,
        grade: hasGradingPeriods
          ? enrollment.current_period_computed_current_grade
          : enrollment.computed_current_grade,
        isHomeroom: course.homeroom_course
      }
    })
  )

export const fetchLatestAnnouncement = courseId =>
  asJson(
    window.fetch(
      `/api/v1/announcements?context_codes=course_${courseId}&active_only=true&per_page=1`,
      defaultFetchOptions
    )
  ).then(data => {
    if (data?.length > 0) {
      return data[0]
    }
    return null
  })

export const fetchMissingAssignments = (userId = 'self') =>
  asJson(
    window.fetch(
      `/api/v1/users/${userId}/missing_submissions?filter[]=submittable`,
      defaultFetchOptions
    )
  )
