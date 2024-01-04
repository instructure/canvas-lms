/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'

import {SimpleSelect} from '@instructure/ui-simple-select'

const I18n = useI18nScope('discussion_create')

const gradedDiscussionOptions = [
  {
    id: 'points',
    label: I18n.t('Points'),
  },
  {
    id: 'percent',
    label: I18n.t('Percentage'),
  },
  {
    id: 'pass_fail',
    label: I18n.t('Complete/Incomplete'),
  },
  {
    id: 'letter_grade',
    label: I18n.t('Letter Grade'),
  },
  {
    id: 'gpa_scale',
    label: I18n.t('GPA Scale'),
  },
]

type Props = {
  displayGradeAs: string
  setDisplayGradeAs: (id: string | undefined) => void
}

export const DisplayGradeAs = ({displayGradeAs, setDisplayGradeAs}: Props) => {
  return (
    <SimpleSelect
      data-testid="display-grade-input"
      renderLabel={I18n.t('Display Grade As')}
      value={displayGradeAs}
      onChange={(_event, {id}) => setDisplayGradeAs(id)}
    >
      {gradedDiscussionOptions.map(option => (
        <SimpleSelect.Option id={option.id} key={option.id} value={option.id}>
          {option.label}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}
