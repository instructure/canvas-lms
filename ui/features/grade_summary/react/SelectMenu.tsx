/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {SimpleSelect} from '@instructure/ui-simple-select'

interface SelectMenuProps {
  defaultValue: string
  disabled: boolean
  id: string
  label: string
  onChange: (event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => void
  options: Array<Record<string | number, any>>
  textAttribute: string | number
  valueAttribute: string | number
}

export default function SelectMenu(props: SelectMenuProps) {
  const options = props.options.map(option => {
    const text = option[props.textAttribute]
    const value = option[props.valueAttribute]
    return (
      <SimpleSelect.Option data-testid="select-menu-option" key={value} id={value} value={value}>
        {text}
      </SimpleSelect.Option>
    )
  })

  return (
    <SimpleSelect
      defaultValue={props.defaultValue}
      interaction={props.disabled ? 'disabled' : 'enabled'}
      id={props.id}
      isInline={true}
      renderLabel={props.label}
      onChange={props.onChange}
      width="15rem"
    >
      {options}
    </SimpleSelect>
  )
}
