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

import {useEffect, useState} from 'react'
import type {CustomColumn} from '../../types'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

export const useCustomColumns = (getCustomColumnsUrl?: string | null) => {
  const [customColumns, setCustomColumns] = useState<CustomColumn[] | null>(null)
  useEffect(() => {
    const fetchCustomColumns = async () => {
      if (!getCustomColumnsUrl) {
        return
      }
      const {data} = await executeApiRequest<CustomColumn[]>({
        method: 'GET',
        path: getCustomColumnsUrl,
      })
      setCustomColumns(data)
    }
    fetchCustomColumns()
  }, [getCustomColumnsUrl])
  return {
    customColumns,
  }
}
