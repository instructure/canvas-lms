/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {fudgeDateForProfileTimezone, unfudgeDateForProfileTimezone} from '@instructure/moment-utils'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import {PageViewsTable} from './PageViewsTable'
import {PageViewsDownload} from './PageViewsDownload'
import {Flex} from '@instructure/ui-flex'
import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-text'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = i18nScope('page_views')

export interface PageViewsProps {
  userId: string
}

type DateRange = {
  startDate?: Date
  endDate?: Date
}

export default function PageViews({userId}: PageViewsProps): React.JSX.Element {
  const [filterDate, setFilterDate] = useState<DateRange>({})
  const [startMessages, setStartMessages] = useState<FormMessage[] | undefined>(undefined)
  const [endMessages, setEndMessages] = useState<FormMessage[] | undefined>(undefined)
  const [selectedIndex, setSelectedIndex] = useState(0)
  const [isTableEmpty, setIsTableEmpty] = useState(false)
  const formatDateForDisplay = useDateTimeFormat('date.formats.long')

  // Cache top date is tomorrow 00:00 to allow today to be selected as an end date
  // We expect the range to represent whole days in the user's timezone
  // For this to work, we have to fudge the current datetime (translate to target timezone), zero out time
  // and then unfudge (translate back) to get the correct cache date boundaries
  const topTimestamp = Date.now() + 24 * 60 * 60 * 1000
  const fudgedTop = fudgeDateForProfileTimezone(new Date(topTimestamp)) ?? new Date(topTimestamp)
  fudgedTop.setHours(0, 0, 0, 0)
  const cacheTopDate = unfudgeDateForProfileTimezone(fudgedTop) ?? fudgedTop
  // Cache bottom date is 30 days ago, 00:00, which is 31 days before the top date
  const bottomTimestamp = topTimestamp - 31 * 24 * 60 * 60 * 1000
  const fudgedBottom =
    fudgeDateForProfileTimezone(new Date(bottomTimestamp)) ?? new Date(bottomTimestamp)
  fudgedBottom.setHours(0, 0, 0, 0)
  const cacheBottomDate = unfudgeDateForProfileTimezone(fudgedBottom) ?? fudgedBottom

  function onStartDateChange(date: Date | null) {
    const targetDate = date ?? undefined

    setStartMessages(undefined)
    setEndMessages(undefined)

    if (targetDate && targetDate < cacheBottomDate) {
      setStartMessages([
        {
          text: I18n.t('Start date must be within the last 30 days.'),
          type: 'newError',
        },
      ])
      return
    }
    if (targetDate && filterDate.endDate && targetDate > filterDate.endDate) {
      setStartMessages([
        {
          text: I18n.t('The start date cannot be later than the end date'),
          type: 'newError',
        },
      ])
      return
    }
    if (targetDate?.valueOf() === filterDate.startDate?.valueOf()) return // no change

    setFilterDate({
      startDate: targetDate,
      endDate: filterDate.endDate,
    })
  }

  function onEndDateChange(date: Date | null) {
    const targetDate = date ?? undefined

    setStartMessages(undefined)
    setEndMessages(undefined)

    if (targetDate && filterDate.startDate && targetDate < filterDate.startDate) {
      setEndMessages([
        {
          text: I18n.t('The end date cannot precede the start date'),
          type: 'newError',
        },
      ])
      return
    }
    if (targetDate?.valueOf() === filterDate.endDate?.valueOf()) return // no change

    setFilterDate({
      startDate: filterDate.startDate,
      endDate: targetDate,
    })
  }

  const queryDates: DateRange = {
    startDate: filterDate.startDate ?? cacheBottomDate,
    endDate: filterDate.endDate
      ? new Date(filterDate.endDate.getTime() + 24 * 60 * 60 * 1000)
      : cacheTopDate,
  }

  // Check if a date is within the cached 30-day range
  function isDateInCache(isoDate: string): boolean {
    const date = new Date(isoDate)
    return date >= cacheBottomDate && date <= new Date()
  }

  function isDefaultDateRange() {
    return (
      cacheBottomDate.getTime() === queryDates.startDate?.getTime() &&
      cacheTopDate.getTime() === queryDates.endDate?.getTime()
    )
  }

  function handleEmpty() {
    // wait until after render to avoid React state update warning
    setTimeout(() => {
      setIsTableEmpty(true)
    })
  }

  return (
    <Tabs onRequestTabChange={(_, {index}) => setSelectedIndex(index)} variant="secondary">
      <Tabs.Panel renderTitle={I18n.t('30-day activity')} isSelected={selectedIndex === 0}>
        <Flex direction="column" gap="moduleElements">
          <Text>{I18n.t('This page shows only the past 30 days of history.')}</Text>
          {!isTableEmpty && (
            <Flex direction="row" gap="inputFields" alignItems="start">
              <CanvasDateInput2
                placeholder={I18n.t('Filter start date')}
                selectedDate={filterDate.startDate?.toISOString()}
                disabledDates={date => !isDateInCache(date)}
                formatDate={formatDateForDisplay}
                renderLabel={I18n.t('Filter start date')}
                onSelectedDateChange={onStartDateChange}
                withRunningValue={true}
                interaction="enabled"
                dataTestid="page-views-date-start-filter"
                messages={startMessages}
              />
              <CanvasDateInput2
                placeholder={I18n.t('Filter end date')}
                selectedDate={filterDate.endDate?.toISOString()}
                disabledDates={date => !isDateInCache(date)}
                formatDate={formatDateForDisplay}
                renderLabel={I18n.t('Filter end date')}
                onSelectedDateChange={onEndDateChange}
                withRunningValue={true}
                interaction="enabled"
                dataTestid="page-views-date-end-filter"
                messages={endMessages}
              />
            </Flex>
          )}
          <Flex.Item>
            <PageViewsTable
              userId={userId}
              startDate={queryDates.startDate}
              endDate={queryDates.endDate}
              onEmpty={isDefaultDateRange() ? handleEmpty : undefined}
              pageSize={100}
            />
          </Flex.Item>
        </Flex>
      </Tabs.Panel>
      <Tabs.Panel renderTitle={I18n.t('1-year activity')} isSelected={selectedIndex === 1}>
        <PageViewsDownload userId={userId} />
      </Tabs.Panel>
    </Tabs>
  )
}
