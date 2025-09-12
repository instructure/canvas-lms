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

import {
  resubmitFailureMessage,
  ResubmitLtiAssetReportsParams,
  resubmitPath,
  resubmitSuccessMessage,
} from '@canvas/lti-asset-processor/shared-with-sg/replicated/mutations/resubmitLtiAssetReports'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'

import {useMutation, UseMutationResult} from '@tanstack/react-query'

async function resubmitLtiAssetReports(props: ResubmitLtiAssetReportsParams) {
  try {
    await doFetchApi({path: resubmitPath(props), method: 'POST'})
  } catch (e) {
    console.error('Error resubmitting LTI asset reports:', e)
    throw e
  }
}

type ResubmitLtiAssetReportsMutationResult = UseMutationResult<
  void,
  Error,
  ResubmitLtiAssetReportsParams,
  unknown
>

export function useResubmitLtiAssetReports(): ResubmitLtiAssetReportsMutationResult {
  return useMutation({
    mutationFn: resubmitLtiAssetReports,
    onSuccess: showFlashSuccess(resubmitSuccessMessage()),
    onError: () => showFlashError(resubmitFailureMessage())(),
  })
}
