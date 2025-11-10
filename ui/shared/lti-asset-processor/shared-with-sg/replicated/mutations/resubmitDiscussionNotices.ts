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

export const ZResubmitDiscussionNoticesParams: z.ZodSchema<{
  assignmentId: string
  studentId: string
}> = z.object({
  assignmentId: z.string().min(1),
  studentId: z.string().min(1),
})

export type ResubmitDiscussionNoticesParams = z.infer<typeof ZResubmitDiscussionNoticesParams>

export function resubmitDiscussionNoticesPath({
  assignmentId,
  studentId,
}: ResubmitDiscussionNoticesParams) {
  return `/api/lti/asset_processors/discussion_notices/${assignmentId}/${encodeURIComponent(studentId)}/resubmit_all`
}

export function resubmitDiscussionNoticesSuccessMessage(): string {
  return I18n.t('Resubmitted all replies to Document Processing Apps')
}

export function resubmitDiscussionNoticesFailureMessage(): string {
  return I18n.t('Resubmission failed')
}
