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

import React, {useState} from 'react'
import {QueryClient, useMutation, useQuery, useQueryClient} from '@tanstack/react-query'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {FetchApiError} from '@canvas/do-fetch-api-effect'
import GenericErrorPage from '@canvas/generic-error-page/react'
import ErrorShip from '@canvas/images/ErrorShip.svg'
import {LoadingView} from './components/LoadingView'
import {NoScanFoundView} from './components/NoScanFoundView'
import {ScanningInProgressView} from './components/ScanningInProgressView'
import {LastScanFailedResultView} from './components/LastScanFailedResultView'
import {ScanHandler} from './components/ScanHandler'
import {accessibilityScanQuery, createAccessibilityScanMutation} from './utils/api'
import {type CourseScanProps} from './types'
import {ACCESSIBILITY_SCAN_QUERY_KEY, QUERY_LAST_SCAN, CREATE_SCAN} from './constants'

const I18n = createI18nScope('accessibility_scan')

const onErrorCallbackForScan = () => {
  showFlashError(
    I18n.t('Something went wrong during course scan start. Reload the page and try again.'),
  )()
}

const onSuccessCallbackForScan = (courseId: string, queryClient: QueryClient) => {
  queryClient.setQueryData([ACCESSIBILITY_SCAN_QUERY_KEY, QUERY_LAST_SCAN, courseId], {
    workflow_state: 'queued',
  })
}

export const AccessibilityCourseScan: React.FC<CourseScanProps> = ({
  courseId,
  children,
  scanDisabled,
}) => {
  const queryClient = useQueryClient()
  const [isMutationLoading, setIsMutationLoading] = useState(false)

  const {isLoading, isError, data} = useQuery({
    queryKey: [ACCESSIBILITY_SCAN_QUERY_KEY, QUERY_LAST_SCAN, courseId],
    queryFn: async context => {
      try {
        return await accessibilityScanQuery(context)
      } catch (error: unknown) {
        if (error instanceof FetchApiError && error.response.status === 404) {
          return {workflow_state: null}
        }
        throw error
      }
    },
    refetchInterval: query => {
      const state = query.state.data?.workflow_state
      // Poll every 2s if queued or running, otherwise stop
      return state === 'queued' || state === 'running' ? 2000 : false
    },
    refetchIntervalInBackground: false,
  })

  const mutation = useMutation({
    mutationKey: [ACCESSIBILITY_SCAN_QUERY_KEY, CREATE_SCAN, courseId],
    mutationFn: createAccessibilityScanMutation,
    onSuccess: () => onSuccessCallbackForScan(courseId, queryClient),
    onError: onErrorCallbackForScan,
    onSettled: () => setIsMutationLoading(false),
  })

  const handleCourseScan = () => {
    setIsMutationLoading(true)

    const url = new URL(window.location.href)
    if (url.searchParams.has('page')) {
      url.searchParams.delete('page')
      window.history.replaceState({}, '', url.toString())
    }

    mutation.mutate({courseId})
  }

  const mutationInProgress = isMutationLoading

  if (isLoading) {
    return <LoadingView />
  }

  if (isError || !data) {
    return (
      <GenericErrorPage
        imageUrl={ErrorShip}
        errorSubject={I18n.t('Scan loading error')}
        errorCategory={I18n.t('Accessibility Scan Error Page.')}
        errorMessage={I18n.t('Try to reload the page.')}
      />
    )
  }

  if (data.workflow_state == null) {
    return (
      <NoScanFoundView
        handleCourseScan={handleCourseScan}
        isRequestLoading={mutationInProgress || scanDisabled}
      />
    )
  }

  if (data.workflow_state === 'failed') {
    return (
      <LastScanFailedResultView
        handleCourseScan={handleCourseScan}
        isRequestLoading={mutationInProgress || scanDisabled}
      />
    )
  }

  if (data.workflow_state === 'queued' || data.workflow_state === 'running' || mutationInProgress) {
    return <ScanningInProgressView />
  }

  if (data.workflow_state === 'completed') {
    return (
      <ScanHandler
        handleCourseScan={handleCourseScan}
        scanButtonDisabled={mutationInProgress || scanDisabled}
      >
        {children}
      </ScanHandler>
    )
  }

  return <LoadingView />
}
