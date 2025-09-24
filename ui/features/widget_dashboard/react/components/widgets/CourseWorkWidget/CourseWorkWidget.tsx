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
import {Pagination} from '@instructure/ui-pagination'
import {Spinner} from '@instructure/ui-spinner'
import {convertDateFilterToParams} from '../../../utils/dateUtils'
import {CourseWorkItem as CourseWorkItemComponent} from '../../shared/CourseWorkItem'

const I18n = createI18nScope('widget_dashboard')

const CourseWorkWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isLoading: externalIsLoading,
  error: externalError,
  onRetry,
}) => {
  const [selectedCourse, setSelectedCourse] = useState<string>('all')
  const [selectedDateFilter, setSelectedDateFilter] = useState<DateFilterOption>('next3days')
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)

  // Fetch user's enrolled courses
  const {data: courseGrades = []} = useSharedCourses({limit: 1000})
  const userCourses: CourseOption[] = courseGrades.map(courseGrade => ({
    id: courseGrade.courseId,
    name: courseGrade.courseName,
  }))

  // Convert frontend filter values to backend parameters
  const courseFilter = selectedCourse === 'all' ? undefined : selectedCourse.replace('course_', '')
  const dateParams = convertDateFilterToParams(selectedDateFilter)

  // Fetch course work items with infinite pagination
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
    pageSize: 4,
    courseFilter,
    ...dateParams,
  })

  // Get current page data from infinite query
  const currentPage = data?.pages?.[currentPageIndex]
  const allCourseWorkItems = currentPage?.items || []
  const totalPagesLoaded = data?.pages?.length || 0

  // Calculate pagination state similar to CourseGrades widget
  const effectiveHasNextPage = currentPageIndex < totalPagesLoaded - 1 || hasNextPage
  const effectiveHasPreviousPage = currentPageIndex > 0
  const effectiveTotalPages = hasNextPage ? totalPagesLoaded + 1 : totalPagesLoaded
  const effectiveCurrentPage = currentPageIndex + 1

  // Use external loading/error states if provided, otherwise use hook states
  const isLoading = externalIsLoading || courseWorkLoading
  const error = externalError || courseWorkError?.message || null
  const handleRetry = onRetry || (() => refetch())

  // All filtering is now handled server-side
  const filteredItems = allCourseWorkItems

  const resetPagination = useCallback(() => {
    setCurrentPageIndex(0)
    refetch()
  }, [refetch])

  const handleCourseChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedCourse(data.value)
        resetPagination()
      }
    },
    [resetPagination],
  )

  const handleDateFilterChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedDateFilter(data.value as DateFilterOption)
        resetPagination()
      }
    },
    [resetPagination],
  )

  const goToPage = useCallback(
    (pageNumber: number) => {
      const targetIndex = pageNumber - 1

      if (targetIndex < 0) return

      if (targetIndex < totalPagesLoaded) {
        // Page is already cached, navigate directly
        setCurrentPageIndex(targetIndex)
      } else if (targetIndex === totalPagesLoaded && hasNextPage) {
        // Need to fetch the next page
        fetchNextPage().then(() => {
          setCurrentPageIndex(targetIndex)
        })
      }
    },
    [totalPagesLoaded, hasNextPage, fetchNextPage],
  )

  return (
    <TemplateWidget
      widget={widget}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load course work. Please try again.') : null}
      onRetry={handleRetry}
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
          {(effectiveHasNextPage || effectiveHasPreviousPage) && (
            <View padding="small" textAlign="center">
              <Flex direction="row" justifyItems="center" alignItems="center" gap="small">
                {(isFetchingNextPage || isFetchingPreviousPage) && (
                  <Spinner size="x-small" renderTitle={I18n.t('Loading course work...')} />
                )}
                <Pagination
                  variant="compact"
                  margin="small"
                  labelNext={I18n.t('Next page')}
                  labelPrev={I18n.t('Previous page')}
                  currentPage={effectiveCurrentPage}
                  totalPageNumber={effectiveTotalPages}
                  onPageChange={goToPage}
                  aria-label={I18n.t('Course work pagination')}
                />
              </Flex>
            </View>
          )}
        </View>
      )}
    </TemplateWidget>
  )
}

export default CourseWorkWidget
