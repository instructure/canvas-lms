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

import {useQuery} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import type {CourseOption, CourseGrade} from '../types'
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {COURSE_GRADES_WIDGET, QUERY_CONFIG} from '../constants'

interface UserEnrollment {
  course: {
    _id: string
    name: string
    courseCode?: string
  }
  updatedAt?: string
  grades?: {
    currentScore?: number | null
    currentGrade?: string | null
    finalScore?: number | null
    finalGrade?: string | null
    overrideScore?: number | null
    overrideGrade?: string | null
  } | null
}

interface GraphQLResponse {
  legacyNode: {
    _id: string
    enrollments: UserEnrollment[]
  }
}

const USER_COURSES_WITH_GRADES_QUERY = gql`
  query GetUserCoursesWithGrades($userId: ID!) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollments {
          course {
            _id
            name
            courseCode
          }
          updatedAt
          grades {
            currentScore
            currentGrade
            finalScore
            finalGrade
            overrideScore
            overrideGrade
          }
        }
      }
    }
  }
`

export function useUserCourses() {
  return useQuery({
    ...createUserQueryConfig(['userCourses'], QUERY_CONFIG.STALE_TIME.COURSES),
    queryFn: async (): Promise<CourseOption[]> => {
      const currentUserId = getCurrentUserId()

      const result = await executeGraphQLQuery<GraphQLResponse>(USER_COURSES_WITH_GRADES_QUERY, {
        userId: currentUserId,
      })

      if (!result.legacyNode?.enrollments) {
        return []
      }

      return result.legacyNode.enrollments.map(enrollment => ({
        id: enrollment.course._id,
        name: enrollment.course.name,
      }))
    },
  })
}

export function useUserCoursesWithGrades() {
  return useQuery({
    ...createUserQueryConfig(['userCoursesWithGrades'], QUERY_CONFIG.STALE_TIME.GRADES),
    queryFn: async (): Promise<CourseGrade[]> => {
      const currentUserId = getCurrentUserId()

      const result = await executeGraphQLQuery<GraphQLResponse>(USER_COURSES_WITH_GRADES_QUERY, {
        userId: currentUserId,
      })

      if (!result.legacyNode?.enrollments) {
        return []
      }

      return result.legacyNode.enrollments.map(enrollment => {
        const grades = enrollment.grades

        // Determine the display grade - prioritize override, then final, then current
        let displayGrade: number | null = null
        let displayGradeString: string | null = null

        if (grades?.overrideScore !== null && grades?.overrideScore !== undefined) {
          displayGrade = grades.overrideScore
          displayGradeString = grades.overrideGrade || null
        } else if (grades?.finalScore !== null && grades?.finalScore !== undefined) {
          displayGrade = grades.finalScore
          displayGradeString = grades.finalGrade || null
        } else if (grades?.currentScore !== null && grades?.currentScore !== undefined) {
          displayGrade = grades.currentScore
          displayGradeString = grades.currentGrade || null
        }

        return {
          courseId: enrollment.course._id,
          courseCode: enrollment.course.courseCode || COURSE_GRADES_WIDGET.DEFAULT_COURSE_CODE,
          courseName: enrollment.course.name,
          currentGrade: displayGrade,
          gradingScheme: displayGradeString
            ? COURSE_GRADES_WIDGET.GRADING_SCHEMES.LETTER
            : COURSE_GRADES_WIDGET.GRADING_SCHEMES.PERCENTAGE,
          lastUpdated: new Date(enrollment.updatedAt || new Date().toISOString()),
        }
      })
    },
  })
}
