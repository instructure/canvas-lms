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

// For new Speedgrader, corresponding type is in its repo in
// apps/speedgrader/src/types/GetSubmissionResultLtiAssetReport.ts
export const LTI_ASSET_REPORT_PROCESSING_PROGRESSES = [
  'Processed',
  'Processing',
  'Pending',
  'PendingManual',
  'Failed',
  'NotProcessed',
  'NotReady',
] as const
export const ZLtiAssetReportProcessingProgress = z.enum(LTI_ASSET_REPORT_PROCESSING_PROGRESSES)
export type LtiAssetReportProcessingProgress = z.infer<typeof ZLtiAssetReportProcessingProgress>

// Can update this when zod is updated to allow z.literal(ARRAY): https://github.com/colinhacks/zod/issues/2686
const ZLtiAssetReportPriority = z.union([
  z.literal(0),
  z.literal(1),
  z.literal(2),
  z.literal(3),
  z.literal(4),
  z.literal(5),
])

/**
 * Asset Report information, as shown e.g. in Speedgrader
 */
export const ZLtiAssetReport = z.object({
  _id: z.number(),
  comment: z.string().optional(),
  errorCode: z.string().optional(),
  indicationAlt: z.string().optional(),
  indicationColor: z.string().optional(),
  launchUrlPath: z.string().optional(),
  priority: ZLtiAssetReportPriority,
  processingProgress: ZLtiAssetReportProcessingProgress,
  reportType: z.string(),
  resubmitAvailable: z.boolean(),
  result: z.string().optional(),
  resultTruncated: z.string().optional(),
  title: z.string().optional(),
})
export type LtiAssetReport = z.infer<typeof ZLtiAssetReport>

export const ZLtiAssetReportsByProcessor = z.record(z.string(), z.array(ZLtiAssetReport))

export type LtiAssetReportsByProcessor = z.infer<typeof ZLtiAssetReportsByProcessor>

export type LtiAssetReportWithAsset = LtiAssetReport & {
  asset_processor_id: number
  asset: {
    id: number
    attachment_id: string | null
    attachment_name: string | null
    submission_id: string
    submission_attempt: string | null
  }
}
