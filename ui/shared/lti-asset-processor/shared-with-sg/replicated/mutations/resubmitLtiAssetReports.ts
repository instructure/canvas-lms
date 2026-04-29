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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_asset_processor')

export const ZResubmitLtiAssetReportsParams: z.ZodSchema<{
  processorId: string
  studentId: string
  attempt?: string | null
}> = z.object({
  processorId: z.string().min(1),
  studentId: z.string().min(1),
  attempt: z.string().nullable().optional(),
})

export type ResubmitLtiAssetReportsParams = z.infer<typeof ZResubmitLtiAssetReportsParams>

export function resubmitPath({processorId, studentId, attempt}: ResubmitLtiAssetReportsParams) {
  return `/api/lti/asset_processors/${processorId}/notices/${encodeURIComponent(studentId)}/attempts/${attempt ?? 'latest'}`
}

export function resubmitSuccessMessage(): string {
  return I18n.t('Resubmitted to Document Processing App')
}

export function resubmitFailureMessage(): string {
  return I18n.t('Resubmission failed')
}
