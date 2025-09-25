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

import React, {useState, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseWorkFilters, {type DateFilterOption} from '../../shared/CourseWorkFilters'
import type {BaseWidgetProps, CourseOption} from '../../../types'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {useCourseWork} from '../../../hooks/useCourseWork'
import {useCourseWorkStatistics} from '../../../hooks/useCourseWorkStatistics'
import {usePagination} from '../../../hooks/usePagination'
import StatisticsCardsGrid from '../../shared/StatisticsCardsGrid'
import {
  convertDateFilterToParams,
  convertDateFilterToStatisticsRange,
} from '../../../utils/dateUtils'
import {CourseWorkItem as CourseWorkItemComponent} from '../../shared/CourseWorkItem'

const I18n = createI18nScope('widget_dashboard')

const CourseWorkCombinedWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isLoading: externalIsLoading,
  error: externalError,
  onRetry,
}) => {
  const [selectedCourse, setSelectedCourse] = useState<string>('all')
  const [selectedDateFilter, setSelectedDateFilter] = useState<DateFilterOption>('next3days')

  const {data: courseGrades = []} = useSharedCourses({limit: 1000})
  const userCourses: CourseOption[] = courseGrades.map(courseGrade => ({
    id: courseGrade.courseId,
    name: courseGrade.courseName,
  }))

  const courseFilter = selectedCourse === 'all' ? undefined : selectedCourse.replace('course_', '')
  const dateParams = convertDateFilterToParams(selectedDateFilter)
  const statisticsDateRange = convertDateFilterToStatisticsRange(selectedDateFilter)

  const {
    data,
    isLoading: courseWorkLoading,
    error: courseWorkError,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isFetchingPreviousPage,
  } = useCourseWork({
    pageSize: 6,
    courseFilter,
    ...dateParams,
  })

  const {currentPageIndex, paginationProps, resetPagination} = usePagination({
    hasNextPage: !!hasNextPage,
    totalPagesLoaded: data?.pages?.length || 0,
    fetchNextPage,
    isFetchingNextPage,
    isFetchingPreviousPage,
  })

  const {
    data: summary = {due: 0, missing: 0, submitted: 0},
    isLoading: statisticsLoading,
    error: statisticsError,
  } = useCourseWorkStatistics({
    startDate: statisticsDateRange.startDate,
    endDate: statisticsDateRange.endDate,
    courseId: courseFilter,
  })

  const currentPage = data?.pages?.[currentPageIndex]
  const filteredItems = currentPage?.items || []

  const isLoading = externalIsLoading || courseWorkLoading || statisticsLoading
  const error = externalError || courseWorkError?.message || statisticsError?.message || null
  const handleRetry = onRetry || (() => refetch())

  const handleResetPagination = useCallback(() => {
    resetPagination()
    refetch()
  }, [resetPagination, refetch])

  const handleCourseChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedCourse(data.value)
        handleResetPagination()
      }
    },
    [handleResetPagination],
  )

  const handleDateFilterChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedDateFilter(data.value as DateFilterOption)
        handleResetPagination()
      }
    },
    [handleResetPagination],
  )

  return (
    <TemplateWidget
      widget={widget}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load course work. Please try again.') : null}
      onRetry={handleRetry}
      pagination={{
        ...paginationProps,
        ariaLabel: I18n.t('Course work pagination'),
      }}
      headerActions={
        <CourseWorkFilters
          selectedCourse={selectedCourse}
          selectedDateFilter={selectedDateFilter}
          onCourseChange={handleCourseChange}
          onDateFilterChange={handleDateFilterChange}
          userCourses={userCourses}
        />
      }
    >
      <Flex direction="column" gap="small" height="100%">
        {/* Statistics Cards Section */}
        <Flex.Item overflowY="hidden">
          <StatisticsCardsGrid summary={summary} margin="small 0" />
        </Flex.Item>

        {/* Course Work Items Section */}
        <Flex.Item shouldGrow>
          {filteredItems.length === 0 ? (
            <Flex justifyItems="center" padding="large">
              <Text color="secondary">
                {selectedCourse === 'all'
                  ? I18n.t('No upcoming course work')
                  : I18n.t('No upcoming course work for selected course')}
              </Text>
            </Flex>
          ) : (
            <View height="100%">
              <Flex direction="column">
                {filteredItems.map(item => (
                  <CourseWorkItemComponent key={item.id} item={item} />
                ))}
              </Flex>
            </View>
          )}
        </Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default CourseWorkCombinedWidget
