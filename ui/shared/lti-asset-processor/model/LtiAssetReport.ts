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

/**
 * Types used by LTI Asset Report related code, see
 * doc/lti/18_asset_reports.md for an overview of where LTI Asset Reports are
 * shown in the app.
 */

import {z} from 'zod'

export function zNullishGqlObj<S extends string, T extends z.ZodRawShape>(typeName: S, schema: T) {
  return zGqlObj(typeName, schema).nullish()
}

export function zGqlObj<S extends string, T extends z.ZodRawShape>(typeName: S, schema: T) {
  return z
    .object(schema)
    .extend({
      __typename: z.literal(typeName).optional(),
    })
    .strict()
}

export function zGqlConnection<S extends string, T extends z.ZodType>(
  connectionName: S,
  nodeSchema: T,
) {
  return zNullishGqlObj(connectionName, {
    nodes: z.array(nodeSchema.nullable()).nullish(),
  })
}

const ZLtiAssetReportProcessingProgress = z.string()

// Can update this when zod is updated to allow z.literal(ARRAY): https://github.com/colinhacks/zod/issues/2686
const ZLtiAssetReportPriority = z.number()

const ZDiscussionEntryVersion = zGqlObj('DiscussionEntryVersion', {
  _id: z.string(),
  messageIntro: z.string(),
  createdAt: z.string().nullish(),
})

const ZLtiAsset = zGqlObj('LtiAsset', {
  attachmentId: z.string().nullish(),
  submissionAttempt: z.number().nullish(),
  discussionEntryVersion: ZDiscussionEntryVersion.nullish(),
})
export type LtiAsset = z.infer<typeof ZLtiAsset>

/**
 * Asset Report information, as shown e.g. in Speedgrader
 * Corresponds to object used in LTI_ASSET_REPORTS_QUERY
 */
export const ZLtiAssetReport = z
  .object({
    __typename: z.literal('LtiAssetReport').optional(),
    _id: z.string(),
    comment: z.string().nullish(),
    errorCode: z.string().nullish(),
    indicationAlt: z.string().nullish(),
    indicationColor: z.string().nullish(),
    launchUrlPath: z.string().nullish(),
    priority: ZLtiAssetReportPriority,
    processingProgress: ZLtiAssetReportProcessingProgress,
    processorId: z.string(),
    resubmitAvailable: z.boolean(),
    result: z.string().nullish(),
    resultTruncated: z.string().nullish(),
    title: z.string().nullish(),
    asset: ZLtiAsset,
  })
  .strict()

export type LtiAssetReport = z.infer<typeof ZLtiAssetReport>

/**
 * Corresponds to LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT
 */
export const ZLtiAssetReportForStudent = ZLtiAssetReport.extend({
  asset: ZLtiAsset.extend({attachmentName: z.string().nullish()}),
})
export type LtiAssetReportForStudent = z.infer<typeof ZLtiAssetReportForStudent>

export const ZLtiAssetReports = z.array(ZLtiAssetReport.nullable())
export type LtiAssetReports = z.infer<typeof ZLtiAssetReports>

/**
 * Corresponds to the result of LTI_ASSET_REPORTS_QUERY
 */
export const ZGetLtiAssetReportsResult = z.strictObject({
  __typename: z.literal('Query').optional(),
  submission: zNullishGqlObj('Submission', {
    ltiAssetReportsConnection: zNullishGqlObj('LtiAssetReportConnection', {
      nodes: z.array(ZLtiAssetReport.nullable()).nullish(),
      pageInfo: zGqlObj('PageInfo', {
        hasNextPage: z.boolean(),
      }),
    }),
  }),
})

export type GetLtiAssetReportsResult = z.infer<typeof ZGetLtiAssetReportsResult>

/**
 * An LtiAssetProcessor as returned by our GraphQL query.
 */
export const ZLtiAssetProcessor = z.strictObject({
  __typename: z.literal('LtiAssetProcessor').optional(),
  _id: z.string(),
  title: z.string().nullish(),
  iconOrToolIconUrl: z.string().nullish(),
  externalTool: zGqlObj('ExternalTool', {
    _id: z.string(),
    name: z.string(),
    labelFor: z.string().nullish(),
  }),
})

export type LtiAssetProcessor = z.infer<typeof ZLtiAssetProcessor>

export const ZGetLtiAssetProcessorsResult = z.strictObject({
  __typename: z.literal('Query').optional(),
  assignment: zNullishGqlObj('Assignment', {
    __typename: z.literal('Assignment').optional(),
    ltiAssetProcessorsConnection: zGqlConnection('LtiAssetProcessorConnection', ZLtiAssetProcessor),
  }),
})

export type GetLtiAssetProcessorsResult = z.infer<typeof ZGetLtiAssetProcessorsResult>

export function shouldShowAssetReportCell(
  assetProcessors: LtiAssetProcessor[] | null | undefined,
  assetReports: LtiAssetReport[] | null | undefined,
): boolean {
  // Don't show if there are no processors. For asset reports,
  // note that empty array means to still show, but show "No Reports"
  // see AssetProcessorReportHelper#raw_asset_reports
  return !!assetProcessors?.length && !!assetReports
}
