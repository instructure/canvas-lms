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
import type {GetLtiAssetReportsResult} from '../../dependenciesShims'

type LtiAssetReportsConnection = NonNullable<
  NonNullable<GetLtiAssetReportsResult['submission']>['ltiAssetReportsConnection']
>

export type LtiAssetReportsNodes = NonNullable<LtiAssetReportsConnection['nodes']>
export type LtiAssetReport = NonNullable<LtiAssetReportsNodes[number]>
export type LtiAsset = LtiAssetReport['asset']

const COMPATIBLE_SUBMISSION_TYPES = ['online_text_entry', 'online_upload'] as const

export const ZAssetReportCompatibleSubmissionType: z.ZodEnum<
  ['online_text_entry', 'online_upload']
> = z.enum(COMPATIBLE_SUBMISSION_TYPES)

export type AssetReportCompatibleSubmissionType = z.infer<
  typeof ZAssetReportCompatibleSubmissionType
>

export function ensureCompatibleSubmissionType(
  submissionType: string,
): AssetReportCompatibleSubmissionType | undefined {
  const result = ZAssetReportCompatibleSubmissionType.safeParse(submissionType)
  if (result.success) {
    return result.data
  }
  return undefined
}
