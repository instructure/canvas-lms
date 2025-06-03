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

import {executeQuery} from '@canvas/graphql'
import {useScope as createI18nScope} from '@canvas/i18n'
import {gql} from '@apollo/client'

const I18n = createI18nScope('differentiated_modules')

const QUERY = gql`
  query Selective_Release_GetStudentsQuery($courseId: ID!, $cursor: String) {
    __typename
    legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        id
        name
        enrollmentsConnection(
          filter: {types: StudentEnrollment, states: [invited, active]}
          first: 100
          after: $cursor
        ) {
          edges {
            cursor
            node {
              user {
                id: _id
                name
                sisId
              }
            }
          }
        }
      }
    }
  }
`

interface EnrollmentEdge {
  cursor: string
  node: {
    user: {
      id: string
      name: string
      sisID: string
    }
  }
}

interface EnrollmentsConnection {
  edges: EnrollmentEdge[]
}

interface LegacyNode {
  enrollmentsConnection: EnrollmentsConnection
}

interface QueryResult {
  legacyNode: LegacyNode
  errors?: any
}

const fetchAllPages = async (
  courseId: string,
  cursor: string | null = null,
  combinedResults: any[] = [],
): Promise<any[]> => {
  const result: QueryResult = await executeQuery(QUERY, {courseId, cursor})

  if (result?.errors) {
    throw new Error(I18n.t('Failed to load students data'))
  }

  combinedResults.push(...(result?.legacyNode?.enrollmentsConnection?.edges || []))

  if (result?.legacyNode?.enrollmentsConnection?.edges?.length === 100) {
    const lastCursor = result.legacyNode.enrollmentsConnection.edges.slice(-1)[0]?.cursor || null
    return fetchAllPages(courseId, lastCursor, combinedResults)
  }

  return combinedResults
}

export const getStudentsByCourse = async ({
  courseId,
}: {
  courseId: string
}): Promise<Array<{id: string; value: string; sisID: string; group: string}>> => {
  const combinedResults = await fetchAllPages(courseId)

  return combinedResults
    .map((edge: any) => ({
      id: `student-${edge.node.user.id}`,
      value: edge.node.user.name,
      sisID: edge.node.user.sisId,
      group: I18n.t('Students'),
    }))
    .sort((a, b) => a.value.localeCompare(b.value))
}
