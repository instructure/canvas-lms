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
import {useMutation} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import getCookie from '@instructure/canvas-rce/es/common/getCookie'
type NodeFile = globalThis.File

export interface useUploadTracksProps {
  attachmentId: string
}

export const useUploadTracks = ({attachmentId}: useUploadTracksProps) => {
  return useMutation({
    mutationFn: async ({locale, file}: {locale: string; file: NodeFile}) => {
      const formData = new FormData()
      formData.append('kind', 'subtitles')
      formData.append('locale', locale)
      formData.append('content', file)
      const response = await fetch(`/media_attachments/${attachmentId}/media_tracks`, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': getCookie('_csrf_token'),
        },
      })
      if (!response.ok) {
        throw new Error()
      }
      return await response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['media', attachmentId])
    },
  })
}
