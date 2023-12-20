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
import type {CustomColumn, HandleCheckboxChange, TeacherNotes} from '../../../types'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import CheckboxTemplate from './CheckboxTemplate'

const I18n = useI18nScope('enhanced_individual_gradebook')
type Props = {
  teacherNotes?: TeacherNotes | null
  customColumns?: CustomColumn[] | null
  customColumnsUrl?: string | null
  customColumnUrl?: string | null
  reorderCustomColumnsUrl?: string | null
  handleCheckboxChange: HandleCheckboxChange
  showNotesColumn: boolean
  onTeacherNotesCreation: (teacherNotes: TeacherNotes) => void
}

export default function ShowNotesColumnCheckbox({
  teacherNotes,
  customColumns,
  customColumnsUrl,
  customColumnUrl,
  reorderCustomColumnsUrl,
  showNotesColumn,
  handleCheckboxChange,
  onTeacherNotesCreation,
}: Props) {
  const handleShowNotesColumnChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!customColumnUrl || !customColumnsUrl) {
      return
    }
    const checked = event.target.checked
    if (teacherNotes) {
      executeApiRequest({
        method: 'PUT',
        body: {column: {hidden: !checked}},
        path: customColumnUrl.replace(':id', teacherNotes?.id),
      })
    } else {
      const {data} = await executeApiRequest<TeacherNotes>({
        method: 'POST',
        body: {
          column: {
            title: I18n.t('Notes'),
            position: 1,
            teacher_notes: true,
            hidden: !checked,
          },
        },
        path: customColumnsUrl,
      })
      onTeacherNotesCreation(data)
    }
    handleCheckboxChange('showNotesColumn', checked)
    if (!checked || !reorderCustomColumnsUrl || !customColumns) {
      return
    }
    executeApiRequest({
      method: 'POST',
      path: reorderCustomColumnsUrl,
      body: {
        order: customColumns.map(column => Number(column.id)),
      },
    })
  }

  return (
    <CheckboxTemplate
      dataTestId="show-notes-column-checkbox"
      label={I18n.t('Show Notes in Student Info')}
      checked={showNotesColumn}
      onChange={handleShowNotesColumnChange}
    />
  )
}
