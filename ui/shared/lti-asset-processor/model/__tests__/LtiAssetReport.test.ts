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
import {SpeedGrader_LtiAssetReportsQueryQuery} from '@canvas/graphql/codegen/graphql'
import {GetLtiAssetReportsResult, ZGetLtiAssetReportsResult} from '../LtiAssetReport'

type DeepNonNullable<T> = T extends object
  ? {[K in keyof T]-?: DeepNonNullable<NonNullable<T[K]>>}
  : NonNullable<T>
type DeepRequired<T> = T extends object
  ? {[K in keyof T]-?: DeepRequired<NonNullable<T[K]>>}
  : NonNullable<T>

const zodQuery: DeepRequired<DeepNonNullable<GetLtiAssetReportsResult>> = {
  __typename: 'Query',
  submission: {
    __typename: 'Submission',
    ltiAssetReportsConnection: {
      __typename: 'LtiAssetReportConnection',
      nodes: [
        {
          __typename: 'LtiAssetReport',
          _id: '1',
          processingProgress: 'Processed',
          priority: 0,
          asset: {
            __typename: 'LtiAsset',
            attachmentId: 'attachment-1',
            submissionAttempt: 1,
          },
          comment: '',
          errorCode: '',
          indicationAlt: '',
          indicationColor: '',
          launchUrlPath: '',
          processorId: '',
          reportType: '',
          resubmitAvailable: false,
          result: '',
          resultTruncated: '',
          title: '',
        },
      ],
    },
  },
}

describe('GetLtiAssetReportsResult', () => {
  it('defines a zod schema compatible with the GraphQL type', () => {
    // Most of the magic in this test is in the Typescript checking.
    // This test relies on types from codegen, generated with "yarn run graphql:codegen"
    const sgQuery: DeepRequired<DeepNonNullable<SpeedGrader_LtiAssetReportsQueryQuery>> = zodQuery
    const zodQuery2: DeepRequired<DeepNonNullable<GetLtiAssetReportsResult>> = sgQuery
    const looseZodQuery: GetLtiAssetReportsResult = zodQuery2
    const looseSgQuery: SpeedGrader_LtiAssetReportsQueryQuery = looseZodQuery
    const looseZodQuery2: GetLtiAssetReportsResult = looseSgQuery

    // Also, parsed query should be compatible with the GraphQL type, and all fields should be present
    const zodParsed = ZGetLtiAssetReportsResult.parse(zodQuery)
    const zodParsedOfSgType: SpeedGrader_LtiAssetReportsQueryQuery = zodParsed

    expect(zodParsedOfSgType).toEqual(looseZodQuery2)
  })
})
