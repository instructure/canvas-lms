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

import React, {useState, useMemo, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import type {BaseWidgetProps, CourseOption} from '../../../types'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {useCourseWork, type CourseWorkItem} from '../../../hooks/useCourseWork'
import {Pagination} from '@instructure/ui-pagination'
import {Spinner} from '@instructure/ui-spinner'
import {startOfToday, endOfDay, addDays} from '../../../utils/dateUtils'
import {CourseWorkItem as CourseWorkItemComponent} from './CourseWorkItem'

const I18n = createI18nScope('widget_dashboard')

type DateFilterOption = 'all' | 'missing' | 'next3days' | 'next7days' | 'next14days' | 'submitted'

interface DateFilterConfig {
  id: DateFilterOption
  label: string
}

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
    fetchPreviousPage,
    hasNextPage,
    hasPreviousPage,
    isFetchingNextPage,
    isFetchingPreviousPage,
  } = useCourseWork({
    pageSize: 4,
    courseFilter,
    ...dateParams,
  })

  function convertDateFilterToParams(filter: DateFilterOption) {
    const today = startOfToday()

    switch (filter) {
      case 'next3days':
        return {
          startDate: today.toISOString(),
          endDate: addDays(today, 3).toISOString(),
          includeOverdue: false,
          includeNoDueDate: false,
          onlySubmitted: false,
        }
      case 'next7days':
        return {
          startDate: today.toISOString(),
          endDate: addDays(today, 7).toISOString(),
          includeOverdue: false,
          includeNoDueDate: false,
          onlySubmitted: false,
        }
      case 'next14days':
        return {
          startDate: today.toISOString(),
          endDate: addDays(today, 14).toISOString(),
          includeOverdue: false,
          includeNoDueDate: false,
          onlySubmitted: false,
        }
      case 'missing':
        return {
          startDate: undefined,
          endDate: undefined,
          includeOverdue: true,
          includeNoDueDate: false,
          onlySubmitted: false,
        }
      case 'submitted':
        return {
          startDate: undefined,
          endDate: undefined,
          includeOverdue: false,
          includeNoDueDate: false,
          onlySubmitted: true,
        }
      default:
        return {
          startDate: undefined,
          endDate: undefined,
          includeOverdue: false,
          includeNoDueDate: false,
          onlySubmitted: false,
        }
    }
  }

  // Get current page data from infinite query
  const currentPage = data?.pages?.[currentPageIndex]
  const allCourseWorkItems = currentPage?.items || []
  const totalPagesLoaded = data?.pages?.length || 0

  // Calculate pagination state similar to CourseGrades widget
  const effectiveHasNextPage = currentPageIndex < totalPagesLoaded - 1 || hasNextPage
  const effectiveHasPreviousPage = currentPageIndex > 0
  const effectiveTotalPages = hasNextPage ? totalPagesLoaded + 1 : totalPagesLoaded
  const effectiveCurrentPage = currentPageIndex + 1

  const courseOptions: CourseOption[] = useMemo(
    () => [{id: 'all', name: I18n.t('All Courses')}, ...userCourses],
    [userCourses],
  )

  const dateFilterOptions: DateFilterConfig[] = useMemo(
    () => [
      {id: 'next3days', label: I18n.t('Next 3 days')},
      {id: 'next7days', label: I18n.t('Next 7 days')},
      {id: 'next14days', label: I18n.t('Next 14 days')},
      {id: 'missing', label: I18n.t('Missing')},
      {id: 'submitted', label: I18n.t('Submitted')},
    ],
    [],
  )

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

  const handleNextPage = useCallback(async () => {
    if (currentPageIndex < totalPagesLoaded - 1) {
      // Move to next cached page
      setCurrentPageIndex(currentPageIndex + 1)
    } else if (hasNextPage) {
      // Fetch new page and move to it
      await fetchNextPage()
      setCurrentPageIndex(currentPageIndex + 1)
    }
  }, [currentPageIndex, totalPagesLoaded, hasNextPage, fetchNextPage])

  const handlePreviousPage = useCallback(async () => {
    if (currentPageIndex > 0) {
      setCurrentPageIndex(currentPageIndex - 1)
    }
  }, [currentPageIndex])

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
        <Flex gap="small">
          <SimpleSelect
            renderLabel={I18n.t('Filter by course')}
            value={selectedCourse}
            onChange={handleCourseChange}
            width="200px"
            size="small"
          >
            {courseOptions.map(option => (
              <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
                {option.name}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
          <SimpleSelect
            renderLabel={I18n.t('Filter by due date')}
            value={selectedDateFilter}
            onChange={handleDateFilterChange}
            width="150px"
            size="small"
          >
            {dateFilterOptions.map(option => (
              <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
                {option.label}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </Flex>
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
