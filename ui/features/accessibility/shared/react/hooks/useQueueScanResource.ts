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
import {useShallow} from 'zustand/react/shallow'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {AccessibilityResourceScan} from '../types'
import {ScanWorkflowState} from '../types'
import {getResourceQueueScanPath} from '../utils/query'
import {useAccessibilityScansStore} from '../stores/AccessibilityScansStore'

interface ScanResourceParams {
  item: AccessibilityResourceScan
}

export const useQueueScanResource = () => {
  const [accessibilityScans, setAccessibilityScans] = useAccessibilityScansStore(
    useShallow(state => [state.accessibilityScans, state.setAccessibilityScans]),
  )

  const mutation = useMutation({
    mutationFn: async ({item}: ScanResourceParams) => {
      const response = await doFetchApi({
        path: getResourceQueueScanPath(item),
        method: 'POST',
      })
      return response
    },
    onSuccess: (_data, {item}) => {
      if (accessibilityScans) {
        const updatedScans = accessibilityScans.map(scan =>
          scan.id === item.id ? {...scan, workflowState: ScanWorkflowState.Queued} : scan,
        )
        setAccessibilityScans(updatedScans)
      }
    },
  })

  return mutation
}
