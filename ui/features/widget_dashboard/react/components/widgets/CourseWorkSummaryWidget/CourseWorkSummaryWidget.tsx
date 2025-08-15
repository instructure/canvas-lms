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

import React, {useState, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import StatisticsCard from './StatisticsCard'
import type {CourseOption, DateRangeOption, BaseWidgetProps} from '../../../types'
import {useCourseWorkStatistics} from '../../../hooks/useCourseWorkStatistics'
import {useUserCourses} from '../../../hooks/useUserCourses'

const I18n = createI18nScope('widget_dashboard')

const CourseWorkSummaryWidget: React.FC<BaseWidgetProps> = ({widget}) => {
  const [selectedCourse, setSelectedCourse] = useState<string>('all')
  const [selectedDateRange, setSelectedDateRange] = useState<string>('next_3_days')

  // Fetch user's enrolled courses
  const {data: userCourses = []} = useUserCourses()

  const courseOptions: CourseOption[] = useMemo(
    () => [{id: 'all', name: I18n.t('All Courses')}, ...userCourses],
    [userCourses],
  )

  const dateRangeOptions: DateRangeOption[] = useMemo(() => {
    const now = new Date()

    // Start of today (00:00:00)
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate())

    // Helper function to create end of day for N days from today
    const endOfDays = (days: number) => {
      const endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + days + 1)
      endDate.setMilliseconds(-1) // Set to 23:59:59.999 of the last day
      return endDate
    }

    return [
      {
        id: 'next_3_days',
        label: I18n.t('Next 3 Days'),
        startDate: startOfToday,
        endDate: endOfDays(2), // Today + 2 more days = 3 days total
      },
      {
        id: 'next_7_days',
        label: I18n.t('Next 7 Days'),
        startDate: startOfToday,
        endDate: endOfDays(6), // Today + 6 more days = 7 days total
      },
      {
        id: 'next_14_days',
        label: I18n.t('Next 14 Days'),
        startDate: startOfToday,
        endDate: endOfDays(13), // Today + 13 more days = 14 days total
      },
    ]
  }, [])

  const selectedDateRangeOption = useMemo(() => {
    return dateRangeOptions.find(option => option.id === selectedDateRange) || dateRangeOptions[0]
  }, [selectedDateRange, dateRangeOptions])

  const courseId = useMemo(() => {
    if (selectedCourse === 'all') {
      return undefined
    }
    return selectedCourse.replace('course_', '')
  }, [selectedCourse])

  const {
    data: summary = {due: 0, missing: 0, submitted: 0},
    isLoading,
    error,
  } = useCourseWorkStatistics({
    startDate: selectedDateRangeOption.startDate,
    endDate: selectedDateRangeOption.endDate,
    courseId,
  })

  const handleCourseChange = (
    _event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => {
    if (data.value && typeof data.value === 'string') {
      setSelectedCourse(data.value)
    }
  }

  const handleDateRangeChange = (
    _event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => {
    if (data.value && typeof data.value === 'string') {
      setSelectedDateRange(data.value)
    }
  }

  const tooltipMessage = useMemo(() => {
    const selectedOption = dateRangeOptions.find(option => option.id === selectedDateRange)
    const rangeLabel = selectedOption?.label || 'selected date range'

    return (
      <div>
        <div>{I18n.t('Due: Assignments due within %{range}', {range: rangeLabel})}</div>
        <div>{I18n.t('Missing: All missing assignments')}</div>
        <div>{I18n.t('Submitted: All completed assignments')}</div>
      </div>
    )
  }, [selectedDateRange, dateRangeOptions])

  const statisticsData = useMemo(
    () => [
      {
        key: 'due',
        count: summary.due,
        label: I18n.t('Due'),
        backgroundColor: '#E0EBF5',
      },
      {
        key: 'missing',
        count: summary.missing,
        label: I18n.t('Missing'),
        backgroundColor: '#FCE4E5',
      },
      {
        key: 'submitted',
        count: summary.submitted,
        label: I18n.t('Submitted'),
        backgroundColor: '#DCEEE4',
      },
    ],
    [summary],
  )

  return (
    <TemplateWidget
      widget={widget}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load course work data. Please try again.') : null}
      loadingText={I18n.t('Loading course work data...')}
      headerActions={
        <Tooltip renderTip={tooltipMessage} placement="top">
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Information about course work counts')}
          >
            <IconInfoLine size="x-small" />
          </IconButton>
        </Tooltip>
      }
    >
      <Flex direction="column" gap="x-small">
        <Flex.Item overflowY="hidden">
          <Flex gap="small" wrap="wrap" padding="xx-small">
            <Flex.Item>
              <SimpleSelect
                renderLabel={I18n.t('Course')}
                value={selectedCourse}
                onChange={handleCourseChange}
                width="12rem"
              >
                {courseOptions.map(option => (
                  <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
                    {option.name}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect>
            </Flex.Item>

            <Flex.Item>
              <SimpleSelect
                renderLabel={I18n.t('Date Range')}
                value={selectedDateRange}
                onChange={handleDateRangeChange}
                width="12rem"
              >
                {dateRangeOptions.map(option => (
                  <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
                    {option.label}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item shouldGrow>
          <Flex gap="small" margin="small 0 0 xx-small">
            {statisticsData.map(stat => (
              <Flex.Item key={stat.key} shouldGrow shouldShrink>
                <StatisticsCard
                  count={stat.count}
                  label={stat.label}
                  backgroundColor={stat.backgroundColor}
                />
              </Flex.Item>
            ))}
          </Flex>
        </Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default CourseWorkSummaryWidget
