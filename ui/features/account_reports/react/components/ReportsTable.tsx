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
import {
  IconDownloadLine,
  IconCalendarClockLine,
  IconQuestionLine,
  IconCheckLine,
  IconTroubleSolid,
  IconWarningSolid,
} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {IconButton, Button} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Transition} from '@instructure/ui-motion'
import {Pill} from '@instructure/ui-pill'
import {showFlashSuccess, showFlashWarning} from '@canvas/alerts/react/FlashAlert'
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

  const alertOnStatusChange = (prevReport: AccountReport, updatedReport: AccountReport) => {
    if (!prevReport || prevReport.status !== updatedReport.status) {
      const title =
        reports.find(r => r.report === updatedReport.report)?.title || updatedReport.report
      switch (updatedReport.status) {
        case 'complete':
          showFlashSuccess(I18n.t('Report %{title} completed successfully', {title}))()
          break
        case 'error':
          showFlashWarning(I18n.t('Report %{title} failed to complete', {title}))()
          break
        case 'aborted':
          showFlashWarning(I18n.t('Report %{title} was canceled', {title}))()
          break
      }
    }
  }

  const updateReport = (report: AccountReport) => {
    setUpdatedReports(prevReports => {
      alertOnStatusChange(prevReports[report.report], report)
      return {
        ...prevReports,
        [report.report]: report,
      }
    })
  }

  const formatDate = useDateTimeFormat('time.formats.medium')

  const updatePill = (
    color: 'success' | 'warning' | 'danger',
    text: string,
    icon: React.ReactElement,
  ) => {
    return (
      <Transition in transitionOnMount type="scale">
        <Pill color={color} margin="0 small" renderIcon={icon}>
          {text}
        </Pill>
      </Transition>
    )
  }

  const renderUpdatePill = (lastRun: AccountReport) => {
    switch (lastRun.status) {
      case 'complete':
        return updatePill('success', I18n.t('Completed'), <IconCheckLine />)
      case 'error':
        return updatePill('warning', I18n.t('Failed'), <IconWarningSolid />)
      case 'aborted':
        return updatePill('danger', I18n.t('Canceled'), <IconTroubleSolid />)
      default:
        return null
    }
  }

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
            <Table.ColHeader id="run_report" width="12rem">
              {I18n.t('Run Report')}
            </Table.ColHeader>
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
                      <View as="div">
                        {formatDate(lastRun.created_at)}
                        {lastRun.report in updatedReports && renderUpdatePill(lastRun)}
                        {lastRun.parameters?.extra_text && (
                          <Text>&nbsp;({lastRun.parameters.extra_text})</Text>
                        )}
                        {lastRun.file_url && (
                          <Tooltip renderTip={I18n.t('Download report')}>
                            <Link
                              href={`${lastRun.file_url}?download_frd=1`}
                              margin="0 0 0 x-small"
                              renderIcon={IconDownloadLine}
                            >
                              <ScreenReaderContent>{I18n.t('Download report')}</ScreenReaderContent>
                            </Link>
                          </Tooltip>
                        )}
                      </View>
                      <View as="div" margin="x-small 0 0 0">
                        <Button
                          size="small"
                          color="secondary"
                          onClick={() => setHistoryReport(report)}
                          renderIcon={<IconCalendarClockLine />}
                        >
                          {I18n.t('Report History')}
                        </Button>
                      </View>
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
