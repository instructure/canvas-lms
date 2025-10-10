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

import React, {useMemo, useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import type {CourseOption} from '../../types'
import {useResponsiveContext} from '../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

export type DateFilterOption =
  | 'all'
  | 'missing'
  | 'next3days'
  | 'next7days'
  | 'next14days'
  | 'submitted'

export interface DateFilterConfig {
  id: DateFilterOption
  label: string
}

export interface CourseWorkFiltersProps {
  selectedCourse: string
  selectedDateFilter: DateFilterOption
  onCourseChange: (
    event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => void
  onDateFilterChange: (
    event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => void
  userCourses: CourseOption[]
  statisticsOnly?: boolean
}

const CourseWorkFilters: React.FC<CourseWorkFiltersProps> = ({
  selectedCourse,
  selectedDateFilter,
  onCourseChange,
  onDateFilterChange,
  userCourses,
  statisticsOnly = false,
}) => {
  const {isMobile} = useResponsiveContext()

  // Custom breakpoint for 1365px
  const [isNarrowScreen, setIsNarrowScreen] = useState(false)

  useEffect(() => {
    const checkScreenSize = () => {
      setIsNarrowScreen(window.innerWidth <= 1365)
    }

    checkScreenSize()
    window.addEventListener('resize', checkScreenSize)

    return () => window.removeEventListener('resize', checkScreenSize)
  }, [])
  const courseOptions: CourseOption[] = useMemo(
    () => [{id: 'all', name: I18n.t('All Courses')}, ...userCourses],
    [userCourses],
  )

  const dateFilterOptions: DateFilterConfig[] = useMemo(() => {
    const options: DateFilterConfig[] = [
      {id: 'next3days', label: I18n.t('Next 3 days')},
      {id: 'next7days', label: I18n.t('Next 7 days')},
      {id: 'next14days', label: I18n.t('Next 14 days')},
      {id: 'missing', label: I18n.t('Missing')},
      {id: 'submitted', label: I18n.t('Submitted')},
    ]
    return statisticsOnly
      ? options.filter(opt => opt.id !== 'missing' && opt.id !== 'submitted')
      : options
  }, [statisticsOnly])

  const filterMobilePadding = useMemo(() => 'xx-small', [])

  return (
    <Flex direction={isNarrowScreen ? 'column' : 'row'} padding="0 x-small">
      <Flex.Item shouldGrow={isMobile} padding={isNarrowScreen ? filterMobilePadding : undefined}>
        <SimpleSelect
          renderBeforeInput={
            <View padding="xx-small 0">
              <Text size="small" weight="bold">
                Filter by:
              </Text>
            </View>
          }
          renderLabel={<ScreenReaderContent>{I18n.t('Filter by course')}</ScreenReaderContent>}
          value={selectedCourse}
          onChange={onCourseChange}
          width={isMobile ? '100%' : '275px'}
          size="small"
        >
          {courseOptions.map(option => (
            <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
              {option.name}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>
      <Flex.Item
        shouldGrow={isMobile}
        padding={isNarrowScreen ? filterMobilePadding : '0 0 0 small'}
      >
        <SimpleSelect
          renderBeforeInput={
            <View padding="xx-small 0">
              <Text size="small" weight="bold">
                Filter by:
              </Text>
            </View>
          }
          renderLabel={<ScreenReaderContent>{I18n.t('Filter by due date')}</ScreenReaderContent>}
          value={selectedDateFilter}
          onChange={onDateFilterChange}
          width={isMobile ? '100%' : '275px'}
          size="small"
        >
          {dateFilterOptions.map(option => (
            <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
              {option.label}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>
    </Flex>
  )
}

export default CourseWorkFilters
