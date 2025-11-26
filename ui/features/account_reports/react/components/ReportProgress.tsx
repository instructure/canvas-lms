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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {IconXSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {ProgressCircle} from '@instructure/ui-progress'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {AccountReport, reportRunning} from '@canvas/account_reports/types'

import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('account_reports')

interface Props {
  accountId: string
  reportRun: AccountReport
  onStateChange: (report: AccountReport) => void
}

export default function ReportProgress({accountId, reportRun, onStateChange}: Props) {
  const [canceling, setCanceling] = useState(false)
  const [errored, setErrored] = useState(false)

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

  const {error} = useQuery<AccountReport>({
    queryKey: ['reportProgress', accountId, reportRun.report, reportRun.id],
    queryFn: async ({queryKey}) => {
      const [_key, accountId, reportName, reportId] = queryKey
      const {json} = await doFetchApi<AccountReport>({
        path: `/api/v1/accounts/${accountId}/reports/${reportName}/${reportId}`,
      })
      onStateChange(json!)
      return json!
    },
    enabled: !errored && reportRunning(reportRun.status),
    staleTime: 0,
    refetchOnWindowFocus: true,
    refetchInterval: query => {
      // initially poll every 2 seconds, slowing down to once a minute for long-running reports
      const n = query.state.data?.run_time
      return n ? Math.min(2000 * 1.02 ** n, 60000) : false
    },
    refetchIntervalInBackground: false,
  })
  if (error && !errored) {
    setErrored(true)
    showFlashError(I18n.t('Error updating report progress'))(error as Error)
  }

  const getStatusText = () => {
    const progress = reportRun.progress
    if (errored) return I18n.t('Error (%{progress}%)', {progress})
    if (canceling) return I18n.t('Canceling (%{progress}%)', {progress})
    switch (reportRun.status) {
      case 'running':
        return I18n.t('Running (%{progress}%)', {progress})
      case 'compiling':
        return I18n.t('Compiling (%{progress}%)', {progress})
      case 'created':
        return I18n.t('Starting (%{progress}%)', {progress})
      default:
        return I18n.t('Processing (%{progress}%)', {progress})
    }
  }

  return (
    <Flex gap="x-small" alignItems="center">
      <ProgressCircle
        size="x-small"
        meterColor={errored ? 'danger' : 'info'}
        screenReaderLabel={I18n.t('Report progress')}
        valueNow={reportRun.progress}
        shouldAnimateOnMount
      />
      <Text size="small" weight="normal">
        {getStatusText()}
      </Text>
      <Tooltip renderTip={I18n.t('Cancel report')}>
        <IconButton
          size="small"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Cancel report')}
          onClick={cancelReport}
          interaction={canceling || errored ? 'disabled' : 'enabled'}
          data-testid="cancel-report-button"
        >
          <IconXSolid />
        </IconButton>
      </Tooltip>
    </Flex>
  )
}
