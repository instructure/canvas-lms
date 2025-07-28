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

import {useMemo} from 'react'
import type {GradebookQueryResponse} from '../../types/queries'
import {useAssignmentGroupsQuery} from './useAssignmentGroupsQuery'
import {useAssignmentsQuery} from './useAssignmentsQuery'
import {useEnrollmentsQuery} from './useEnrollmentsQuery'
import {useSectionsQuery} from './useSectionsQuery'
import {useSubmissionsQuery} from './useSubmissionsQuery'
import {useOutcomesQuery} from './useOutcomesQuery'
import {useCourseOutcomeMasteryScales} from './useCourseOutcomeMasteryScales'

export const useGradebookQuery = (courseId: string) => {
  const {enrollments, enrollmentsLoading, enrollmentsSuccessful} = useEnrollmentsQuery(courseId)

  const {sections, sectionsLoading, sectionsSuccessful} = useSectionsQuery(courseId)

  const {outcomes, outcomesLoading, outcomesSuccessful} = useOutcomesQuery(courseId)

  const {
    outcomeCalculationMethod,
    outcomeProficiency,
    courseOutcomeMasteryScalesLoading,
    courseOutcomeMasteryScalesSuccessful,
  } = useCourseOutcomeMasteryScales(courseId)

  const {submissions, submissionsLoading, submissionsSuccessful} = useSubmissionsQuery(courseId)

  const {assignmentGroups, assignmentGroupsLoading, assignmentGroupsSuccessful} =
    useAssignmentGroupsQuery(courseId)

  const {assignments, assignmentsLoading, assignmentsSuccessful} = useAssignmentsQuery(courseId)

  const isSuccess =
    enrollmentsSuccessful &&
    sectionsSuccessful &&
    outcomesSuccessful &&
    submissionsSuccessful &&
    assignmentGroupsSuccessful &&
    assignmentsSuccessful &&
    courseOutcomeMasteryScalesSuccessful
  const isLoading =
    enrollmentsLoading &&
    sectionsLoading &&
    outcomesLoading &&
    submissionsLoading &&
    assignmentGroupsLoading &&
    assignmentsLoading &&
    courseOutcomeMasteryScalesLoading

  const courseData: GradebookQueryResponse | undefined = useMemo(() => {
    if (!isSuccess) {
      return undefined
    }

    return {
      course: {
        enrollmentsConnection: {
          nodes: enrollments,
        },
        assignmentGroupsConnection: {
          nodes: assignmentGroups.map(ag => ({
            ...ag,
            assignmentsConnection: {nodes: assignments[ag.id] || []},
          })),
        },
        rootOutcomeGroup: {
          outcomes: {
            nodes: outcomes,
          },
        },
        sectionsConnection: {
          nodes: sections,
        },
        submissionsConnection: {
          nodes: submissions,
        },
        outcomeCalculationMethod,
        outcomeProficiency,
      },
    }
  }, [isSuccess, enrollments, assignmentGroups, outcomes, sections, submissions, assignments])

  return {
    courseData,
    isLoading,
    isSuccess,
  }
}
