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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {Table} from '@instructure/ui-table'
import {Link} from '@instructure/ui-link'
import {IconDownloadLine, IconCalendarClockLine, IconQuestionLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

import {AccountReportInfo, AccountReport} from '@canvas/account_reports/types'
import ReportDescription from '@canvas/account_reports/react/ReportDescription'
import ReportHistoryModal from './ReportHistoryModal'
import ReportAction from './ReportAction'

const I18n = createI18nScope('account_reports')

type Props = {
  accountId: string
  reports: AccountReportInfo[]
}

export default function ReportsTable({accountId, reports}: Props) {
  const [describedReport, setDescribedReport] = useState<AccountReportInfo | null>(null)
  const [historyReport, setHistoryReport] = useState<AccountReportInfo | null>(null)

  const [updatedReports, setUpdatedReports] = useState<{[key: string]: AccountReport}>({})

  const updateReport = (report: AccountReport) => {
    setUpdatedReports(prevReports => ({
      ...prevReports,
      [report.report]: report,
    }))
  }

  const formatDate = useDateTimeFormat('time.formats.medium')

  return (
    <>
      {describedReport && (
        <ReportDescription
          title={describedReport.title}
          descHTML={describedReport.description_html}
          closeModal={() => setDescribedReport(null)}
        />
      )}
      {historyReport && (
        <ReportHistoryModal
          accountId={accountId}
          report={historyReport.report}
          closeModal={() => setHistoryReport(null)}
        />
      )}
      <Table caption={I18n.t('Reports')}>
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="name">{I18n.t('Name')}</Table.ColHeader>
            <Table.ColHeader id="last_run">{I18n.t('Last Run')}</Table.ColHeader>
            <Table.ColHeader id="run_report">{I18n.t('Run Report')}</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {reports.map(report => {
            const lastRun = updatedReports[report.report] || report.last_run
            return (
              <Table.Row key={report.report} data-testid={`tr_${report.report}`}>
                <Table.RowHeader>
                  {report.title}
                  <IconButton
                    withBackground={false}
                    withBorder={false}
                    size="small"
                    margin="0 0 0 x-small"
                    screenReaderLabel={I18n.t('Details for %{title}', {title: report.title})}
                    onClick={() => setDescribedReport(report)}
                  >
                    <IconQuestionLine />
                  </IconButton>
                </Table.RowHeader>
                <Table.Cell>
                  {lastRun ? (
                    <>
                      {formatDate(lastRun.created_at)}
                      {lastRun.parameters?.extra_text && (
                        <Text>&nbsp;({lastRun.parameters.extra_text})</Text>
                      )}
                      {lastRun.file_url && (
                        <Link
                          href={`${lastRun.file_url}?download_frd=1`}
                          margin="0 0 0 x-small"
                          renderIcon={IconDownloadLine}
                        >
                          <ScreenReaderContent>{I18n.t('Download report')}</ScreenReaderContent>
                        </Link>
                      )}
                      <IconButton
                        withBackground={false}
                        withBorder={false}
                        margin="0 0 0 x-small"
                        screenReaderLabel={I18n.t('Report history')}
                        onClick={() => setHistoryReport(report)}
                      >
                        <IconCalendarClockLine />
                      </IconButton>
                    </>
                  ) : (
                    <Text color="secondary">{I18n.t('Never')}</Text>
                  )}
                </Table.Cell>
                <Table.Cell>
                  <ReportAction
                    accountId={accountId}
                    report={report}
                    reportRun={lastRun}
                    onStateChange={updateReport}
                  />
                </Table.Cell>
              </Table.Row>
            )
          })}
        </Table.Body>
      </Table>
    </>
  )
}
