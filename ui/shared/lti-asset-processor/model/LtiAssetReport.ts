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

export const ZLtiAssetReports = z.array(ZLtiAssetReport.nullable())
export type LtiAssetReports = z.infer<typeof ZLtiAssetReports>

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
export const ZLtiAssetProcessor: z.ZodType<{
  _id: string
  title: string | null
  iconOrToolIconUrl: string | null
  externalTool: {
    _id: string
    name: string
    labelFor: string | null
  }
}> = z
  .object({
    _id: z.string(),
    title: z.string().nullable(),
    iconOrToolIconUrl: z.string().nullable(),
    externalTool: z.object({
      _id: z.string(),
      name: z.string(),
      labelFor: z.string().nullable(),
    }),
  })
  .strict()

export type LtiAssetProcessor = z.infer<typeof ZLtiAssetProcessor>

export const ZLtiAssetProcessors: z.ZodType<Array<LtiAssetProcessor>> = z.array(ZLtiAssetProcessor)
export type LtiAssetProcessors = z.infer<typeof ZLtiAssetProcessors>

export const ZGetLtiAssetProcessorsResult: z.ZodType<{
  assignment: {
    ltiAssetProcessorsConnection: {
      nodes: LtiAssetProcessors
    }
  }
}> = z
  .object({
    assignment: z.object({
      ltiAssetProcessorsConnection: z.object({
        nodes: ZLtiAssetProcessors,
      }),
    }),
  })
  .strict()

export type GetLtiAssetProcessorsResult = z.infer<typeof ZGetLtiAssetProcessorsResult>
