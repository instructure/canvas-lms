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
import {unfudgeDateForProfileTimezone} from '@instructure/moment-utils'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import {PageViewsTable} from './PageViewsTable'
import {PageViewsDownload} from './PageViewsDownload'
import {Flex} from '@instructure/ui-flex'
import {Tabs} from '@instructure/ui-tabs'
import _ from 'lodash'
import {Text} from '@instructure/ui-text'

const I18n = i18nScope('page_views')

export interface PageViewsProps {
  userId: string
}

type DateRange = {
  date?: Date
  start?: Date
  end?: Date
}

export default function PageViews({userId}: PageViewsProps): React.JSX.Element {
  const [filterDate, setFilterDate] = useState<DateRange>({})
  const [selectedIndex, setSelectedIndex] = useState(0)
  const [isTableEmpty, setIsTableEmpty] = useState(false)
  const formatDateForDisplay = useDateTimeFormat('date.formats.long')

  function handleDateChange(date: Date | null) {
    if (date === null) {
      setFilterDate({})
      return
    }
    const start = unfudgeDateForProfileTimezone(date)
    if (start !== null) {
      const end = new Date(start.getTime() + 24 * 60 * 60 * 1000)
      setFilterDate({date, start, end})
    }
  }

  // data in cache is only for the last 30 days
  function isDateInCache(isoDate: string): boolean {
    const date = new Date(isoDate)
    const now = new Date()
    const cacheBottomDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
    return date >= cacheBottomDate && date <= now
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
          <Flex.Item>
            {!isTableEmpty && (
              <CanvasDateInput2
                placeholder={I18n.t('Limit to a specific date')}
                selectedDate={filterDate.date?.toISOString()}
                disabledDates={date => !isDateInCache(date)}
                formatDate={formatDateForDisplay}
                renderLabel={I18n.t('Filter by date')}
                onSelectedDateChange={handleDateChange}
                withRunningValue={true}
                interaction="enabled"
                dataTestid="page-views-date-filter"
              />
            )}
          </Flex.Item>
          <Flex.Item>
            <PageViewsTable
              userId={userId}
              startDate={filterDate.start}
              endDate={filterDate.end}
              onEmpty={handleEmpty}
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
