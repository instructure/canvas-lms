/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useCallback, useEffect, useState} from 'react'
import {useQuery} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

import {GRADEBOOK_SUBMISSION_COMMENTS} from '../../queries/Queries'
import {
  ApiCallStatus,
  type CommentConnection,
  type GradebookSubmissionCommentsResponse,
} from '../../types'
import type {Submission} from '../../../../api.d'

const I18n = useI18nScope('enhanced_individual_gradebook_submit_score')

type UseCommentsProps = {
  courseId?: string
  submissionId?: string
}
export const useGetComments = ({courseId, submissionId}: UseCommentsProps) => {
  const [submissionComments, setSubmissionComments] = useState<CommentConnection[]>([])

  const {data, error, loading, refetch} = useQuery<GradebookSubmissionCommentsResponse>(
    GRADEBOOK_SUBMISSION_COMMENTS,
    {
      variables: {courseId, submissionId},
      fetchPolicy: 'cache-and-network',
      skip: !submissionId || !courseId,
    }
  )

  useEffect(() => {
    if (error) {
      // TODO: handle error
    }

    if (data?.submission) {
      setSubmissionComments(data.submission.commentsConnection.nodes)
    }
  }, [data, error])

  return {submissionComments, loadingComments: loading, refetchComments: refetch}
}

export const usePostComment = () => {
  const [postCommentStatus, setpostCommentStatus] = useState<ApiCallStatus>(
    ApiCallStatus.NOT_STARTED
  )
  const [postCommentError, setpostCommentError] = useState<string>('')

  const submit = useCallback(
    async (comment: string, groupComment?: boolean, submitScoreUrl?: string | null) => {
      if (!submitScoreUrl) {
        setpostCommentError(I18n.t('Unable to post comment'))
        setpostCommentStatus(ApiCallStatus.FAILED)
        return
      }

      setpostCommentStatus(ApiCallStatus.PENDING)

      const requestBody = {
        comment: {
          text_comment: comment,
          group_comment: groupComment,
        },
      }

      try {
        const {status} = await executeApiRequest<Submission>({
          path: submitScoreUrl,
          body: requestBody,
          method: 'PUT',
        })

        if (status === 200) {
          setpostCommentStatus(ApiCallStatus.COMPLETED)
        } else {
          throw new Error()
        }
      } catch (error) {
        setpostCommentError(I18n.t('Something went wrong'))
        setpostCommentStatus(ApiCallStatus.FAILED)
      }
    },
    []
  )

  return {
    postCommentError,
    postCommentStatus,
    submit,
  }
}
