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
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseWorkFilters, {type DateFilterOption} from '../../shared/CourseWorkFilters'
import StatisticsCardsGrid from '../../shared/StatisticsCardsGrid'
import type {CourseOption, BaseWidgetProps} from '../../../types'
import {useCourseWorkStatistics} from '../../../hooks/useCourseWorkStatistics'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {convertDateFilterToStatisticsRange} from '../../../utils/dateUtils'

const I18n = createI18nScope('widget_dashboard')

const CourseWorkSummaryWidget: React.FC<BaseWidgetProps> = ({widget}) => {
  const [selectedCourse, setSelectedCourse] = useState<string>('all')
  const [selectedDateRange, setSelectedDateRange] = useState<DateFilterOption>('next3days')

  // Fetch user's enrolled courses
  const {data: courseGrades = []} = useSharedCourses({limit: 1000})
  const userCourses: CourseOption[] = courseGrades.map(courseGrade => ({
    id: courseGrade.courseId,
    name: courseGrade.courseName,
  }))

  const selectedDateRangeOption = convertDateFilterToStatisticsRange(selectedDateRange)

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
      setSelectedDateRange(data.value as DateFilterOption)
    }
  }

  const tooltipMessage = useMemo(() => {
    const rangeLabels: Partial<Record<DateFilterOption, string>> = {
      next3days: I18n.t('Next 3 Days'),
      next7days: I18n.t('Next 7 Days'),
      next14days: I18n.t('Next 14 Days'),
    }
    const rangeLabel = rangeLabels[selectedDateRange] ?? 'selected date range'

    return (
      <div>
        <div>{I18n.t('Due: Assignments due within %{range}', {range: rangeLabel})}</div>
        <div>{I18n.t('Missing: All missing assignments')}</div>
        <div>{I18n.t('Submitted: All completed assignments')}</div>
      </div>
    )
  }, [selectedDateRange])

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
            <CourseWorkFilters
              selectedCourse={selectedCourse}
              selectedDateFilter={selectedDateRange}
              onCourseChange={handleCourseChange}
              onDateFilterChange={handleDateRangeChange}
              userCourses={userCourses}
              statisticsOnly={true}
            />
          </Flex>
        </Flex.Item>
        <Flex.Item shouldGrow>
          <StatisticsCardsGrid summary={summary} />
        </Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default CourseWorkSummaryWidget
