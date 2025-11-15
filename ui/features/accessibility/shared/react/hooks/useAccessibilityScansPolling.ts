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

import {useMemo} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {useQuery} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useAccessibilityScansStore} from '../stores/AccessibilityScansStore'
import {AccessibilityResourceScan, ScanWorkflowState} from '../types'
import {convertKeysToCamelCase} from '../utils/apiData'
import {getCourseBasedPath} from '../utils/query'

const POLLING_INTERVAL_MS = 5000

type PollingResponse = {
  scans: AccessibilityResourceScan[]
}

/**
 * Custom hook to manage polling for resource scans with Queued or InProgress workflow states.
 * Uses TanStack Query for efficient polling with automatic cleanup.
 */
export const useAccessibilityScansPolling = () => {
  const [accessibilityScans, setAccessibilityScans] = useAccessibilityScansStore(
    useShallow(state => [state.accessibilityScans, state.setAccessibilityScans]),
  )

  const scansNeedingPolling = useMemo(() => {
    if (!accessibilityScans) return []

    return accessibilityScans
      .filter(
        scan =>
          scan.workflowState === ScanWorkflowState.Queued ||
          scan.workflowState === ScanWorkflowState.InProgress,
      )
      .map(scan => scan.id)
      .sort()
  }, [accessibilityScans])

  const shouldPoll = scansNeedingPolling.length > 0

  useQuery({
    queryKey: ['resourceAccessibilityScan', scansNeedingPolling],
    queryFn: async () => {
      // Double-check we have scans to poll (should be guaranteed by enabled flag)
      if (scansNeedingPolling.length === 0) {
        return null
      }

      const path = getCourseBasedPath('/accessibility/resource_scan/poll')
      const data = await doFetchApi<PollingResponse>({
        path,
        params: {
          scan_ids: scansNeedingPolling.join(','),
        },
        method: 'GET',
      })

      // Check for error responses (4xx or 5xx) and throw to stop polling
      if (data.response && !data.response.ok) {
        throw new Error(`Polling failed with status ${data.response.status}`)
      }

      if (data.json && accessibilityScans) {
        const updatedScans = convertKeysToCamelCase(data.json.scans) as AccessibilityResourceScan[]

        const updatedScansMap = new Map(updatedScans.map(scan => [scan.id, scan]))

        const newScans = accessibilityScans.map(scan => {
          const updatedScan = updatedScansMap.get(scan.id)
          return updatedScan || scan
        })

        setAccessibilityScans(newScans)

        return updatedScans
      }

      return null
    },
    enabled: shouldPoll,
    // Stop polling if there's an error (4xx/5xx), otherwise continue if shouldPoll is true
    refetchInterval: query => {
      if (query.state.error) {
        return false
      }
      return shouldPoll ? POLLING_INTERVAL_MS : false
    },
    refetchIntervalInBackground: false,
    retry: false,
  })
}
