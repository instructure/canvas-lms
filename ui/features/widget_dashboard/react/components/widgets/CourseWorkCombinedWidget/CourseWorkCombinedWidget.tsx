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
import {List} from '@instructure/ui-list'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseWorkFilters, {type DateFilterOption} from '../../shared/CourseWorkFilters'
import type {BaseWidgetProps, CourseOption} from '../../../types'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {useCourseWorkPaginated} from '../../../hooks/useCourseWork'
import {useCourseWorkStatistics} from '../../../hooks/useCourseWorkStatistics'
import StatisticsCardsGrid from '../../shared/StatisticsCardsGrid'
import {
  convertDateFilterToParams,
  convertDateFilterToStatisticsRange,
} from '../../../utils/dateUtils'
import {CourseWorkItem as CourseWorkItemComponent} from '../../shared/CourseWorkItem'
import {DEFAULT_PAGE_SIZE} from '../../../constants/pagination'

const I18n = createI18nScope('widget_dashboard')

const CourseWorkCombinedWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isLoading: externalIsLoading,
  error: externalError,
  onRetry,
  isEditMode = false,
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

  const pageSize = DEFAULT_PAGE_SIZE.COURSE_WORK_COMBINED

  // Fetch course work with pagination
  const {
    currentPage: currentPageData,
    currentPageIndex,
    totalPages,
    goToPage,
    resetPagination,
    refetch,
    isLoading: courseWorkLoading,
    error: courseWorkError,
  } = useCourseWorkPaginated({
    pageSize,
    courseFilter,
    ...dateParams,
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

  const filteredItems = currentPageData?.items || []

  const isLoading = externalIsLoading || courseWorkLoading || statisticsLoading
  const error =
    externalError ||
    (courseWorkError ? courseWorkError.message : null) ||
    statisticsError?.message ||
    null
  const handleRetry = onRetry || (() => refetch())

  const handleCourseChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedCourse(data.value)
      }
    },
    [],
  )

  const handleDateFilterChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedDateFilter(data.value as DateFilterOption)
      }
    },
    [],
  )

  return (
    <TemplateWidget
      widget={widget}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load course work. Please try again.') : null}
      onRetry={handleRetry}
      isEditMode={isEditMode}
      pagination={{
        currentPage: currentPageIndex + 1,
        totalPages,
        onPageChange: goToPage,
        isLoading: courseWorkLoading,
        ariaLabel: I18n.t('Course work pagination'),
      }}
    >
      <Flex direction="column" gap="small" height="100%">
        {/* Filters Section */}
        <Flex.Item overflowX="visible" overflowY="visible">
          <CourseWorkFilters
            selectedCourse={selectedCourse}
            selectedDateFilter={selectedDateFilter}
            onCourseChange={handleCourseChange}
            onDateFilterChange={handleDateFilterChange}
            userCourses={userCourses}
          />
        </Flex.Item>

        {/* Statistics Cards Section */}
        <Flex.Item overflowY="hidden">
          <StatisticsCardsGrid summary={summary} margin="small 0" />
        </Flex.Item>

        {/* Course Work Items Section */}
        <Flex.Item shouldGrow>
          {filteredItems.length === 0 ? (
            <Flex justifyItems="center" padding="large">
              <Text color="secondary" data-testid="no-course-work-message">
                {selectedCourse === 'all'
                  ? I18n.t('No upcoming course work')
                  : I18n.t('No upcoming course work for selected course')}
              </Text>
            </Flex>
          ) : (
            <View height="100%">
              <Flex direction="column">
                <List isUnstyled margin="0">
                  {filteredItems.map(item => (
                    <List.Item key={item.id} margin="0">
                      <CourseWorkItemComponent item={item} />
                    </List.Item>
                  ))}
                </List>
              </Flex>
            </View>
          )}
        </Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default CourseWorkCombinedWidget
