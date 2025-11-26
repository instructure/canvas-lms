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
import {
  SpeedGrader_LtiAssetReportsQueryQuery,
  LtiAssetReportForStudentFragment,
  SpeedGrader_LtiAssetProcessorsQueryQuery,
  LtiAssetProcessorFragmentFragment,
} from '@canvas/graphql/codegen/graphql'
import {
  GetLtiAssetProcessorsResult,
  GetLtiAssetReportsResult,
  LtiAssetProcessor,
  LtiAssetReportForStudent,
  ZGetLtiAssetProcessorsResult,
  ZGetLtiAssetReportsResult,
  ZLtiAssetReportForStudent,
} from '../LtiAssetReport'

type DeepNonNullable<T> = T extends object
  ? {[K in keyof T]-?: DeepNonNullable<NonNullable<T[K]>>}
  : NonNullable<T>
type DeepRequired<T> = T extends object
  ? {[K in keyof T]-?: DeepRequired<NonNullable<T[K]>>}
  : NonNullable<T>

describe('GetLtiAssetReportsResult', () => {
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
              discussionEntryVersion: {
                __typename: 'DiscussionEntryVersion',
                _id: 'dev-1',
                messageIntro: 'Test discussion entry message',
                createdAt: '2023-01-01T00:00:00Z',
              },
            },
            comment: '',
            errorCode: '',
            indicationAlt: '',
            indicationColor: '',
            launchUrlPath: '',
            processorId: '',
            resubmitAvailable: false,
            result: '',
            resultTruncated: '',
            title: '',
          },
        ],
        pageInfo: {
          hasNextPage: false,
          __typename: 'PageInfo',
        },
      },
    },
  }

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

describe('LtiAssetReportForStudent', () => {
  const zodReport: DeepRequired<DeepNonNullable<LtiAssetReportForStudent>> = {
    __typename: 'LtiAssetReport',
    _id: '1',
    processingProgress: 'Processed',
    priority: 0,
    asset: {
      __typename: 'LtiAsset',
      attachmentId: 'attachment-1',
      attachmentName: 'file.pdf',
      submissionAttempt: 1,
      discussionEntryVersion: {
        __typename: 'DiscussionEntryVersion',
        _id: 'dev-2',
        messageIntro: 'Test discussion entry message for student',
        createdAt: '2023-01-01T00:00:00Z',
      },
    },
    comment: '',
    errorCode: '',
    indicationAlt: '',
    indicationColor: '',
    launchUrlPath: '',
    processorId: '',
    resubmitAvailable: false,
    result: '',
    resultTruncated: '',
    title: '',
  }

  type Codegen_LtiAssetReportFromSpeedGraderQuery = NonNullable<
    NonNullable<
      NonNullable<SpeedGrader_LtiAssetReportsQueryQuery['submission']>['ltiAssetReportsConnection']
    >['nodes']
  >[number]
  type ExpectedLtiAssetReportType = NonNullable<Codegen_LtiAssetReportFromSpeedGraderQuery> & {
    asset?: {
      attachmentName?: string | null
    }
  }

  it('defines a zod schema compatible with the GraphQL type for students', () => {
    // Most of the magic in this test is in the Typescript checking.
    // This test relies on types from codegen, generated with "yarn run graphql:codegen"
    const codegenReport: DeepRequired<DeepNonNullable<LtiAssetReportForStudentFragment>> = zodReport
    const zodReport2: DeepRequired<DeepNonNullable<LtiAssetReportForStudent>> = codegenReport
    const looseZodReport: LtiAssetReportForStudent = zodReport2
    const looseCodegenReport: LtiAssetReportForStudentFragment = looseZodReport
    const looseZodReport2: LtiAssetReportForStudent = looseCodegenReport

    // Also, parsed report should be compatible with the GraphQL type, and all fields should be present
    const zodParsed = ZLtiAssetReportForStudent.parse(zodReport)
    const zodParsedOfCodegenType: LtiAssetReportForStudentFragment = zodParsed

    expect(zodParsedOfCodegenType).toEqual(looseZodReport2)
  })

  it('is the same as the teacher query but with attachmentName added to asset', () => {
    // This is the exact same test as above with
    // Codegen_LtiAssetReportForStudent replaced with
    // ExpectedLtiAssetReportType
    const expectedReport: DeepRequired<DeepNonNullable<ExpectedLtiAssetReportType>> = zodReport
    const zodReport2: DeepRequired<DeepNonNullable<LtiAssetReportForStudent>> = expectedReport
    const looseZodReport: LtiAssetReportForStudent = zodReport2
    const looseExpectedReport: ExpectedLtiAssetReportType = looseZodReport
    const looseZodReport2: LtiAssetReportForStudent = looseExpectedReport

    // Also, parsed report should be compatible with the GraphQL type, and all fields should be present
    const zodParsed = ZLtiAssetReportForStudent.parse(zodReport)
    const zodParsedOfExpectedType: ExpectedLtiAssetReportType = zodParsed

    expect(zodParsedOfExpectedType).toEqual(looseZodReport2)
  })
})

describe('GetLtiAssetProcessorsResult', () => {
  const zodQuery: DeepRequired<DeepNonNullable<GetLtiAssetProcessorsResult>> = {
    __typename: 'Query',
    assignment: {
      __typename: 'Assignment',
      ltiAssetProcessorsConnection: {
        __typename: 'LtiAssetProcessorConnection',
        nodes: [
          {
            __typename: 'LtiAssetProcessor',
            _id: '1',
            title: 'ap 1',
            iconOrToolIconUrl: 'http://example.com/icon.png',
            externalTool: {
              _id: '',
              name: 'tool 1',
              labelFor: 'tool 1 label',
              __typename: 'ExternalTool',
            },
          },
        ],
      },
    },
  }

  it('defines a zod schema compatible with the GraphQL type', () => {
    // Most of the magic in this test is in the Typescript checking.
    // This test relies on types from codegen, generated with "yarn run graphql:codegen"
    const sgQuery: DeepRequired<DeepNonNullable<SpeedGrader_LtiAssetProcessorsQueryQuery>> =
      zodQuery
    const zodQuery2: DeepRequired<DeepNonNullable<GetLtiAssetProcessorsResult>> = sgQuery
    const looseZodQuery: GetLtiAssetProcessorsResult = zodQuery2
    const looseSgQuery: SpeedGrader_LtiAssetProcessorsQueryQuery = looseZodQuery
    const looseZodQuery2: GetLtiAssetProcessorsResult = looseSgQuery

    // Also, parsed query should be compatible with the GraphQL type, and all fields should be present
    const zodParsed = ZGetLtiAssetProcessorsResult.parse(zodQuery)
    const zodParsedOfSgType: SpeedGrader_LtiAssetProcessorsQueryQuery = zodParsed

    expect(zodParsedOfSgType).toEqual(looseZodQuery2)
  })

  it('defines a zod schema compatible with the GraphQL Fragment type', () => {
    const graphqlFragment: DeepRequired<LtiAssetProcessorFragmentFragment> =
      zodQuery.assignment.ltiAssetProcessorsConnection.nodes[0]
    const zodProc: DeepRequired<DeepNonNullable<LtiAssetProcessor>> = graphqlFragment
    const looseZodProc: LtiAssetProcessor = zodProc
    const looseGraphqlFragment: LtiAssetProcessorFragmentFragment = looseZodProc
    const looseZodProc2: LtiAssetProcessor = looseGraphqlFragment
    expect(looseZodProc2).toEqual(graphqlFragment)
  })
})
