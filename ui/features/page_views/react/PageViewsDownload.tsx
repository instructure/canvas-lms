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
import _ from 'lodash'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Table} from '@instructure/ui-table'
import {
  AsyncPageViewJobStatus,
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

const I18n = i18nScope('page_views')

export interface PageViewsDownloadProps {
  userId: string
}

const locale = ENV?.LOCALE || navigator.language
// For displaying selected months, we need a format with month and year only
const formatter = new Intl.DateTimeFormat(locale, {year: 'numeric', month: 'long'})

// Available dates are first day of each month for the last 12 months
const availableDates = new Array(13).fill(0).map((_, i) => {
  const date = new Date()
  date.setDate(1)
  date.setHours(0, 0, 0, 0)
  date.setMonth(date.getMonth() - i)
  return date
})

// When sent to the API,
// we need YYYY-MM-01 formats as it only accepts the first of the month
// the start month is inclusive (YYYY-MM-01 00:00:00)
function startMonthString(date: Date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-01`
}

// and the end month is exclusive (YYYY-MM-01 00:00:00 of the following month)
function endMonthString(date: Date) {
  const d = new Date(date)
  d.setMonth(d.getMonth() + 1)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`
}

export function PageViewsDownload({userId}: PageViewsDownloadProps): React.JSX.Element {
  const [startMonth, setStartMonth] = useState<string | number | undefined>(
    startMonthString(availableDates[0]),
  )
  const [endMonth, setEndMonth] = useState<string | number | undefined>(
    endMonthString(availableDates[0]),
  )
  const [exportError, setExportError] = useState<string | null>(null)
  const [asyncJobs, _setAsyncJobs, pollAsyncJobs, postAsyncJob, getDownloadUrl] =
    useAsyncPageviewJobs(`pv-export-${userId}`, userId)

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
    if (!startMonth || !endMonth || startMonth >= endMonth) {
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
    postAsyncJob(
      userId,
      `${formatter.format(new Date(startMonth))} - ${formatter.format(new Date(endMonth))}`,
      startMonth.toString(),
      endMonth.toString(),
    ).catch(e => {
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
              value={startMonth}
              onChange={(_e, {value}) => setStartMonth(value)}
            >
              {availableDates.map(date => (
                <SimpleSelect.Option
                  key={startMonthString(date)}
                  id={`start-month-${startMonthString(date)}`}
                  value={startMonthString(date)}
                >
                  {formatter.format(date)}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>
            <SimpleSelect
              renderLabel={I18n.t('End month')}
              placeholder={I18n.t('Select month')}
              value={endMonth}
              onChange={(_e, {value}) => setEndMonth(value)}
            >
              {availableDates.map(date => (
                <SimpleSelect.Option
                  key={endMonthString(date)}
                  id={`end-month-${endMonthString(date)}`}
                  value={endMonthString(date)}
                >
                  {formatter.format(date)}
                </SimpleSelect.Option>
              ))}
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
                      <Link href={getDownloadUrl(record)}>{record.name}</Link>
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
