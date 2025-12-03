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
  resubmitDiscussionNoticesFailureMessage,
  ResubmitDiscussionNoticesParams,
  resubmitDiscussionNoticesPath,
  resubmitDiscussionNoticesSuccessMessage,
} from '@canvas/lti-asset-processor/shared-with-sg/replicated/mutations/resubmitDiscussionNotices'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'

import {useMutation, UseMutationResult} from '@tanstack/react-query'

async function resubmitDiscussionNotices(props: ResubmitDiscussionNoticesParams) {
  try {
    await doFetchApi({path: resubmitDiscussionNoticesPath(props), method: 'POST'})
  } catch (e) {
    console.error('Error resubmitting discussion notices:', e)
    throw e
  }
}

type ResubmitDiscussionNoticesMutationResult = UseMutationResult<
  void,
  Error,
  ResubmitDiscussionNoticesParams,
  unknown
>

export function useResubmitDiscussionNotices(): ResubmitDiscussionNoticesMutationResult {
  return useMutation({
    mutationFn: resubmitDiscussionNotices,
    onSuccess: showFlashSuccess(resubmitDiscussionNoticesSuccessMessage()),
    onError: () => showFlashError(resubmitDiscussionNoticesFailureMessage())(),
  })
}
