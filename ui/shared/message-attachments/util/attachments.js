/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {uploadFiles} from '@canvas/upload-file'

const I18n = useI18nScope('conversations_2')

export const addAttachmentsFn =
  (
    setAttachments,
    setPendingUploads,
    messageAttachmentUploadFolderId,
    setOnFailure,
    setOnSuccess
  ) =>
  async e => {
    const fileUploadUrl = `/api/v1/folders/${messageAttachmentUploadFolderId}/files`

    const files = Array.from(e.currentTarget?.files)
    if (!files.length) {
      setOnFailure(I18n.t('Error adding files.'))
      return
    }

    const newAttachmentsToUpload = files.map((file, i) => {
      return {isLoading: true, id: file.url ? `${i}-${file.url}` : `${i}-${file.name}`}
    })

    setPendingUploads(prev => prev.concat(newAttachmentsToUpload))
    setOnSuccess(I18n.t('Uploading files'))

    try {
      const newFiles = await uploadFiles(files, fileUploadUrl)
      setAttachments(prev => prev.concat(newFiles))
    } catch (err) {
      setOnFailure(I18n.t('Error uploading files.'))
    } finally {
      setPendingUploads(prev => {
        const attachmentsStillUploading = prev.filter(
          file => !newAttachmentsToUpload.includes(file)
        )
        return attachmentsStillUploading
      })
    }
  }

export const removeAttachmentFn = setAttachments => id => {
  setAttachments(prev => prev.filter(prevAttachment => prevAttachment.id !== id))
}
