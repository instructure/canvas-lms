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
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {IconMsExcelLine} from '@instructure/ui-icons'

const I18n = i18nScope('page_views')
const icon = <IconMsExcelLine />

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
  const formatDateForDisplay = useDateTimeFormat('date.formats.long')
  const baseURL = `/users/${userId}/page_views.csv`

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

  function downloadURL() {
    if (!filterDate.start || !filterDate.end) return baseURL
    return `${baseURL}?start_time=${filterDate.start.toISOString()}&end_time=${filterDate.end.toISOString()}`
  }

  return (
    <Flex direction="column">
      <Flex.Item padding="small">
        <CanvasDateInput2
          placeholder={I18n.t('Limit to a specific date')}
          selectedDate={filterDate.date?.toISOString()}
          formatDate={formatDateForDisplay}
          renderLabel={I18n.t('Filter by date')}
          onSelectedDateChange={handleDateChange}
          withRunningValue={true}
          interaction="enabled"
          dataTestid="page-views-date-filter"
        />
      </Flex.Item>
      <Flex.Item padding="small">
        <Button
          data-testid="page-views-csv-link"
          size="small"
          renderIcon={icon}
          href={downloadURL()}
        >
          {I18n.t('Download as CSV')}
        </Button>
      </Flex.Item>
      <Flex.Item>
        <PageViewsTable userId={userId} startDate={filterDate.start} endDate={filterDate.end} />
      </Flex.Item>
    </Flex>
  )
}
