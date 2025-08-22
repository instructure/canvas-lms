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
import {Tag} from '@instructure/ui-tag'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import type {BaseWidgetProps, CourseOption} from '../../../types'
import {usePaginatedCoursesWithGrades} from '../../../hooks/useUserCourses'
import {useCourseWork, type CourseWorkItem} from '../../../hooks/useCourseWork'
import {startOfToday, endOfDay, addDays, getTomorrow} from '../../../utils/dateUtils'

const I18n = createI18nScope('widget_dashboard')

type DateFilterOption = 'all' | 'missing' | 'next3days' | 'next7days' | 'next14days'

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
  const [selectedDateFilter, setSelectedDateFilter] = useState<DateFilterOption>('all')

  // Fetch user's enrolled courses
  const {data: courseGrades = []} = usePaginatedCoursesWithGrades({limit: 1000})
  const userCourses: CourseOption[] = courseGrades.map(courseGrade => ({
    id: courseGrade.courseId,
    name: courseGrade.courseName,
  }))

  // Fetch all course work items
  const {
    data: allCourseWorkItems = [],
    isLoading: courseWorkLoading,
    error: courseWorkError,
    refetch,
  } = useCourseWork()

  const courseOptions: CourseOption[] = useMemo(
    () => [{id: 'all', name: I18n.t('All Courses')}, ...userCourses],
    [userCourses],
  )

  const dateFilterOptions: DateFilterConfig[] = useMemo(
    () => [
      {id: 'all', label: I18n.t('All')},
      {id: 'missing', label: I18n.t('Missing')},
      {id: 'next3days', label: I18n.t('Next 3 days')},
      {id: 'next7days', label: I18n.t('Next 7 days')},
      {id: 'next14days', label: I18n.t('Next 14 days')},
    ],
    [],
  )

  // Use external loading/error states if provided, otherwise use hook states
  const isLoading = externalIsLoading || courseWorkLoading
  const error = externalError || (courseWorkError as string | null)
  const handleRetry = onRetry || (() => refetch())

  // Filter items by selected course and date filter in memory
  const filteredItems = useMemo(() => {
    let items = allCourseWorkItems

    // Filter by course
    if (selectedCourse !== 'all') {
      const courseId = selectedCourse.replace('course_', '')
      items = items.filter(item => item.course.id === courseId)
    }

    // Filter by date
    if (selectedDateFilter === 'missing') {
      // Filter for missing assignments (no due date)
      items = items.filter(item => !item.dueAt)
    } else if (selectedDateFilter !== 'all') {
      const today = startOfToday()

      let endDate: Date
      switch (selectedDateFilter) {
        case 'next3days':
          endDate = endOfDay(addDays(today, 3))
          break
        case 'next7days':
          endDate = endOfDay(addDays(today, 7))
          break
        case 'next14days':
          endDate = endOfDay(addDays(today, 14))
          break
        default:
          return items
      }

      items = items.filter(item => {
        // Include assignments with no due date (always actionable) OR assignments within date range
        if (!item.dueAt) return true
        const dueDate = new Date(item.dueAt)
        return dueDate >= today && dueDate <= endDate
      })
    }

    return items
  }, [allCourseWorkItems, selectedCourse, selectedDateFilter])

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

  const dueDateTime = (dueDate: Date, day: string) => {
    return I18n.t('Due %{day} at %{time}', {
      day,
      time: dueDate.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'}),
    })
  }

  const formatDueDate = (dueAt: string | null) => {
    if (!dueAt) return I18n.t('No due date')

    const dueDate = new Date(dueAt)
    const today = startOfToday()
    const tomorrow = getTomorrow()

    const dueToday = dueDate.toDateString() === today.toDateString()
    const dueTomorrow = dueDate.toDateString() === tomorrow.toDateString()

    if (dueToday) {
      return dueDateTime(dueDate, I18n.t('today'))
    }
    if (dueTomorrow) {
      return dueDateTime(dueDate, I18n.t('tomorrow'))
    }
    return I18n.t('Due %{date} at %{time}', {
      date: dueDate.toLocaleDateString(),
      time: dueDate.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'}),
    })
  }

  const getTypeInfo = (type: CourseWorkItem['type']) => {
    switch (type) {
      case 'assignment':
        return {color: 'info' as const, label: I18n.t('Assignment')}
      case 'quiz':
        return {color: 'warning' as const, label: I18n.t('Quiz')}
      case 'discussion':
        return {color: 'success' as const, label: I18n.t('Discussion')}
      default:
        return {color: 'primary' as const, label: I18n.t('Item')}
    }
  }

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
      actions={
        <Link href="/courses" isWithinText={false} data-testid="view-all-courses-link">
          <Flex gap="xx-small" alignItems="center">
            <IconExternalLinkLine size="x-small" />
            <Text size="small">{I18n.t('View all courses')}</Text>
          </Flex>
        </Link>
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
          <Flex direction="column" gap="small">
            {filteredItems.map(item => (
              <Flex.Item key={item.id} overflowY="hidden">
                <View padding="small" background="primary" borderRadius="medium">
                  <Flex gap="small" alignItems="start">
                    <Flex.Item shouldShrink>
                      <Tag
                        text={getTypeInfo(item.type).label}
                        color={getTypeInfo(item.type).color}
                        margin="0 0 x-small 0"
                      />
                    </Flex.Item>
                    <Flex.Item shouldGrow>
                      <Flex direction="column" gap="xx-small">
                        <Link
                          href={item.htmlUrl}
                          isWithinText={false}
                          data-testid={`course-work-item-link-${item.id}`}
                        >
                          <Text weight="bold" size="small">
                            {item.title}
                          </Text>
                        </Link>
                        <Text size="x-small" color="secondary">
                          {item.course.name}
                        </Text>
                        <Text size="x-small" color="secondary">
                          {formatDueDate(item.dueAt)}
                          {item.points != null &&
                            ` • ${I18n.t('%{points} pts', {points: item.points})}`}
                        </Text>
                      </Flex>
                    </Flex.Item>
                  </Flex>
                </View>
              </Flex.Item>
            ))}
          </Flex>
        </View>
      )}
    </TemplateWidget>
  )
}

export default CourseWorkWidget
