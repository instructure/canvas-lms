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
import {doFetchApiWithAuthCheck, NotFoundError} from '../../utils/apiUtils'
import {File} from '../../interfaces/File'

interface UseGetFileProps {
  fileId: string | null
  contextType?: string
  contextId?: string
}

export const useGetFile = ({fileId, contextType, contextId}: UseGetFileProps) => {
  return useQuery({
    queryKey: ['file', fileId, contextType, contextId],
    queryFn: async ({queryKey}): Promise<File> => {
      const [_, fileId, contextType, contextId] = queryKey
      const {json} = await doFetchApiWithAuthCheck<File>({
        method: 'GET',
        path: `/api/v1/files/${fileId}?include[]=user&include[]=usage_rights&include[]=enhanced_preview_url&include[]=context_asset_string`,
      })

      if (!json) {
        throw new NotFoundError('File not found')
      }

      // Validate that the file belongs to the current context if context is provided
      if (contextType && contextId) {
        const expectedContextAssetString = `${contextType}_${contextId}`
        if (json.context_asset_string !== expectedContextAssetString) {
          throw new NotFoundError('File not found in current context')
        }
      }

      return json
    },
    enabled: !!fileId,
    retry: false,
  })
}
