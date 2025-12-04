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
import {useScope as i18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {IconWarningLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Table} from '@instructure/ui-table'
import {
  AsyncPageViewJobStatus,
  AsyncPageviewJob,
  displayTTL,
  isInProgress,
  notExpired,
  statusColor,
  statusDisplayName,
  useAsyncPageviewJobs,
} from './hooks/asyncPageviewExport'
import {Pill} from '@instructure/ui-pill'
import {Link} from '@instructure/ui-link'
import {FetchApiError} from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = i18nScope('page_views')

export interface PageViewsDownloadProps {
  userId: string
}

const locale = ENV?.LOCALE || navigator.language
// For displaying selected months, we need a format with month and year only
const formatter = new Intl.DateTimeFormat(locale, {year: 'numeric', month: 'long'})

// Type representing a year and month pair (month range is 1-12)
type YearMonth = {year: number; month: number}

function yearMonthToDate(ym: YearMonth): Date {
  return new Date(ym.year, ym.month - 1, 1)
}

function yearMonthToApiString(ym: YearMonth): string {
  return `${ym.year}-${String(ym.month).padStart(2, '0')}-01`
}

function nextMonth(ym: YearMonth): YearMonth {
  if (ym.month === 12) {
    return {year: ym.year + 1, month: 1}
  }
  return {year: ym.year, month: ym.month + 1}
}

// Compare two YearMonth values (-1 if a < b, 0 if equal, 1 if a > b)
function compareYearMonth(a: YearMonth, b: YearMonth): number {
  if (a.year !== b.year) return a.year - b.year
  return a.month - b.month
}

// Available months are the last 13 months (current month + 12 previous)
const availableMonths: YearMonth[] = new Array(13).fill(0).map((_, i) => {
  const date = new Date()
  date.setDate(1)
  date.setMonth(date.getMonth() - i)
  return {year: date.getFullYear(), month: date.getMonth() + 1}
})

export function PageViewsDownload({userId}: PageViewsDownloadProps): React.JSX.Element {
  const [startMonth, setStartMonth] = useState<YearMonth>(availableMonths[0])
  const [endMonth, setEndMonth] = useState<YearMonth>(availableMonths[0])
  const [exportError, setExportError] = useState<string | null>(null)
  const [asyncJobs, _setAsyncJobs, pollAsyncJobs, postAsyncJob, getDownloadUrl] =
    useAsyncPageviewJobs(`pv-export-${userId}`, userId)

  const handleDownload = async (record: AsyncPageviewJob) => {
    try {
      const url = await getDownloadUrl(record)
      window.open(url, '_self')
    } catch (error) {
      if (
        error instanceof FetchApiError &&
        (error.response.status === 410 || error.response.status === 404)
      ) {
        showFlashAlert({
          message: I18n.t(
            'The requested export is no longer available and is removed from the list. Please create a new export.',
          ),
          type: 'info',
          err: undefined,
        })
      }
      if (error instanceof FetchApiError && error.response.status === 204) {
        showFlashAlert({
          message: I18n.t('The requested export is empty.'),
          type: 'info',
          err: undefined,
        })
      }
    }
  }

  const jobsInProgress = asyncJobs.some(isInProgress)

  // Polling mechanism for asyncJobs in progress
  React.useEffect(() => {
    let timeoutId: ReturnType<typeof setTimeout> | null = null
    let isCancelled = false

    pollAsyncJobs()
      .then(stateUpdateNeeded => {
        if (stateUpdateNeeded && !isCancelled) {
          timeoutId = setTimeout(pollAsyncJobs, 5000)
        }
      })
      .catch(_e => {
        // A failing poll is considered an intermittent error, so we keep polling
        if (!isCancelled) {
          if (timeoutId) clearTimeout(timeoutId)
          timeoutId = setTimeout(pollAsyncJobs, 5000)
        }
      })
    return () => {
      isCancelled = true
      if (timeoutId) clearTimeout(timeoutId)
    }
  }, [pollAsyncJobs])

  const postAsyncJobHandler = () => {
    if (compareYearMonth(startMonth, endMonth) > 0) {
      setExportError(
        I18n.t(
          'Please select a valid date range where the start month is not after the end month.',
        ),
      )
      return
    }
    if (jobsInProgress) {
      setExportError(I18n.t('You can request a new export once the current one is complete.'))
      return
    }
    setExportError(null)

    // Convert YearMonth to Date objects for display formatting in the user's locale
    const displayName = `${formatter.format(yearMonthToDate(startMonth))} - ${formatter.format(yearMonthToDate(endMonth))}`

    // API expects exclusive end date, so we send the next month after the user's selection
    const apiStartDate = yearMonthToApiString(startMonth)
    const apiEndDate = yearMonthToApiString(nextMonth(endMonth))

    postAsyncJob(userId, displayName, apiStartDate, apiEndDate).catch(e => {
      if (e instanceof FetchApiError && e.response.status === 429) {
        setExportError(
          I18n.t('You must wait for your running jobs to finish before starting a new one.'),
        )
      } else {
        setExportError(
          I18n.t('There was a problem creating a new export job. Please try again later.'),
        )
      }
    })
  }

  return (
    <>
      <Flex direction="column" gap="sectionElements">
        <Text>
          {I18n.t('You may export up to 1 year of history by selecting a start and end month.')}
        </Text>
        <Flex direction="column" gap="moduleElements">
          <Flex gap="inputFields" alignItems="end">
            <SimpleSelect
              renderLabel={I18n.t('Start month')}
              placeholder={I18n.t('Select month')}
              value={yearMonthToApiString(startMonth)}
              onChange={(_e, {value}) => {
                const ym = availableMonths.find(m => yearMonthToApiString(m) === value)
                if (ym) setStartMonth(ym)
              }}
            >
              {availableMonths.map(ym => {
                const key = yearMonthToApiString(ym)
                return (
                  <SimpleSelect.Option key={key} id={`start-month-${key}`} value={key}>
                    {formatter.format(yearMonthToDate(ym))}
                  </SimpleSelect.Option>
                )
              })}
            </SimpleSelect>
            <SimpleSelect
              renderLabel={I18n.t('End month')}
              placeholder={I18n.t('Select month')}
              value={yearMonthToApiString(endMonth)}
              onChange={(_e, {value}) => {
                const ym = availableMonths.find(m => yearMonthToApiString(m) === value)
                if (ym) setEndMonth(ym)
              }}
            >
              {availableMonths.map(ym => {
                const key = yearMonthToApiString(ym)
                return (
                  <SimpleSelect.Option key={key} id={`end-month-${key}`} value={key}>
                    {formatter.format(yearMonthToDate(ym))}
                  </SimpleSelect.Option>
                )
              })}
            </SimpleSelect>
            <Button
              data-testid="page-views-csv-link"
              onClick={postAsyncJobHandler}
              disabled={jobsInProgress}
            >
              {I18n.t('Export CSV')}
            </Button>
          </Flex>
          <Text size="small" color="warning">
            {exportError && (
              <Flex gap="space8">
                <IconWarningLine />
                {exportError}
              </Flex>
            )}
          </Text>
        </Flex>
        <Flex direction="column" gap="moduleElements">
          <Text size="large">{I18n.t('Recent exports (last 24 hours)')}</Text>
          <Text>
            {I18n.t(
              'Exporting a file may take anywhere from a few seconds to several minutes. CSV files are stored for 24 hours only.',
            )}
          </Text>
          <Table caption={I18n.t('Recent exports table')}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="export-name">{I18n.t('Exported Range')}</Table.ColHeader>
                <Table.ColHeader id="export-status">{I18n.t('Status')}</Table.ColHeader>
                <Table.ColHeader id="export-created-at">{I18n.t('Available for')}</Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {asyncJobs.filter(notExpired).map(record => (
                <Table.Row key={record.query_id}>
                  <Table.Cell id={`export-name-${record.query_id}`}>
                    {record.status === AsyncPageViewJobStatus.Finished ? (
                      <Link
                        onClick={() => handleDownload(record)}
                        data-testid={`download-${record.query_id}`}
                        isWithinText={false}
                      >
                        {record.name}
                      </Link>
                    ) : (
                      record.name
                    )}
                  </Table.Cell>
                  <Table.Cell id={`export-status-${record.query_id}`}>
                    <div aria-live="polite">
                      <Pill color={statusColor(record)}>{statusDisplayName(record)}</Pill>
                    </div>
                  </Table.Cell>
                  <Table.Cell id={`export-ttl-${record.query_id}`}>{displayTTL(record)}</Table.Cell>
                </Table.Row>
              ))}
            </Table.Body>
          </Table>
        </Flex>
      </Flex>
    </>
  )
}
