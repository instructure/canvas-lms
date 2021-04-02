/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useState, useCallback} from 'react'
import useFetchApi from '@canvas/use-fetch-api-hook'

function useSettings(coursId) {
  const [group, setGroup] = useState({})
  const [enabled, setEnabled] = useState()
  const [loading, setLoading] = useState({})
  const [error, setError] = useState()

  // TODO: Make real requests to create/delete the group
  function toggleGroup() {
    return new Promise(resolve =>
      setTimeout(
        resolve({
          workflow_state: 'deleted',
          last_synced_at: 'Tue, 30 Mar 2021 20:44:10 UTC +00:00'
        }),
        3000
      )
    )
  }

  useFetchApi({
    success: useCallback(response => {
      setGroup(response)
      setEnabled(response.workflow_state !== 'deleted')
    }, []),
    error: setError,
    loading: setLoading,
    path: `/api/v1/courses/${coursId}/microsoft_sync/group`
  })

  // TODO: Extract bits to a common method that handles setting loading/error state
  async function toggleEnabled() {
    setLoading(true)
    try {
      const groupResponse = await toggleGroup()
      setGroup(groupResponse)
      setEnabled(groupResponse.workflow_state !== 'deleted')
    } catch (e) {
      setError(e)
    }
    setLoading(false)
  }

  return [group, enabled, loading, error, toggleEnabled]
}

export default useSettings
