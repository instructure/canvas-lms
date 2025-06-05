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

import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useMutation} from '@tanstack/react-query'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('speed_grader')

// Canvas-specific functions:

async function resubmitLtiAssetReports(props: ResubmitLtiAssetReportsProps): Promise<void> {
  const url = resubmitPath(props)
  await doFetchApi({
    path: url,
    method: 'POST',
  })
}

export function useResubmitLtiAssetReports() {
  return useMutation({
    mutationFn: resubmitLtiAssetReports,
    onSuccess: () => showFlashSuccess(I18n.t('Resubmitted to Document Processing App'))(),
    onError: () => showFlashError(I18n.t('Resubmission failed'))(),
  })
}

// The rest should be the same as in SG2

export type ResubmitLtiAssetReportsProps = {
  processorId: string
  studentId: string
  attempt: number | undefined | null
}

// TODO: figure out what happens for anonymous grading here
function resubmitPath({processorId, studentId, attempt}: ResubmitLtiAssetReportsProps) {
  return `/api/lti/asset_processors/${processorId}/notices/${encodeURIComponent(studentId)}/attempts/${attempt ?? 'latest'}`
}
