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

import RunReportForm from '@canvas/account_reports/react/RunReportForm'
import doFetchApi from '@canvas/do-fetch-api-effect'
import React from 'react'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import ReportProgress from './ReportProgress'
import {AccountReportInfo, AccountReport, reportRunning} from '@canvas/account_reports/types'

import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
const I18n = createI18nScope('account_reports')

type Props = {
  accountId: string
  report: AccountReportInfo
  reportRun?: AccountReport
  onStateChange: (report: AccountReport) => void
}

export default function ReportAction({accountId, report, reportRun, onStateChange}: Props) {
  const [configuring, setConfiguring] = React.useState<boolean>(false)
  const run_report_path = `/api/v1/accounts/${accountId}/reports/${report.report}`

  const onConfigure = () => {
    setConfiguring(true)
  }

  const onRunReport = async () => {
    try {
      const {json} = await doFetchApi<AccountReport>({
        path: run_report_path,
        method: 'POST',
      })
      onStateChange(json!)
    } catch (error) {
      showFlashError(I18n.t('Error running report'))(error as Error)
    }
  }

  return (
    <div>
      {reportRunning(reportRun?.status) ? (
        <ReportProgress
          accountId={accountId}
          reportRun={reportRun!}
          onStateChange={onStateChange}
        />
      ) : (
        <View as="div">
          {report.parameters_html ? (
            <Button color="secondary" onClick={onConfigure}>
              {I18n.t('Configure Run...')}
            </Button>
          ) : (
            <Button color="primary" onClick={onRunReport}>
              {I18n.t('Run Report')}
            </Button>
          )}
        </View>
      )}
      {configuring && (
        <RunReportForm
          path={run_report_path}
          reportName={report.report}
          onSuccess={data => {
            setConfiguring(false)
            onStateChange(data)
          }}
          formHTML={report.parameters_html!}
          closeModal={() => setConfiguring(false)}
        />
      )}
    </div>
  )
}
