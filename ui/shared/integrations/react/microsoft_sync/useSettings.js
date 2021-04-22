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

import axios from 'axios'
import {useState, useCallback} from 'react'
import I18n from 'i18n!course_settings'
import useFetchApi from '@canvas/use-fetch-api-hook'

function useSettings(courseId) {
  const [group, setGroup] = useState({})
  const [enabled, setEnabled] = useState(false)
  const [loading, setLoading] = useState({})
  const [error, setError] = useState()
  const groupEndpoint = `/api/v1/courses/${courseId}/microsoft_sync/group`

  async function toggleGroup() {
    const response = await axios.request({
      method: enabled ? 'delete' : 'post',
      url: groupEndpoint
    })

    setGroup(response.data)
    setEnabled(!!response.data.workflow_state)
    setError()
  }

  // This effect is called once on render
  useFetchApi({
    success: useCallback(response => {
      setGroup(response)
      setEnabled(!!response.workflow_state)

      if (response.workflow_state === 'errored') {
        setError({
          message: I18n.t('An error occurred during the sync process: %{error}', {
            error: response.last_error
          })
        })
      }
    }, []),
    error: useCallback(e => {
      // 404s are expected if the group has not been created yet.
      if (!(e.response.status === 404)) {
        setError(e.message)
      }
    }, []),
    loading: setLoading,
    path: groupEndpoint
  })

  // The function called to enable/disable
  // Microsoft Sync plugin
  async function toggleEnabled() {
    setLoading(true)
    try {
      await toggleGroup()
    } catch (e) {
      setError(e.message)
    }
    setLoading(false)
  }

  return [group, enabled, loading, error, toggleEnabled, setError, setGroup]
}

export default useSettings
