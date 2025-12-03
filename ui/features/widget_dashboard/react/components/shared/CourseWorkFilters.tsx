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

import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import CourseFilterSelect from './CourseFilterSelect'
import {useResponsiveContext} from '../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

export type DateFilterOption = 'not_submitted' | 'missing' | 'submitted'

export interface DateFilterConfig {
  id: DateFilterOption
  label: string
}

export function isValidDateFilterOption(value: unknown): value is DateFilterOption {
  return (
    typeof value === 'string' &&
    (value === 'not_submitted' || value === 'missing' || value === 'submitted')
  )
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
}

const CourseWorkFilters: React.FC<CourseWorkFiltersProps> = ({
  selectedCourse,
  selectedDateFilter,
  onCourseChange,
  onDateFilterChange,
}) => {
  const {isMobile} = useResponsiveContext()

  const statusFilterOptions: DateFilterConfig[] = useMemo(
    () => [
      {id: 'not_submitted', label: I18n.t('Not submitted')},
      {id: 'missing', label: I18n.t('Missing')},
      {id: 'submitted', label: I18n.t('Submitted')},
    ],
    [],
  )

  return (
    <Flex direction={isMobile ? 'column' : 'row'} wrap="wrap" gap="small">
      <Flex.Item shouldGrow overflowX="visible" overflowY="visible">
        <CourseFilterSelect selectedCourse={selectedCourse} onChange={onCourseChange} />
      </Flex.Item>
      <Flex.Item shouldGrow overflowX="visible" overflowY="visible">
        <SimpleSelect
          renderLabel={I18n.t('Submission status:')}
          value={selectedDateFilter}
          onChange={onDateFilterChange}
          data-testid="submission-status-filter-select"
        >
          {statusFilterOptions.map(option => (
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
