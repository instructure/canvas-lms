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

import I18n from 'i18n!k5_dashboard'
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
      `/api/v1/users/${userId}/courses?include[]=total_scores&include[]=current_grading_period_scores&include[]=grading_periods&include[]=course_image&enrollment_state=active`,
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
        currentGradingPeriodId: enrollment.current_grading_period_id,
        currentGradingPeriodTitle: enrollment.current_grading_period_title,
        enrollmentType: enrollment.type,
        gradingPeriods: hasGradingPeriods ? course.grading_periods : [],
        hasGradingPeriods,
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

export const fetchGradesForGradingPeriod = (gradingPeriodId, userId = 'self') =>
  asJson(
    window.fetch(
      `/api/v1/users/${userId}/enrollments?state[]=active&&type[]=StudentEnrollment&grading_period_id=${gradingPeriodId}`,
      defaultFetchOptions
    )
  ).then(enrollments =>
    enrollments.map(({course_id, grades}) => ({
      courseId: course_id,
      score: grades && grades.current_score,
      grade: grades && grades.current_grade
    }))
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

/* Fetches instructors for a given course - in this case an instructor is a user with
   either a Teacher or TA enrollment. */
export const fetchCourseInstructors = courseId =>
  asJson(
    window.fetch(
      `/api/v1/courses/${courseId}/users?enrollment_type[]=teacher&enrollment_type[]=ta&include[]=avatar_url&include[]=bio&include[]=enrollments`,
      defaultFetchOptions
    )
  )

export const readableRoleName = role => {
  const ROLES = {
    TeacherEnrollment: I18n.t('Teacher'),
    TaEnrollment: I18n.t('Teaching Assistant'),
    DesignerEnrollment: I18n.t('Designer'),
    StudentEnrollment: I18n.t('Student'),
    StudentViewEnrollment: I18n.t('Student'),
    ObserverEnrollment: I18n.t('Observer')
  }
  // Custom roles return as named
  return ROLES[role] || role
}
