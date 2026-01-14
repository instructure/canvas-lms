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
import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {DisplayFilter} from '../../utils/constants'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface DisplayFilterSelectorProps {
  values: DisplayFilter[]
  onChange: (values: DisplayFilter[]) => void
}

export const DisplayFilterSelector: React.FC<DisplayFilterSelectorProps> = ({values, onChange}) => {
  return (
    <CheckboxGroup
      name="display-filter"
      description={I18n.t('Display')}
      defaultValue={values}
      onChange={values => onChange(values as DisplayFilter[])}
    >
      <Checkbox
        label={I18n.t('Unpublished Assignments')}
        value={DisplayFilter.SHOW_UNPUBLISHED_ASSIGNMENTS}
      />
      <Checkbox
        label={I18n.t('Outcomes with no results')}
        value={DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS}
      />
      <Checkbox
        label={I18n.t('Students with no results')}
        value={DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS}
      />
      <Checkbox
        label={I18n.t('Avatars in student list')}
        value={DisplayFilter.SHOW_STUDENT_AVATARS}
      />
    </CheckboxGroup>
  )
}
