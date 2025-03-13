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

import React, {useState, type FC, type SyntheticEvent} from 'react'
import {View} from '@instructure/ui-view'
import {Select} from '@instructure/ui-select'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import useCoursePeopleContext from '../../hooks/useCoursePeopleContext'
import {sortRoles} from '../../../util/utils'
import {DEFAULT_OPTION} from '../../../util/constants'
import {EnvRole} from '../../../types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

type SelectHandler = (event: SyntheticEvent, data: {id?: string, value?: string | number}) => void

interface PeopleFilterProps {
  onOptionSelect: (optionId: string) => void
}

const PeopleFilter: FC<PeopleFilterProps> = ({
  onOptionSelect: handleOptionSelect
}) => {
  const {id: defaultId, label: defaultValue} = DEFAULT_OPTION
  const {allRoles = []} = useCoursePeopleContext()
  const [selectedValue, setSelectedValue] = useState<string>(defaultValue)
  const filterOptions = [DEFAULT_OPTION, ...sortRoles(allRoles)]

  const handleSelect: SelectHandler = (_event, {id = defaultId, value = defaultValue}) => {
    handleOptionSelect(id)
    setSelectedValue(value as string)
  }

  const labelWithCount = (role: EnvRole) =>
    role.id === defaultId
      ? role.label
      : I18n.t('%{label} (%{count})', {label: role.label, count: role.count})

  return (
    <View as="div">
      <SimpleSelect
        renderLabel={<ScreenReaderContent>{I18n.t('Filter by role')}</ScreenReaderContent>}
        assistiveText={I18n.t('Use arrow keys to navigate options.')}
        value={selectedValue}
        onChange={handleSelect}
      >
        {filterOptions.map(role => {
          const label = labelWithCount(role)
          return (
            <Select.Option
              key={role.id}
              id={role.id}
              value={label}
            >
              {label}
            </Select.Option>
          )
        })}
      </SimpleSelect>
    </View>
  )
}

export default PeopleFilter
