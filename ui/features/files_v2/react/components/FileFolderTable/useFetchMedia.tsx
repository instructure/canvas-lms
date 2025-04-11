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

import {useQuery} from '@tanstack/react-query'
import {MediaInfo} from '@canvas/canvas-studio-player/react/types'

export interface useFetchMediaProps {
  attachmentId: string
  enabled: boolean
}

export const useFetchMedia = ({attachmentId, enabled}: useFetchMediaProps) => {
  return useQuery({
    queryKey: ['media', attachmentId],
    queryFn: async () => {
      const response = await fetch(`/media_attachments/${attachmentId}/info`)
      if (!response.ok) {
        /* If this errors, we pass undefined media_sources to CanvasStudioPlayer
           and let CanvasStudioPlayer handle retries and error messaging
           instead of duplicating that logic */
        return undefined
      }
      return (await response.json()) as MediaInfo
    },
    enabled: enabled,
    select: data => (enabled ? data : undefined),
    staleTime: 0,
    retry: false,
  })
}
