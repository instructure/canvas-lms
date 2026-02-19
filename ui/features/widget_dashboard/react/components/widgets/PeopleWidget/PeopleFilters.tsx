/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import CourseFilterSelect from '../../shared/CourseFilterSelect'
import {useResponsiveContext} from '../../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

export type RoleFilterOption = 'all' | 'teacher' | 'ta'

export interface RoleFilterConfig {
  id: RoleFilterOption
  label: string
}

export function isValidRoleFilterOption(value: unknown): value is RoleFilterOption {
  return typeof value === 'string' && (value === 'all' || value === 'teacher' || value === 'ta')
}

export interface PeopleFiltersProps {
  selectedCourse: string
  selectedRole: RoleFilterOption
  onCourseChange: (
    event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => void
  onRoleChange: (event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => void
}

const PeopleFilters: React.FC<PeopleFiltersProps> = ({
  selectedCourse,
  selectedRole,
  onCourseChange,
  onRoleChange,
}) => {
  const {isMobile} = useResponsiveContext()

  const roleFilterOptions: RoleFilterConfig[] = useMemo(
    () => [
      {id: 'all', label: I18n.t('All Roles')},
      {id: 'teacher', label: I18n.t('Teacher')},
      {id: 'ta', label: I18n.t('Teaching Assistant')},
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
          renderLabel={I18n.t('Role filter:')}
          value={selectedRole}
          onChange={onRoleChange}
          data-testid="role-filter-select"
        >
          {roleFilterOptions.map(option => (
            <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
              {option.label}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>
    </Flex>
  )
}

export default PeopleFilters
