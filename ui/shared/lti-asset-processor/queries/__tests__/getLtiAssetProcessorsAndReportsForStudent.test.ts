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

// This test relies on types from codegen, generated with "yarn run graphql:codegen":
// It makes sure the Zod types we use actually correspond to the GraphQL queries.
import {LtiAssetReportsForStudentQuery} from '@canvas/graphql/codegen/graphql'
import {
  GetLtiAssetProcessorsAndReportsForStudentResult,
  ZGetLtiAssetProcessorsAndReportsForStudentResult,
} from '../getLtiAssetProcessorsAndReportsForStudent'
import {defaultGetLtiAssetProcessorsAndReportsForStudentResult} from '../__fixtures__/LtiAssetProcessorsAndReportsForStudent'

type DeepNonNullable<T> = T extends object
  ? {[K in keyof T]-?: DeepNonNullable<NonNullable<T[K]>>}
  : NonNullable<T>
type DeepRequired<T> = T extends object
  ? {[K in keyof T]-?: DeepRequired<NonNullable<T[K]>>}
  : NonNullable<T>

describe('GetLtiAssetProcessorsAndReportsForStudentResult', () => {
  const zodQuery: DeepRequired<DeepNonNullable<GetLtiAssetProcessorsAndReportsForStudentResult>> = {
    __typename: 'Query',
    submission: {
      __typename: 'Submission',
      attempt: 1,
      ltiAssetReportsConnection: {
        __typename: 'LtiAssetReportConnection',
        nodes: [
          {
            __typename: 'LtiAssetReport',
            _id: '1234',
            comment: 'comment for Student OK Report',
            errorCode: '',
            indicationAlt: '',
            indicationColor: '',
            launchUrlPath: '/launch/report/1234',
            priority: 1,
            processingProgress: 'Processed',
            processorId: '2000',
            resubmitAvailable: false,
            result: '',
            resultTruncated: '',
            title: 'Student OK Report',
            asset: {
              __typename: 'LtiAsset',
              attachmentId: '',
              attachmentName: '',
              submissionAttempt: 1,
            },
          },
        ],
      },
      assignment: {
        __typename: 'Assignment',
        name: 'Test Assignment',
        ltiAssetProcessorsConnection: {
          __typename: 'LtiAssetProcessorConnection',
          nodes: [
            {
              __typename: 'LtiAssetProcessor',
              _id: '2000',
              title: 'StudentAssetProcessor1',
              iconOrToolIconUrl: '',
              externalTool: {
                __typename: 'ExternalTool',
                _id: '223',
                name: 'StudentTool1',
                labelFor: 'StudentToolTitle1',
              },
            },
          ],
        },
      },
    },
  }

  it('defines a zod schema compatible with the GraphQL type', () => {
    // Most of the magic in this test is in the Typescript checking.
    // This test relies on types from codegen, generated with "yarn run graphql:codegen"
    const codegenQuery: DeepRequired<DeepNonNullable<LtiAssetReportsForStudentQuery>> = zodQuery
    const zodQuery2: DeepRequired<
      DeepNonNullable<GetLtiAssetProcessorsAndReportsForStudentResult>
    > = codegenQuery
    const looseZodQuery: GetLtiAssetProcessorsAndReportsForStudentResult = zodQuery2
    const looseCodegenQuery: LtiAssetReportsForStudentQuery = looseZodQuery
    const looseZodQuery2: GetLtiAssetProcessorsAndReportsForStudentResult = looseCodegenQuery

    // Also, parsed query should be compatible with the GraphQL type, and all fields should be present
    const zodParsed = ZGetLtiAssetProcessorsAndReportsForStudentResult.parse(zodQuery)
    const zodParsedOfCodegenType: LtiAssetReportsForStudentQuery = zodParsed

    expect(zodParsedOfCodegenType).toEqual(looseZodQuery2)
  })
})
