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

import {gql} from '@apollo/client'
import {z} from 'zod'
import {LTI_ASSET_PROCESSORS_QUERY_NODES_FRAGMENT} from '../shared-with-sg/replicated/queries/getLtiAssetProcessors'
import {LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT} from '../shared-with-sg/replicated/queries/getLtiAssetReports'
import {
  zGqlConnection,
  zGqlObj,
  ZLtiAssetProcessor,
  ZLtiAssetReportForStudent,
  zNullishGqlObj,
} from '../model/LtiAssetReport'

export const COURSE_ASSIGNMENTS_ASSET_REPORTS_QUERY = gql`
  query GetCourseAssignmentsAssetReports(
    $courseID: ID!
    $gradingPeriodID: ID
    $studentId: ID!
    $after: String
  ) {
    legacyNode(_id: $courseID, type: Course) {
      ... on Course {
        assignmentsConnection(
          filter: {gradingPeriodId: $gradingPeriodID, userId: $studentId}
          after: $after
        ) {
          nodes {
            _id
            name
            ltiAssetProcessorsConnection {
              nodes { ...LtiAssetProcessorFragment }
            }
            submissionsConnection(filter: {userId: $studentId, includeUnsubmitted: true}) {
              nodes {
                _id
                submissionType
                ltiAssetReportsConnection(first: 10, latest: true) {
                  nodes { ...LtiAssetReportForStudent }
                }
              }
            }
          }
          pageInfo {
            endCursor
            hasPreviousPage
            hasNextPage
            startCursor
          }
        }
      }
    }
  }
  ${LTI_ASSET_PROCESSORS_QUERY_NODES_FRAGMENT}
  ${LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT}
`
// This needs to be kept up to date with the GraphQL Codegen SubmissionType,
// which eventually comes from app/graphql/types/assignment_submission_type.rb
export const ZSubmissionType = z.enum([
  'attendance',
  'basic_lti_launch',
  'discussion_topic',
  'external_tool',
  'media_recording',
  'none',
  'not_graded',
  'on_paper',
  'online_quiz',
  'online_text_entry',
  'online_upload',
  'online_url',
  'peer_review',
  'student_annotation',
  'wiki_page',
])

export const ZGetCourseAssignmentsAssetReportsResult = zGqlObj('Query', {
  legacyNode: zNullishGqlObj('Course', {
    assignmentsConnection: zGqlObj('AssignmentConnection', {
      nodes: z
        .array(
          zGqlObj('Assignment', {
            _id: z.string(),
            name: z.string().nullish(),
            ltiAssetProcessorsConnection: zGqlConnection(
              'LtiAssetProcessorConnection',
              ZLtiAssetProcessor,
            ),
            submissionsConnection: zGqlConnection(
              'SubmissionConnection',
              zGqlObj('Submission', {
                _id: z.string(),
                submissionType: ZSubmissionType.nullish(),
                ltiAssetReportsConnection: zGqlConnection(
                  'LtiAssetReportConnection',
                  ZLtiAssetReportForStudent,
                ),
              }),
            ),
          }).nullable(),
        )
        .nullish(),
      pageInfo: z.object({
        __typename: z.literal('PageInfo').optional(),
        endCursor: z.string().nullish(),
        hasPreviousPage: z.boolean(),
        hasNextPage: z.boolean(),
        startCursor: z.string().nullish(),
      }),
    }),
  }),
})

export type GetCourseAssignmentsAssetReportsResult = z.infer<
  typeof ZGetCourseAssignmentsAssetReportsResult
>
