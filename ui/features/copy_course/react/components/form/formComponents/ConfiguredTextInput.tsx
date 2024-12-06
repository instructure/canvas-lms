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

import React, {type ChangeEvent} from 'react'
import {TextInput} from '@instructure/ui-text-input'

export const ConfiguredTextInput = ({
  label,
  inputValue,
  onChange,
  disabled = false,
}: {
  label: string
  inputValue: string
  onChange: (value: string) => void
  disabled?: boolean
}) => {
  const handleInput = (_: ChangeEvent<HTMLInputElement>, value: string) => {
    onChange(value)
  }

  return (
    <TextInput renderLabel={label} value={inputValue} onChange={handleInput} disabled={disabled} />
  )
}
