/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useState, useEffect} from 'react'

interface AUPResponse {
  content: string
}

export const useAUPContent = () => {
  const [content, setContent] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  useEffect(() => {
    const fetchContent = async () => {
      try {
        const {json, response} = await doFetchApi<AUPResponse>({
          path: '/api/v1/acceptable_use_policy',
          method: 'GET',
        })

        if (response.ok && json) {
          setContent(json.content)
        } else {
          setError(true)
        }
      } catch (_err) {
        setError(true)
      } finally {
        setLoading(false)
      }
    }

    fetchContent()
  }, [])

  return {content, loading, error}
}
