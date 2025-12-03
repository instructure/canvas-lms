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

import {z} from 'zod'
import {
  zGqlConnection,
  zGqlObj,
  ZLtiAssetProcessor,
  ZLtiAssetReportForStudent,
  zNullishGqlObj,
} from '../model/LtiAssetReport'
import {LTI_ASSET_PROCESSORS_QUERY_NODES_FRAGMENT} from '../shared-with-sg/replicated/queries/getLtiAssetProcessors'
import {LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT} from '../shared-with-sg/replicated/queries/getLtiAssetReports'
import {gql} from '@apollo/client'

export const LTI_ASSET_PROCESSORS_AND_REPORTS_FOR_STUDENT_QUERY = gql`
  query LtiAssetReportsForStudent($submissionId: ID!) {
    submission(id: $submissionId) {
      attempt
      ltiAssetReportsConnection {
        nodes { ...LtiAssetReportForStudent }
      }
      assignment {
        name
        ltiAssetProcessorsConnection {
          nodes { ...LtiAssetProcessorFragment }
        }
      }
    }
  }
  ${LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT}
  ${LTI_ASSET_PROCESSORS_QUERY_NODES_FRAGMENT}
`

export const ZGetLtiAssetProcessorsAndReportsForStudentResult = zGqlObj('Query', {
  submission: zNullishGqlObj('Submission', {
    attempt: z.number(),
    ltiAssetReportsConnection: zGqlConnection(
      'LtiAssetReportConnection',
      ZLtiAssetReportForStudent,
    ),
    assignment: zGqlObj('Assignment', {
      name: z.string().nullish(),
      ltiAssetProcessorsConnection: zGqlConnection(
        'LtiAssetProcessorConnection',
        ZLtiAssetProcessor,
      ),
    }),
  }),
})
export type GetLtiAssetProcessorsAndReportsForStudentResult = z.infer<
  typeof ZGetLtiAssetProcessorsAndReportsForStudentResult
>
