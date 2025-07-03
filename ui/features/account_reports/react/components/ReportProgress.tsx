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

import React, {useEffect, useState, useRef, useCallback} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {IconXSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {ProgressCircle} from '@instructure/ui-progress'
import {AccountReport, reportRunning} from '@canvas/account_reports/types'

import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
const I18n = createI18nScope('account_reports')

const POLLING_INTERVAL = 3000

interface Props {
  accountId: string
  reportRun: AccountReport
  onStateChange: (report: AccountReport) => void
}

export default function ReportProgress({accountId, reportRun, onStateChange}: Props) {
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const [canceling, setCanceling] = useState(false)

  const cancelReport = async () => {
    setCanceling(true)
    try {
      const {json} = await doFetchApi<AccountReport>({
        path: `/api/v1/accounts/${accountId}/reports/${reportRun.report}/${reportRun.id}/abort`,
        method: 'PUT',
      })
      onStateChange(json!)
    } catch (error) {
      showFlashError(I18n.t('Error canceling report'))(error as Error)
      setCanceling(false)
    }
  }

  const stopPolling = () => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current)
      timeoutRef.current = null
    }
  }

  const pollReportProgress = useCallback(async () => {
    try {
      const {json} = await doFetchApi<AccountReport>({
        path: `/api/v1/accounts/${accountId}/reports/${reportRun.report}/${reportRun.id}`,
      })
      onStateChange(json!)
      if (reportRunning(json?.status)) {
        timeoutRef.current = setTimeout(pollReportProgress, POLLING_INTERVAL)
      }
    } catch (error) {
      showFlashError(I18n.t('Error fetching report progress'))(error as Error)
      stopPolling()
    }
  }, [accountId, reportRun.report, reportRun.id, onStateChange])

  useEffect(() => {
    if (reportRunning(reportRun.status)) {
      pollReportProgress()
    }

    return stopPolling
  }, [reportRun.status, pollReportProgress])

  return (
    <>
      <ProgressCircle
        size="x-small"
        screenReaderLabel={I18n.t('Report progress')}
        valueNow={reportRun.progress}
        margin="0 small 0 0"
        shouldAnimateOnMount
      />
      <IconButton
        withBackground={false}
        withBorder={false}
        margin="0 0 0 x-small"
        screenReaderLabel={I18n.t('Cancel report')}
        onClick={cancelReport}
        interaction={canceling ? 'disabled' : 'enabled'}
      >
        <IconXSolid />
      </IconButton>
    </>
  )
}
