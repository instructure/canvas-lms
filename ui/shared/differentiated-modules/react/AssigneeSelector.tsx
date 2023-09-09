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

import CanvasMultiSelect from '@canvas/multi-select/react'
import React, {ReactElement, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'

const {Option: CanvasMultiSelectOption} = CanvasMultiSelect as any

const I18n = useI18nScope('differentiated_modules')

interface Option {
  id: string
  value: string
}
export const OPTIONS = [
  {id: '1', value: 'Section A'},
  {id: '2', value: 'Section B'},
  {id: '3', value: 'Section C'},
  {id: '4', value: 'Section D'},
  {id: '5', value: 'Section E'},
  {id: '6', value: 'Section F'},
]

const AssigneeSelector = () => {
  const [selectedAssignees, setSelectedAssignees] = useState<Option[]>([])

  const handleChange = (newSelected: string[]) => {
    const newSelectedSet = new Set(newSelected)
    const selected = OPTIONS.filter(option => newSelectedSet.has(option.id))
    setSelectedAssignees(selected)
  }

  return (
    <>
      <CanvasMultiSelect
        data-testid="assignee_selector"
        label={I18n.t('Assign To')}
        size="large"
        selectedOptionIds={selectedAssignees.map(val => val.id)}
        onChange={handleChange}
        renderAfterInput={<></>}
        customRenderBeforeInput={tags =>
          tags?.map((tag: ReactElement) => (
            <View
              key={tag.key}
              data-testid="assignee_selector_option"
              as="div"
              display="inline-block"
              margin="xx-small none"
            >
              {tag}
            </View>
          ))
        }
      >
        {OPTIONS.map(role => {
          return (
            <CanvasMultiSelectOption id={role.id} value={role.id} key={role.id}>
              {role.value}
            </CanvasMultiSelectOption>
          )
        })}
      </CanvasMultiSelect>
      <View as="div" textAlign="end" margin="small none">
        <Link
          data-testid="clear_selection_button"
          onClick={() => setSelectedAssignees([])}
          isWithinText={false}
        >
          {I18n.t('Clear All')}
        </Link>
      </View>
    </>
  )
}

export default AssigneeSelector
