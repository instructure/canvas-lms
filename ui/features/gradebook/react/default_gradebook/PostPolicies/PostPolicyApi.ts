// @ts-nocheck
/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {createClient, gql} from '@canvas/apollo'

export const SET_COURSE_POST_POLICY_MUTATION = gql`
  mutation SetCoursePostPolicy($courseId: ID!, $postManually: Boolean!) {
    setCoursePostPolicy(input: {courseId: $courseId, postManually: $postManually}) {
      postPolicy {
        postManually
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const COURSE_ASSIGNMENT_POST_POLICIES_QUERY = gql`
  query CourseAssignmentPostPolicies($courseId: ID!) {
    course(id: $courseId) {
      assignmentsConnection(filter: {gradingPeriodId: null}) {
        nodes {
          _id
          postPolicy {
            postManually
          }
        }
      }
    }
  }
`

export function setCoursePostPolicy({
  courseId,
  postManually,
}: {
  courseId: string
  postManually: boolean
}) {
  return createClient()
    .mutate({
      mutation: SET_COURSE_POST_POLICY_MUTATION,
      variables: {
        courseId,
        postManually,
      },
    })
    .then(response => {
      const queryResponse = response && response.data && response.data.setCoursePostPolicy
      if (queryResponse) {
        if (queryResponse.postPolicy) {
          return {
            postManually: queryResponse.postPolicy.postManually,
          }
        } else if (queryResponse.errors && queryResponse.errors.length > 0) {
          throw new Error(queryResponse.errors[0].message)
        }
      }

      throw new Error('no postPolicy or error provided in response')
    })
}

export function getAssignmentPostPolicies({courseId}: {courseId: string}) {
  return createClient()
    .query({
      query: COURSE_ASSIGNMENT_POST_POLICIES_QUERY,
      variables: {courseId},
    })
    .then(response => {
      const queryResponse = response && response.data && response.data.course
      if (queryResponse) {
        const assignments = queryResponse.assignmentsConnection.nodes
        if (assignments != null) {
          const assignmentPostPoliciesById = {}
          assignments.forEach(assignment => {
            if (assignment.postPolicy) {
              const {postManually} = assignment.postPolicy
              assignmentPostPoliciesById[assignment._id] = {postManually}
            }
          })

          return {assignmentPostPoliciesById}
        }
      }

      throw new Error('no course provided in response')
    })
}
