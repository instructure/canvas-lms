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

const ZLtiAssetReportProcessingProgress = z.string()

// Can update this when zod is updated to allow z.literal(ARRAY): https://github.com/colinhacks/zod/issues/2686
const ZLtiAssetReportPriority = z.number()

const ZLtiAsset = z
  .object({
    __typename: z.literal('LtiAsset').optional(),
    attachmentId: z.string().nullable().optional(),
    submissionAttempt: z.number().nullable().optional(),
  })
  .strict()
export type LtiAsset = z.infer<typeof ZLtiAsset>

/**
 * Asset Report information, as shown e.g. in Speedgrader
 * Corresponds to object used in LTI_ASSET_REPORTS_QUERY
 */
export const ZLtiAssetReport = z
  .object({
    __typename: z.literal('LtiAssetReport').optional(),
    _id: z.string(),
    comment: z.string().nullable().optional(),
    errorCode: z.string().nullable().optional(),
    indicationAlt: z.string().nullable().optional(),
    indicationColor: z.string().nullable().optional(),
    launchUrlPath: z.string().nullable().optional(),
    priority: ZLtiAssetReportPriority,
    processingProgress: ZLtiAssetReportProcessingProgress,
    processorId: z.string(),
    reportType: z.string(),
    resubmitAvailable: z.boolean(),
    result: z.string().nullable().optional(),
    resultTruncated: z.string().nullable().optional(),
    title: z.string().nullable().optional(),
    asset: ZLtiAsset,
  })
  .strict()

export type LtiAssetReport = z.infer<typeof ZLtiAssetReport>

/**
 * Corresponds to LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT
 */
export const ZLtiAssetReportForStudent = ZLtiAssetReport.extend({
  asset: ZLtiAsset.extend({attachmentName: z.string().nullable().optional()}),
})
export type LtiAssetReportForStudent = z.infer<typeof ZLtiAssetReportForStudent>

export const ZLtiAssetReports = z.array(ZLtiAssetReport.nullable())
export type LtiAssetReports = z.infer<typeof ZLtiAssetReports>

/**
 * Corresponds to the result of LTI_ASSET_REPORTS_QUERY
 */
export const ZGetLtiAssetReportsResult = z
  .object({
    __typename: z.literal('Query').optional(),
    submission: z
      .object({
        __typename: z.literal('Submission').optional(),
        ltiAssetReportsConnection: z
          .object({
            __typename: z.literal('LtiAssetReportConnection').optional(),
            nodes: ZLtiAssetReports.nullable().optional(),
          })
          .nullable()
          .optional(),
      })
      .nullable()
      .optional(),
  })
  .strict()

export type GetLtiAssetReportsResult = z.infer<typeof ZGetLtiAssetReportsResult>
/**
 * An LtiAssetProcessor as returned by our GraphQL query.
 */
export const ZLtiAssetProcessor = z
  .object({
    __typename: z.literal('LtiAssetProcessor').optional(),
    _id: z.string(),
    title: z.string().nullable().optional(),
    iconOrToolIconUrl: z.string().nullable().optional(),
    externalTool: z.object({
      __typename: z.literal('ExternalTool').optional(),
      _id: z.string(),
      name: z.string(),
      labelFor: z.string().nullable().optional(),
    }),
  })
  .strict()

export type LtiAssetProcessor = z.infer<typeof ZLtiAssetProcessor>

export const ZLtiAssetProcessors = z.array(ZLtiAssetProcessor.nullable())
export type LtiAssetProcessors = z.infer<typeof ZLtiAssetProcessors>

export const ZGetLtiAssetProcessorsResult = z
  .object({
    __typename: z.literal('Query').optional(),
    assignment: z
      .object({
        __typename: z.literal('Assignment').optional(),
        ltiAssetProcessorsConnection: z
          .object({
            __typename: z.literal('LtiAssetProcessorConnection').optional(),
            nodes: ZLtiAssetProcessors.nullable().optional(),
          })
          .nullable()
          .optional(),
      })
      .nullable()
      .optional(),
  })
  .strict()

export type GetLtiAssetProcessorsResult = z.infer<typeof ZGetLtiAssetProcessorsResult>
