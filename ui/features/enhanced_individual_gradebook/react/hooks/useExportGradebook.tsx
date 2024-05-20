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

import doFetchApi from '@canvas/do-fetch-api-effect'
import type {Progress} from '@canvas/grading/grading.d'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useState} from 'react'
import {ApiCallStatus} from '../../types'
import type {Attachment} from '../../../../api.d'

const I18n = useI18nScope('enhanced_individual_gradebook_submit_score')
type AttachmentProgress = {
  attachment_id: string
  filename: string
  progress_id: string
}
export const useExportGradebook = () => {
  const [attachmentStatus, setAttachmentStatus] = useState<ApiCallStatus>(ApiCallStatus.NOT_STARTED)
  const [attachmentError, setAttachmentError] = useState<Error>(new Error(''))
  const [attachment, setAttachment] = useState<Attachment | null>(null)

  const exportGradebook = async (userId?: string, exportGradebookCsvUrl?: string) => {
    setAttachmentStatus(ApiCallStatus.PENDING)
    if (!exportGradebookCsvUrl) {
      setAttachmentError(new Error('Error exporting gradebook, export URL not found'))
      setAttachmentStatus(ApiCallStatus.FAILED)
      return
    }
    if (!userId) {
      setAttachmentError(new Error('Error exporting gradebook, user ID not found'))
      setAttachmentStatus(ApiCallStatus.FAILED)
      return
    }
    try {
      const attachmentProgress = (await doFetchApi({path: exportGradebookCsvUrl, method: 'POST'}))
        .json as AttachmentProgress // TODO: remove type assertion once doFetchApi is typed
      const pollingProgress: number = window.setInterval(async () => {
        const progress = (
          await doFetchApi({
            path: `/api/v1/progress/${attachmentProgress.progress_id}`,
            method: 'GET',
          })
        ).json as Progress // TODO: remove type assertion once doFetchApi is typed
        if (progress.workflow_state === 'running' || progress.workflow_state === 'queued') {
          return
        }
        if (progress.workflow_state === 'completed') {
          const attachmentResult = (
            await doFetchApi({
              path: `/api/v1/users/${userId}/files/${attachmentProgress.attachment_id}`,
              method: 'GET',
            })
          ).json as Attachment // TODO: remove type assertion once doFetchApi is typed
          setAttachmentStatus(ApiCallStatus.COMPLETED)
          setAttachment(attachmentResult)
        }
        if (progress.workflow_state === 'failed') {
          clearInterval(pollingProgress)
          const message = progress.message
          setAttachmentError(
            new Error(
              message
                ? I18n.t('%{message}', {message})
                : I18n.t('There was an error exporting the gradebook')
            )
          )
          setAttachmentStatus(ApiCallStatus.FAILED)
        }
        clearInterval(pollingProgress)
      }, 2000)
    } catch (e) {
      setAttachmentError(e as Error)
      setAttachmentStatus(ApiCallStatus.FAILED)
    }
  }

  return {
    exportGradebook,
    attachmentStatus,
    attachmentError,
    attachment,
  }
}
