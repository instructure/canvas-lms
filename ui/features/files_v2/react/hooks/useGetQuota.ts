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
import {generateFilesQuotaUrl, UnauthorizedError} from '../../utils/apiUtils'

const fetchQuota = async (contextType: string, contextId: string) => {
  const response = await fetch(generateFilesQuotaUrl(contextType, contextId))
  if (response.status === 401) {
    throw new UnauthorizedError()
  }
  if (!response.ok) {
    throw new Error()
  }
  return response.json()
}

const queryFn = ({queryKey}: {queryKey: [string, string, string]}) => {
  const [, contextType, contextId] = queryKey
  return fetchQuota(contextType, contextId)
}

export const useGetQuota = (contextType: string, contextId: string) => {
  return useQuery({
    queryKey: ['quota', contextType, contextId],
    queryFn,
    staleTime: 0,
  })
}
