/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {type SyntheticEvent, useState} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('content_copy_redesign')

type Option = {id: string; name: string}

export const ConfiguredSelectInput = ({
  label,
  defaultInputValue = '',
  options,
  onSelect,
  disabled = false,
}: {
  label: string
  defaultInputValue?: string
  options: Array<Option>
  onSelect: (selectedId: string | null) => void
  disabled?: boolean
}) => {
  const [inputValue, setInputValue] = useState<string>(defaultInputValue)

  const handleSelectOption = (
    _: SyntheticEvent,
    {id, value}: {id?: string; value?: string | number}
  ) => {
    const convertedId = id === undefined ? null : id
    setInputValue(value as string)
    onSelect(convertedId)
  }

  return (
    <SimpleSelect
      renderLabel={label}
      assistiveText={I18n.t('Use arrow keys to navigate options.')}
      value={inputValue}
      defaultValue={inputValue}
      onChange={handleSelectOption}
      interaction={disabled ? 'disabled' : 'enabled'}
    >
      {options.map(option => {
        return (
          <SimpleSelect.Option key={option.id} id={option.id} value={option.name}>
            {option.name}
          </SimpleSelect.Option>
        )
      })}
    </SimpleSelect>
  )
}
