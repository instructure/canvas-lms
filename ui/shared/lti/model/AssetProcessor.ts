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
import {ZIframeDimensions} from './common'

export const ZAssetProcessorWindowSettings = z.object({
  targetName: z.string().optional(), // Name of window to open, allows sharing a target
  width: z.number().optional(), // Width in pixels of the new window
  height: z.number().optional(), // Height in pixels of the new window
  windowFeatures: z.string().optional(), // Comma-separated list of window features for window.open()
})

/**
 * Data sent by server to show APs already attached to an existing assignment.
 * See Lti::AssetProcessors.info_for_display
 */
export const ZExistingAttachedAssetProcessor = z.object({
  id: z.number(),
  title: z.string().optional(),
  text: z.string().optional(),
  tool_id: z.number(),
  tool_name: z.string(),
  tool_placement_label: z.string().optional(),
  icon_or_tool_icon_url: z.string().optional(),
  iframe: ZIframeDimensions.optional(),

  window: ZAssetProcessorWindowSettings.optional(),
})

export type AssetProcessorWindowSettings = z.infer<typeof ZAssetProcessorWindowSettings>

export type ExistingAttachedAssetProcessor = z.infer<typeof ZExistingAttachedAssetProcessor>

// TODO: we'll probably want to do real validation on the whole content item,
// at least on the server. See INTEROP-9255
export function safeDigIconUrl(icon: any): string | undefined {
  if (typeof icon === 'object' && icon && typeof icon.url === 'string') {
    return icon.url
  }
}

export function buildAPDisplayTitle({
  title,
  toolPlacementLabel,
  toolName,
}: {title?: string; toolPlacementLabel?: string; toolName: string}) {
  const toolTitle = toolPlacementLabel || toolName
  return title && title !== toolTitle ? `${toolTitle} · ${title}` : toolTitle
}

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
  id: z.number(),
  resubmit_url_path: z.string().optional(),
  launch_url_path: z.string().optional(),

  report_type: z.string(),
  processing_progress: ZLtiAssetReportProcessingProgress,
  priority: ZLtiAssetReportPriority,

  title: z.string().optional(),
  comment: z.string().optional(),
  result: z.string().optional(),
  result_truncated: z.string().optional(),
  indication_color: z.string().optional(),
  indication_alt: z.string().optional(),
  error_code: z.string().optional(),
})
export type LtiAssetReport = z.infer<typeof ZLtiAssetReport>

/**
 * Data sent by tool in deep linking response content item.
 */
export const ZImageUrlWithDimensions = z.object({
  url: z.string().optional(),
  width: z.number().int().nonnegative().optional(),
  height: z.number().int().nonnegative().optional(),
})

/**
 * Data sent by tool in deep linking response content item.
 */
export const ZAssetProcessorContentItem = z.object({
  type: z.literal('ltiAssetProcessor'),
  url: z.string().optional(),
  title: z.string().optional(),
  text: z.string().optional(),
  icon: ZImageUrlWithDimensions.optional(),
  thumbnail: ZImageUrlWithDimensions.optional(),
  window: ZAssetProcessorWindowSettings.optional(),
  iframe: ZIframeDimensions.optional(),
  custom: z.record(z.string()).optional(),
  report: z
    .object({
      url: z.string().optional(),
      custom: z.record(z.string()).optional(),
    })
    .optional(),
})

export type AssetProcessorContentItem = z.infer<typeof ZAssetProcessorContentItem>
