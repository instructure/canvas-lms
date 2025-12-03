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

import React, {useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseWorkFilters, {
  type DateFilterOption,
  isValidDateFilterOption,
} from '../../shared/CourseWorkFilters'
import type {BaseWidgetProps} from '../../../types'
import {useCourseWorkPaginated} from '../../../hooks/useCourseWork'
import {convertDateFilterToParams} from '../../../utils/dateUtils'
import {CourseWorkItem as CourseWorkItemComponent} from '../../shared/CourseWorkItem'
import {DEFAULT_PAGE_SIZE} from '../../../constants/pagination'
import {useWidgetConfig} from '../../../hooks/useWidgetConfig'

const I18n = createI18nScope('widget_dashboard')

const CourseWorkWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isEditMode = false,
  isLoading: externalIsLoading,
  error: externalError,
  onRetry,
}) => {
  const [selectedCourse, setSelectedCourse] = useWidgetConfig<string>(
    widget.id,
    'selectedCourse',
    'all',
  )
  const [selectedDateFilter, setSelectedDateFilter] = useWidgetConfig<DateFilterOption>(
    widget.id,
    'selectedDateFilter',
    'not_submitted',
    isValidDateFilterOption,
  )

  // Convert frontend filter values to backend parameters
  const courseFilter = selectedCourse === 'all' ? undefined : selectedCourse
  const dateParams = convertDateFilterToParams(selectedDateFilter)

  const pageSize = DEFAULT_PAGE_SIZE.COURSE_WORK

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

  // Get current page data
  const allCourseWorkItems = currentPageData?.items || []

  // Use external loading/error states if provided, otherwise use hook states
  const isLoading = externalIsLoading || courseWorkLoading
  const error = externalError || courseWorkError?.message || null
  const handleRetry = onRetry || (() => refetch())

  // All filtering is now handled server-side
  const filteredItems = allCourseWorkItems

  const handleCourseChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedCourse(data.value)
      }
    },
    [setSelectedCourse],
  )

  const handleDateFilterChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedDateFilter(data.value as DateFilterOption)
      }
    },
    [setSelectedDateFilter],
  )

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load course work. Please try again.') : null}
      onRetry={handleRetry}
      pagination={{
        currentPage: currentPageIndex + 1,
        totalPages,
        onPageChange: goToPage,
        isLoading: courseWorkLoading,
        ariaLabel: I18n.t('Course work pagination'),
      }}
    >
      <Flex direction="column" gap="small" height="100%">
        <Flex.Item>
          <CourseWorkFilters
            selectedCourse={selectedCourse}
            selectedDateFilter={selectedDateFilter}
            onCourseChange={handleCourseChange}
            onDateFilterChange={handleDateFilterChange}
          />
        </Flex.Item>
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

export default CourseWorkWidget
