/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import gql from 'graphql-tag'
import {bool, number, shape, string, arrayOf} from 'prop-types'

export function GetLinkStateDefaults() {
  const defaults = {}
  if (!window.ENV) {
    return defaults
  }

  const baseUrl = `${window.location.origin}/${ENV.context_asset_string.split('_')[0]}s/${
    ENV.context_asset_string.split('_')[1]
  }`
  defaults.assignmentUrl = `${baseUrl}/assignments`
  defaults.moduleUrl = `${baseUrl}/modules`

  if (ENV.PREREQS.items && ENV.PREREQS.items.length !== 0 && ENV.PREREQS.items[0].prev) {
    const prereq = ENV.PREREQS.items[0].prev
    defaults.modulePrereq = {
      title: prereq.title,
      link: prereq.html_url,
      __typename: 'modulePrereq'
    }
  } else {
    defaults.modulePrereq = null
  }

  return {env: {...defaults, __typename: 'env'}}
}

export const STUDENT_VIEW_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment: legacyNode(type: Assignment, _id: $assignmentLid) {
      ... on Assignment {
        description
        dueAt
        lockAt
        name
        pointsPossible
        unlockAt
        gradingType
        allowedAttempts
        assignmentGroup {
          name
        }
        env @client {
          assignmentUrl
          moduleUrl
          modulePrereq {
            title
            link
          }
        }
        lockInfo {
          isLocked
        }
        modules {
          id
          name
        }
        submissionsConnection(
          last: 1
          filter: {states: [unsubmitted, graded, pending_review, submitted]}
        ) {
          nodes {
            grade
            submissionStatus
          }
        }
      }
    }
  }
`

export const StudentAssignmentShape = shape({
  description: string.isRequired,
  dueAt: string,
  lockAt: string,
  name: string.isRequired,
  pointsPossible: number.isRequired,
  unlockAt: string,
  gradingType: string,
  allowedAttempts: number,
  assignmentGroup: shape({
    name: string.isRequired
  }).isRequired,
  env: shape({
    assignmentUrl: string.isRequired,
    moduleUrl: string.isRequired,
    modulePrereq: shape({
      title: string.isRequired,
      link: string.isRequired
    })
  }).isRequired,
  lockInfo: shape({
    isLocked: bool.isRequired
  }).isRequired,
  modules: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    }).isRequired
  ).isRequired,
  submissionsConnection: shape({
    nodes: arrayOf(
      shape({
        grade: string
      })
    ).isRequired
  }).isRequired
})
