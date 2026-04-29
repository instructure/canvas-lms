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
import {SimpleSelect} from '@instructure/ui-simple-select'
import type {CourseOption} from '../../types'
import {useSharedCourses} from '../../hooks/useSharedCourses'

const I18n = createI18nScope('widget_dashboard')

export interface CourseFilterSelectProps {
  selectedCourse: string
  onChange: (event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => void
  disabled?: boolean
  renderLabel?: string
}

const CourseFilterSelect: React.FC<CourseFilterSelectProps> = ({
  selectedCourse,
  onChange,
  disabled = false,
  renderLabel = I18n.t('Course filter:'),
}) => {
  const {data: courseGrades = []} = useSharedCourses({limit: 1000})
  const userCourses: CourseOption[] = courseGrades.map(courseGrade => ({
    id: courseGrade.courseId,
    name: courseGrade.courseName,
  }))

  const courseOptions: CourseOption[] = useMemo(
    () => [{id: 'all', name: I18n.t('All Courses')}, ...userCourses],
    [userCourses],
  )

  return (
    <SimpleSelect
      renderLabel={renderLabel}
      value={selectedCourse}
      onChange={onChange}
      disabled={disabled}
      data-testid="course-filter-select"
    >
      {courseOptions.map(option => (
        <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
          {option.name}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}

export default CourseFilterSelect
